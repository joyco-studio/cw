# cw — Claude Worktree Manager

A CLI tool for spinning up isolated git worktrees to run parallel Claude Code sessions.

## Installation

```bash
curl -fsSL https://raw.githubusercontent.com/joyco-studio/cw/main/install.sh | bash
```

Then restart your terminal.

## Usage

```bash
cw new <name> [flags] [prompt]  # Create a worktree + open Claude
cw open <name> [prompt]         # Open Claude in existing worktree
cw ls                           # List active worktrees
cw cd <name>                    # cd into a worktree
cw merge <name> [--local]       # Push branch + create PR (--local for local squash)
cw rm <name>                    # Remove a worktree (no merge)
cw clean                        # Remove all cw worktrees
cw hook init                    # Scaffold a cw-hook.sh in your repo
cw help                         # Show help
```

### Flags for `new`

| Flag | Description |
|------|-------------|
| `--open` | Open Claude immediately |
| `--no-open` | Don't open Claude |
| *(default)* | Interactive prompt |

### Flags for `merge`

| Flag | Description |
|------|-------------|
| *(default)* | Push branch to remote and create a PR via GitHub CLI |
| `--local` | Squash-merge locally into base branch (no push, no PR) |

## Workflow

```bash
# 1. Create a worktree and start Claude with a task
cw new auth "implement OAuth2 login"

# 2. Claude works in isolation, commits as it goes

# 3. When done, push branch and create a PR
cw merge auth
```

## Examples

```bash
cw new auth "implement OAuth2 login"   # Interactive open prompt
cw new api --open "build REST API"     # Open Claude immediately
cw new tests --no-open                 # Create only, open later
cw open tests                          # Open existing worktree
cw open tests "add unit tests"         # Open with a prompt
cw merge auth                          # Push branch + create PR
cw merge auth --local                  # Squash merge locally, no PR
cw rm api                              # Discard without merging
cw clean                               # Remove all worktrees
```

## Hooks

Worktrees only get files tracked by git. Untracked files like `.env`, `.vercel/`, or `.env.local` are lost on every `cw new`. The **hook system** solves this.

### Quick start

```bash
cw hook init    # scaffolds cw-hook.sh at your repo root
```

Edit the generated file to copy whatever your project needs:

```bash
#!/usr/bin/env bash
TARGET="$1"   # the new worktree path
SOURCE="$2"   # the repo root path

cp .env "$TARGET/"
cp .env.local "$TARGET/"
cp -r .vercel "$TARGET/"
```

The hook runs automatically after every `cw new`, right after dependency installation. It runs from the repo root directory.

### Contract

| Aspect | Detail |
|--------|--------|
| **File** | `cw-hook.sh` at the repository root |
| **Trigger** | Runs after `cw new` (after deps install, before opening Claude) |
| **Arguments** | `$1` = target worktree path, `$2` = repo root path |
| **Working dir** | Repository root |
| **Permissions** | Must be executable (`chmod +x`) |
| **Exit code** | `0` = success, non-zero = warning (won't abort worktree creation) |

### Tips

- **Copy vs symlink** — Use `cp` for files that might diverge per worktree (`.env`). Use `ln -s` for large shared caches you don't want to duplicate.
- **Git-ignore the hook** — If your hook contains secrets or is developer-specific, add `cw-hook.sh` to `.gitignore`. If it's useful for the whole team, commit it.
- **Idempotent copies** — The hook only runs on `cw new`, not on `cw open`, so each worktree gets one shot. Use `cp -n` (no-clobber) if you want extra safety.

## How It Works

- Worktrees are created under `<repo>/.worktrees/<name>`
- Branches are prefixed with `cw/` (e.g., `cw/auth`)
- Auto-detects `main` or `master` as the base branch
- Auto-installs dependencies (npm/yarn/pnpm) when creating worktrees
- Runs `cw-hook.sh` (if present) to copy untracked files into new worktrees

### Merge Behavior

**Default (PR mode):**
1. Pushes the worktree branch (`cw/<name>`) to remote
2. Creates a PR from that branch → base branch via `gh pr create`
3. Cleans up local worktree (remote branch stays until PR is merged)

**With `--local`:**
1. Squash-merges the branch into your base branch locally
2. Cleans up worktree and deletes the branch
3. No push, no PR — useful for local-only workflows

## Requirements

- Git
- Bash
- [Claude Code CLI](https://docs.anthropic.com/en/docs/claude-code)
- [GitHub CLI](https://cli.github.com) — for creating PRs (required for default `merge` behavior)
