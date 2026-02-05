#!/usr/bin/env bash
# cw - Claude Worktree manager
# Spin up isolated git worktrees for parallel Claude Code sessions.
#
# Usage:
#   cw new <name> [flags] [prompt]  Create a worktree + open claude
#   cw open <name> [prompt]         Open Claude in an existing worktree
#   cw ls                           List active worktrees
#   cw cd <name>                    Print the path (use: cd $(cw cd <name>))
#   cw merge <name> [--local]      Push branch + create PR (or local squash with --local)
#   cw rm <name>                    Remove a worktree and its branch
#   cw clean                        Remove ALL worktrees created by cw
#   cw help                         Show this help
#
# Flags for `new`:
#   --open       Open Claude immediately (skip prompt)
#   --no-open    Don't open Claude (skip prompt)
#   (default)    Interactive — press Enter to open, ESC to skip
#
# Examples:
#   cw new auth "implement OAuth2 login flow"
#   cw new api --open "build REST endpoints"
#   cw new tests --no-open
#   cw merge auth
#   cw clean

set -euo pipefail

# ── Config ──────────────────────────────────────────────────────────────────
CW_PREFIX="cw"                          # branch prefix to namespace cw branches
CW_DIR_PREFIX=".worktrees"              # folder name under repo root for worktrees
BASE_BRANCH=""                           # auto-detected below

# ── Colors ──────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
RESET='\033[0m'

# ── Helpers ─────────────────────────────────────────────────────────────────
die()  { echo -e "${RED}error:${RESET} $*" >&2; exit 1; }
info() { echo -e "${CYAN}▸${RESET} $*"; }
ok()   { echo -e "${GREEN}✓${RESET} $*"; }
warn() { echo -e "${YELLOW}⚠${RESET} $*"; }

get_repo_root() {
  git rev-parse --show-toplevel 2>/dev/null || die "not inside a git repository"
}

get_base_branch() {
  if git show-ref --verify --quiet refs/heads/main 2>/dev/null; then
    echo "main"
  elif git show-ref --verify --quiet refs/heads/master 2>/dev/null; then
    echo "master"
  else
    git rev-parse --abbrev-ref HEAD
  fi
}

worktree_path() {
  local repo_root="$1"
  local name="$2"
  echo "${repo_root}/${CW_DIR_PREFIX}/${name}"
}

branch_name() {
  echo "${CW_PREFIX}/${1}"
}

# Read a single keypress. Returns 0 for Enter, 1 for ESC, 2 for anything else.
# Handles ESC sequences (arrow keys etc) by consuming trailing bytes.
read_key() {
  local key
  IFS= read -rsn1 key

  if [[ "$key" == "" ]]; then
    # Enter
    return 0
  elif [[ "$key" == $'\x1b' ]]; then
    # ESC — consume any remaining bytes from escape sequence (e.g. arrow keys)
    read -rsn2 -t 0.1 _ 2>/dev/null || true
    return 1
  else
    return 2
  fi
}

# Interactive prompt: "Open Claude? [Enter] open  [ESC] skip"
# Returns 0 if user wants to open, 1 if skip.
prompt_open_claude() {
  echo ""
  echo -ne "   ${BOLD}Open Claude?${RESET}  ${DIM}[Enter]${RESET} open  ${DIM}[ESC]${RESET} skip "

  while true; do
    read_key
    local rc=$?
    if [[ $rc -eq 0 ]]; then
      echo ""
      return 0
    elif [[ $rc -eq 1 ]]; then
      echo ""
      return 1
    fi
    # Ignore other keys, keep waiting
  done
}

# ── Commands ────────────────────────────────────────────────────────────────

cmd_new() {
  # Parse: cw new <name> [--open|--no-open] [prompt...]
  local name=""
  local open_mode=""  # "yes", "no", or "" (interactive)
  local prompt_parts=()

  for arg in "$@"; do
    case "$arg" in
      --open)    open_mode="yes" ;;
      --no-open) open_mode="no" ;;
      *)
        if [[ -z "$name" ]]; then
          name="$arg"
        else
          prompt_parts+=("$arg")
        fi
        ;;
    esac
  done

  [[ -n "$name" ]] || die "usage: cw new <name> [--open|--no-open] [prompt]"

  local prompt="${prompt_parts[*]:-}"

  local repo_root
  repo_root="$(get_repo_root)"
  BASE_BRANCH="$(get_base_branch)"

  local wt_path branch
  wt_path="$(worktree_path "$repo_root" "$name")"
  branch="$(branch_name "$name")"

  [[ -d "$wt_path" ]] && die "worktree '${name}' already exists at ${wt_path}"

  # Ensure the worktrees directory exists and is gitignored
  mkdir -p "${repo_root}/${CW_DIR_PREFIX}"
  local gitignore="${repo_root}/.gitignore"
  if [[ -f "$gitignore" ]]; then
    grep -qxF "${CW_DIR_PREFIX}/" "$gitignore" 2>/dev/null || echo "${CW_DIR_PREFIX}/" >> "$gitignore"
  else
    echo "${CW_DIR_PREFIX}/" > "$gitignore"
  fi

  info "Creating worktree ${BOLD}${name}${RESET} from ${DIM}${BASE_BRANCH}${RESET}"
  git worktree add -b "$branch" "$wt_path" "$BASE_BRANCH" --quiet

  # ── Post-setup: install deps if needed ──
  if [[ -f "${wt_path}/package-lock.json" ]]; then
    info "Installing npm dependencies..."
    (cd "$wt_path" && npm install --silent 2>/dev/null) || warn "npm install had issues — you may need to install manually"
  elif [[ -f "${wt_path}/yarn.lock" ]]; then
    info "Installing yarn dependencies..."
    (cd "$wt_path" && yarn install --silent 2>/dev/null) || warn "yarn install had issues"
  elif [[ -f "${wt_path}/pnpm-lock.yaml" ]]; then
    info "Installing pnpm dependencies..."
    (cd "$wt_path" && pnpm install --silent 2>/dev/null) || warn "pnpm install had issues"
  elif [[ -f "${wt_path}/requirements.txt" ]]; then
    info "Found requirements.txt — remember to set up your venv"
  elif [[ -f "${wt_path}/pyproject.toml" ]]; then
    info "Found pyproject.toml — remember to set up your venv"
  fi

  ok "Worktree ready at ${BOLD}${wt_path}${RESET}"
  echo -e "   Branch: ${DIM}${branch}${RESET}"

  # ── Decide whether to open Claude ──
  local should_open=false

  if [[ "$open_mode" == "yes" ]]; then
    should_open=true
  elif [[ "$open_mode" == "no" ]]; then
    should_open=false
  else
    # Interactive prompt
    if prompt_open_claude; then
      should_open=true
    fi
  fi

  if [[ "$should_open" == true ]]; then
    echo ""
    if [[ -n "$prompt" ]]; then
      info "Starting Claude Code with prompt..."
      echo -e "   ${DIM}\"${prompt}\"${RESET}"
      echo ""
      (cd "$wt_path" && claude "$prompt")
    else
      info "Opening Claude Code..."
      echo ""
      (cd "$wt_path" && claude)
    fi
  else
    echo ""
    info "To start working later:"
    echo -e "   ${DIM}cd ${wt_path} && claude${RESET}"
  fi
}

cmd_ls() {
  local repo_root
  repo_root="$(get_repo_root)"
  local wt_dir="${repo_root}/${CW_DIR_PREFIX}"

  if [[ ! -d "$wt_dir" ]] || [[ -z "$(ls -A "$wt_dir" 2>/dev/null)" ]]; then
    info "No active worktrees."
    return
  fi

  echo -e "${BOLD}Active worktrees:${RESET}"
  echo ""

  git worktree list --porcelain | while IFS= read -r line; do
    if [[ "$line" == worktree* ]]; then
      local path="${line#worktree }"
      if [[ "$path" == *"/${CW_DIR_PREFIX}/"* ]]; then
        local name
        name="$(basename "$path")"
        local branch_line
        branch_line=""
      fi
    elif [[ "$line" == branch* && -n "${name:-}" ]]; then
      branch_line="${line#branch refs/heads/}"
      # Count commits ahead of base
      local base
      base="$(get_base_branch)"
      local ahead
      ahead="$(git rev-list --count "${base}..${branch_line}" 2>/dev/null || echo "?")"
      echo -e "  ${GREEN}●${RESET} ${BOLD}${name}${RESET}  ${DIM}(${branch_line}, ${ahead} ahead)${RESET}"
      echo -e "    ${DIM}${path}${RESET}"
      name=""
    fi
  done

  echo ""
}

cmd_cd() {
  local name="${1:?usage: cw cd <name>}"
  local repo_root
  repo_root="$(get_repo_root)"
  local wt_path
  wt_path="$(worktree_path "$repo_root" "$name")"

  [[ -d "$wt_path" ]] || die "worktree '${name}' not found"
  echo "$wt_path"
}

cmd_open() {
  local name="${1:?usage: cw open <name> [prompt]}"
  shift
  local prompt="${*:-}"

  local repo_root
  repo_root="$(get_repo_root)"
  local wt_path
  wt_path="$(worktree_path "$repo_root" "$name")"

  [[ -d "$wt_path" ]] || die "worktree '${name}' not found"

  if [[ -n "$prompt" ]]; then
    info "Opening Claude Code in ${BOLD}${name}${RESET} with prompt..."
    echo -e "   ${DIM}\"${prompt}\"${RESET}"
    echo ""
    (cd "$wt_path" && claude "$prompt")
  else
    info "Opening Claude Code in ${BOLD}${name}${RESET}..."
    echo ""
    (cd "$wt_path" && claude)
  fi
}

cmd_merge() {
  local name="${1:?usage: cw merge <name> [--local]}"
  shift
  local local_only=false
  for arg in "$@"; do
    case "$arg" in
      --local) local_only=true ;;
      *) die "unknown flag: ${arg}" ;;
    esac
  done

  local repo_root
  repo_root="$(get_repo_root)"
  BASE_BRANCH="$(get_base_branch)"

  local wt_path branch
  wt_path="$(worktree_path "$repo_root" "$name")"
  branch="$(branch_name "$name")"

  [[ -d "$wt_path" ]] || die "worktree '${name}' not found"

  # Check for uncommitted changes in the worktree
  if ! (cd "$wt_path" && git diff --quiet 2>/dev/null && git diff --cached --quiet 2>/dev/null); then
    die "worktree '${name}' has uncommitted changes — commit or stash first"
  fi

  # Check there's actually something to merge
  local ahead
  ahead="$(git rev-list --count "${BASE_BRANCH}..${branch}" 2>/dev/null || echo "0")"

  if [[ "$ahead" == "0" ]]; then
    die "branch ${branch} has no commits ahead of ${BASE_BRANCH} — nothing to merge"
  fi

  echo -e "${BOLD}Merging ${name} → ${BASE_BRANCH}${RESET}"
  echo ""

  # Show a summary of changes
  info "Changes (${ahead} commits):"
  echo ""
  git log --oneline "${BASE_BRANCH}..${branch}" | while IFS= read -r log_line; do
    echo -e "   ${DIM}${log_line}${RESET}"
  done
  echo ""

  local files_changed
  files_changed="$(git diff --stat "${BASE_BRANCH}..${branch}" -- | tail -1)"
  echo -e "   ${DIM}${files_changed}${RESET}"
  echo ""

  if [[ "$local_only" == true ]]; then
    # --local: Squash merge locally, no push, no PR
    echo -n -e "   Squash merge into ${BOLD}${BASE_BRANCH}${RESET}? ${DIM}[Y/n]${RESET} "
    read -r confirm
    if [[ "$confirm" =~ ^[Nn]$ ]]; then
      info "Aborted."
      return
    fi

    # Build a commit message from the worktree's log
    local commit_msg
    commit_msg="$(printf "%s\n\n%s" \
      "feat: ${name}" \
      "$(git log --oneline "${BASE_BRANCH}..${branch}")"
    )"

    # Squash merge
    info "Merging..."
    git checkout "$BASE_BRANCH" --quiet
    if git merge --squash "$branch" --quiet 2>/dev/null; then
      git commit -m "$commit_msg" --quiet
      ok "Squash-merged ${BOLD}${branch}${RESET} into ${BOLD}${BASE_BRANCH}${RESET}"
    else
      echo ""
      warn "Merge conflicts detected. Resolve them, then run:"
      echo -e "   ${DIM}git commit${RESET}"
      echo -e "   ${DIM}cw rm ${name}${RESET}"
      return 1
    fi
  else
    # Default: Push branch and create PR (let GitHub handle the merge)
    echo -n -e "   Push branch and create PR? ${DIM}[Y/n]${RESET} "
    read -r confirm
    if [[ "$confirm" =~ ^[Nn]$ ]]; then
      info "Aborted."
      return
    fi

    local has_remote
    has_remote="$(git remote 2>/dev/null | head -1)"

    if [[ -z "$has_remote" ]]; then
      die "no git remote configured — use --local for local-only merge"
    fi

    info "Pushing branch ${BOLD}${branch}${RESET} to ${has_remote}..."
    if git push -u "$has_remote" "$branch" 2>/dev/null; then
      ok "Pushed branch to remote"
    else
      die "push failed — check your remote configuration"
    fi

    if command -v gh &>/dev/null; then
      info "Creating pull request..."
      local pr_url
      if pr_url=$(gh pr create --fill --head "$branch" --base "$BASE_BRANCH" 2>&1); then
        ok "PR created"
        echo -e "   ${DIM}${pr_url}${RESET}"
      else
        warn "Could not create PR via gh — you may need to open one manually"
        echo -e "   ${DIM}gh pr create --head ${branch} --base ${BASE_BRANCH}${RESET}"
      fi
    else
      warn "Install ${BOLD}gh${RESET} CLI to auto-create PRs: ${DIM}https://cli.github.com${RESET}"
      echo -e "   ${DIM}Or create PR manually from branch: ${branch}${RESET}"
    fi
  fi

  # Cleanup worktree (but handle branch differently based on mode)
  echo ""
  info "Cleaning up worktree..."
  git worktree remove "$wt_path" --force 2>/dev/null || rm -rf "$wt_path"
  git worktree prune

  local wt_dir="${repo_root}/${CW_DIR_PREFIX}"
  rmdir "$wt_dir" 2>/dev/null || true

  if [[ "$local_only" == true ]]; then
    # For local merge, delete the branch entirely
    git branch -D "$branch" 2>/dev/null || true
    ok "Done — ${BOLD}${name}${RESET} merged and cleaned up"
  else
    # For PR flow, keep the local branch reference (remote branch is what matters)
    # The branch will be deleted when PR is merged via GitHub
    git branch -D "$branch" 2>/dev/null || true
    ok "Done — PR created for ${BOLD}${name}${RESET}, worktree cleaned up"
    echo -e "   ${DIM}Remote branch ${branch} will be deleted when PR is merged${RESET}"
  fi
}

cmd_rm() {
  local name="${1:?usage: cw rm <name>}"
  local repo_root
  repo_root="$(get_repo_root)"
  local wt_path branch
  wt_path="$(worktree_path "$repo_root" "$name")"
  branch="$(branch_name "$name")"

  [[ -d "$wt_path" ]] || die "worktree '${name}' not found"

  info "Removing worktree ${BOLD}${name}${RESET}..."
  git worktree remove "$wt_path" --force 2>/dev/null || rm -rf "$wt_path"
  git worktree prune

  if git show-ref --verify --quiet "refs/heads/${branch}" 2>/dev/null; then
    if git branch -d "$branch" 2>/dev/null; then
      ok "Removed worktree and branch ${DIM}${branch}${RESET}"
    else
      warn "Branch ${branch} has unmerged changes."
      echo -n -e "   Force delete? ${DIM}[y/N]${RESET} "
      read -r confirm
      if [[ "$confirm" =~ ^[Yy]$ ]]; then
        git branch -D "$branch"
        ok "Removed worktree and force-deleted branch ${DIM}${branch}${RESET}"
      else
        ok "Removed worktree, kept branch ${DIM}${branch}${RESET}"
      fi
    fi
  else
    ok "Removed worktree ${BOLD}${name}${RESET}"
  fi
}

cmd_clean() {
  local repo_root
  repo_root="$(get_repo_root)"
  local wt_dir="${repo_root}/${CW_DIR_PREFIX}"

  if [[ ! -d "$wt_dir" ]] || [[ -z "$(ls -A "$wt_dir" 2>/dev/null)" ]]; then
    info "Nothing to clean."
    return
  fi

  warn "This will remove ALL cw worktrees:"
  for dir in "${wt_dir}"/*/; do
    [[ -d "$dir" ]] && echo -e "   ${DIM}$(basename "$dir")${RESET}"
  done

  echo -n -e "   Continue? ${DIM}[y/N]${RESET} "
  read -r confirm
  [[ "$confirm" =~ ^[Yy]$ ]] || { info "Aborted."; return; }

  for dir in "${wt_dir}"/*/; do
    [[ -d "$dir" ]] || continue
    local name
    name="$(basename "$dir")"
    cmd_rm "$name" 2>/dev/null || warn "Failed to remove ${name}"
  done

  rmdir "$wt_dir" 2>/dev/null || true
  git worktree prune
  ok "All clean."
}

cmd_help() {
  echo -e "${BOLD}cw${RESET} — Claude Worktree manager"
  echo ""
  echo -e "${BOLD}Usage:${RESET}"
  echo "  cw new <name> [flags] [prompt]  Create worktree + open claude"
  echo "  cw open <name> [prompt]         Open Claude in existing worktree"
  echo "  cw ls                           List active worktrees"
  echo '  cw cd <name>                    Print path (use: cd $(cw cd <name>))'
  echo "  cw merge <name> [--local]       Push branch + create PR (--local for local squash)"
  echo "  cw rm <name>                    Remove a worktree (no merge)"
  echo "  cw clean                        Remove all cw worktrees"
  echo "  cw help                         Show this help"
  echo ""
  echo -e "${BOLD}Flags for new:${RESET}"
  echo "  --open       Open Claude immediately (skip prompt)"
  echo "  --no-open    Don't open Claude (skip prompt)"
  echo "  (default)    Interactive — press Enter to open, ESC to skip"
  echo ""
  echo -e "${BOLD}Workflow:${RESET}"
  echo '  1. cw new auth "implement OAuth2 login"   # create + open claude'
  echo '  2. Claude works, commits as it goes'
  echo '  3. cw merge auth                          # push branch, open PR, cleanup'
  echo ""
  echo -e "${BOLD}Examples:${RESET}"
  echo '  cw new auth "implement OAuth2 login"       # interactive open prompt'
  echo '  cw new auth --open "implement OAuth2"      # open immediately'
  echo '  cw new api --no-open                       # create only, open later'
  echo '  cw open api                                # open existing worktree'
  echo '  cw open api "continue with tests"          # open with prompt'
  echo '  cw merge auth                              # push branch, create PR, cleanup'
  echo '  cw merge auth --local                      # squash merge locally, no PR'
  echo '  cw rm api                                  # discard without merging'
  echo '  cw clean'
  echo ""
  echo -e "${DIM}Worktrees live under <repo>/${CW_DIR_PREFIX}/<name>${RESET}"
  echo -e "${DIM}Branches are prefixed with ${CW_PREFIX}/${RESET}"
}

# ── Main ────────────────────────────────────────────────────────────────────
main() {
  local cmd="${1:-help}"
  shift 2>/dev/null || true

  case "$cmd" in
    new)   cmd_new "$@" ;;
    open)  cmd_open "$@" ;;
    ls)    cmd_ls ;;
    cd)    cmd_cd "$@" ;;
    merge) cmd_merge "$@" ;;
    rm)    cmd_rm "$@" ;;
    clean) cmd_clean ;;
    help|-h|--help) cmd_help ;;
    *)     die "unknown command: ${cmd}\nRun 'cw help' for usage." ;;
  esac
}

main "$@"
