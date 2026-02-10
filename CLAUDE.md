# Project Rules

## Commit Messages

This project uses [release-please](https://github.com/googleapis/release-please) to automate releases. All commit messages **must** follow the [Conventional Commits](https://www.conventionalcommits.org/) format:

- `fix: <description>` — patches a bug (bumps PATCH version)
- `feat: <description>` — introduces a new feature (bumps MINOR version)
- `chore: <description>` — maintenance tasks that don't trigger a release

Breaking changes append `!` after the type (e.g., `feat!: <description>`) and bump MAJOR version.

Never use bare commit messages without a prefix. Every commit must start with one of: `fix:`, `feat:`, `chore:`, `fix!:`, `feat!:`, or `chore!:`.
