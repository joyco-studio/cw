# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
