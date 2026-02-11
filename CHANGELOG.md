# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.10](https://github.com/joyco-studio/cw/compare/v0.1.9...v0.1.10) (2026-02-11)


### Features

* make --verbose a global flag that impacts all commands ([7887ea0](https://github.com/joyco-studio/cw/commit/7887ea0854283dd524bfc68d606470436cc55360))

## [0.1.9](https://github.com/joyco-studio/cw/compare/v0.1.8...v0.1.9) (2026-02-11)


### Features

* add --verbose flag for hook output ([0621773](https://github.com/joyco-studio/cw/commit/06217739743f7383bdea1d835b104fd6a8bc0c47))
* auto-resume existing branch in `cw new` ([1521bcf](https://github.com/joyco-studio/cw/commit/1521bcf07024139181a65407308dd3145aa68602))


### Bug Fixes

* strip cw/ prefix from name and reject slashes ([9ca1272](https://github.com/joyco-studio/cw/commit/9ca127294bfb0822b501cfb6c2e659de49e2c469))

## [0.1.8](https://github.com/joyco-studio/cw/compare/v0.1.7...v0.1.8) (2026-02-10)


### Features

* add cw-hook.sh support for preserving untracked files across worktrees ([772979b](https://github.com/joyco-studio/cw/commit/772979ba4abf3b449200665eb77628f775bcadcd))
* add cw-hook.sh.example with .env.local and .vercel copy rules ([9a87d37](https://github.com/joyco-studio/cw/commit/9a87d37d4a7ccbd83aa01e73e46b34cd7d06d5a1))

## [0.1.7](https://github.com/joyco-studio/cw/compare/v0.1.6...v0.1.7) (2026-02-10)


### Bug Fixes

* force release ([c92dc9c](https://github.com/joyco-studio/cw/commit/c92dc9cc8c9ebdc12216671b7fd288fc2f44d511))

## [0.1.6](https://github.com/joyco-studio/cw/compare/v0.1.5...v0.1.6) (2026-02-09)


### Features

* trigger release ([b733515](https://github.com/joyco-studio/cw/commit/b733515e43cd45907163d2990efbe19ed13752a7))

## [0.1.5](https://github.com/joyco-studio/cw/compare/v0.1.4...v0.1.5) (2026-02-09)


### Features

* add source-aware entry point and improved tab completion ([e4d8987](https://github.com/joyco-studio/cw/commit/e4d8987d6863de1c823f35eea57d3fc4fc10cc69))

## [0.1.4](https://github.com/joyco-studio/cw/compare/v0.1.3...v0.1.4) (2026-02-09)


### Features

* add git-style descriptions to zsh tab completions ([cfa7e80](https://github.com/joyco-studio/cw/commit/cfa7e80af85d125d2f14c74f4e86565a0e525f0f))

## [0.1.3](https://github.com/joyco-studio/cw/compare/v0.1.2...v0.1.3) (2026-02-09)


### Bug Fixes

* use native zsh completion to fix excessive tab completion spacing ([cc5eacb](https://github.com/joyco-studio/cw/commit/cc5eacba30a41bfea63d31f3ac46af46e3055e26))

## [0.1.2](https://github.com/joyco-studio/cw/compare/v0.1.1...v0.1.2) (2026-02-09)


### Features

* add tab completion for bash and zsh ([82dfb33](https://github.com/joyco-studio/cw/commit/82dfb33f62a3506acb34607e012c99c0f068abb7))

## [0.1.1](https://github.com/joyco-studio/cw/compare/v0.1.0...v0.1.1) (2026-02-09)


### Features

* add release-please for automated versioning ([7e42573](https://github.com/joyco-studio/cw/commit/7e4257396d81ee6da19b723e91f24b691cbc37f2))

## [Unreleased]

## [0.1.0] - 2025-06-07

### Added

- `cw new` — create isolated git worktrees with auto dependency install
- `cw open` — open Claude Code in an existing worktree
- `cw ls` — list active worktrees with branch and commit info
- `cw cd` — cd into a worktree (shell integration)
- `cw merge` — push branch + create PR, or local squash merge with `--local`
- `cw rm` — remove a single worktree and its branch
- `cw clean` — remove all cw worktrees
- `cw upgrade` — self-update to the latest GitHub release
- `cw version` / `cw --version` — display current version
- Versioning system using semver and GitHub Releases
- Shell integration for bash and zsh (source-aware wrapper)
- Auto-detection of base branch (main/master)
- Auto-detection and installation of project dependencies (npm, yarn, pnpm)

[Unreleased]: https://github.com/joyco-studio/cw/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/joyco-studio/cw/releases/tag/v0.1.0
