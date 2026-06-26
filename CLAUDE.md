# OpenWolf

@.wolf/OPENWOLF.md

This project uses OpenWolf for context management. Read and follow .wolf/OPENWOLF.md every session. Check .wolf/cerebrum.md before generating code. Check .wolf/anatomy.md before reading files.

# Repository Conventions

This repository builds Loop3E assets; it should not behave like an installed Loop3E runtime.

- Keep Codex-consumed source assets under `codex/agents/` and `codex/skills/`.
- Keep repository tooling in top-level `scripts/` and `tests/`.
- Keep full workflow behavior in `codex/skills/mloop/SKILL.md` and `docs/codex-superpowers-loop3e.md`, not in this repository instruction file.
- Use `scripts/install-loop3e.sh` for Codex home changes. Do not edit `~/.codex` directly while developing this repo.
- Runtime artifacts belong under `.loop3e/` and should be created only by actual mloop runs.
