# dots

Personal dotfiles. The real files live in this repo; `$HOME` symlinks to them.

## Install / update

```sh
git clone git@github.com:simonibsen/dots.git ~/src/dots   # first time
cd ~/src/dots && git pull                                 # update
./install.sh                                              # (re)create symlinks
```

- `./install.sh --status` — dry-run: shows what it would do, changes nothing.
- Any existing real file is backed up to `~/.dotfiles-backup/<timestamp>/`
  before being replaced with a symlink. Re-running is safe and idempotent.

## What's managed

- **`.claude/`** — Claude Code config: `CLAUDE.md`, routing-fleet agents, and
  the status-line scripts. Machine-local Claude files (`settings.json`,
  `CLAUDE.local.md`, `metrics/`) are intentionally **not** tracked, so work and
  home machines don't interfere. Env-specific instructions go in
  `~/.claude/CLAUDE.local.md` (imported by the shared `CLAUDE.md`).

## Not yet linked (drift — reconcile before adding to install.sh)

- **`.bashrc`** — `$HOME` copy is newer/richer than the repo copy.
- **`.vimrc`** — the repo copy is richer than the `$HOME` stub.

Decide which side is canonical, sync it into the repo, then add the file to the
`MANIFEST` in `install.sh`.
