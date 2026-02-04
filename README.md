# cw — Claude Worktree Manager

A CLI tool for spinning up isolated git worktrees to run parallel Claude Code sessions.

## Installation

```bash
curl -fsSL https://raw.githubusercontent.com/joyco-studio/cw/main/cw.sh -o ~/.local/bin/cw && chmod +x ~/.local/bin/cw
```

> **Note:** Make sure `~/.local/bin` exists and is in your PATH. If not:
> ```bash
> mkdir -p ~/.local/bin
> echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc  # or ~/.bashrc
> ```

## Usage

```bash
cw new <name> [flags] [prompt]  # Create a worktree + open Claude
cw open <name> [prompt]         # Open Claude in existing worktree
cw ls                           # List active worktrees
cw cd <name>                    # Print path (use: cd $(cw cd <name>))
cw merge <name> [--local]       # Push branch + create PR (--local for local squash)
cw rm <name>                    # Remove a worktree (no merge)
cw clean                        # Remove all cw worktrees
cw help                         # Show help
```

### Flags for `new`

| Flag | Description |
|------|-------------|
| `--open` | Open Claude immediately |
| `--no-open` | Don't open Claude |
| *(default)* | Interactive prompt |

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

## How It Works

- Worktrees are created under `<repo>/.worktrees/<name>`
- Branches are prefixed with `cw/` (e.g., `cw/auth`)
- Auto-detects `main` or `master` as the base branch
- Auto-installs dependencies (npm/yarn/pnpm) when creating worktrees
- Creates PRs via GitHub CLI (`gh`) if available

## Requirements

- Git
- Bash
- [Claude Code CLI](https://docs.anthropic.com/en/docs/claude-code)
- *(Optional)* [GitHub CLI](https://cli.github.com) for auto-creating PRs
