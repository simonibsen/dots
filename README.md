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

## Shared + local split

This repo holds only the **general** config — the parts that are safe to commit
to a public repo and identical on every machine. Anything machine-specific,
work-specific, or secret stays in an untracked `*.local` companion in `$HOME`
that the shared file pulls in at the end. The repo never sees it.

Each shared file loads its local companion through that tool's own include
mechanism:

| Shared file (tracked)   | Local companion (untracked) | How it's loaded                        |
|-------------------------|-----------------------------|----------------------------------------|
| `.bashrc`               | `~/.bashrc.local`           | `[ -f ~/.bashrc.local ] && . ~/.bashrc.local` |
| `.claude/CLAUDE.md`     | `~/.claude/CLAUDE.local.md` | `@~/.claude/CLAUDE.local.md` import     |
| `.gitconfig`            | `~/.gitconfig.local`        | `[include] path = ~/.gitconfig.local`   |

The local files are created by hand per machine — `install.sh` neither creates
nor links them, and the shared files tolerate their absence (a missing
companion is simply skipped). What belongs in them:

- **Secrets and secret loaders** — API tokens, anything read from 1Password or a
  credential store.
- **Work-specific config** — internal tooling, employer paths, VPN/SSO helpers.
- **Machine-specific paths** — app locations that differ between laptops.

Nothing identifying or sensitive lives in the tracked files. Git identity is
**fail-closed**: `.gitconfig` sets no global name/email (`useConfigOnly = true`),
so every repo requires an explicit per-repo `user.email` — a wrong-identity
commit fails rather than silently using the wrong address.

## What's managed

- **`.bashrc`** — general shell config: aliases, prompt, and helper functions.
- **`.claude/`** — Claude Code config: `CLAUDE.md`, routing-fleet agents, and the
  status-line scripts. Machine-local Claude files (`settings.json`, `metrics/`)
  are intentionally not tracked so work and home machines don't interfere.
- **`.vimrc`** — general vim config.
- **`.gitconfig`** — general git config + SSH commit signing.

See [Shared + local split](#shared--local-split) for where the machine-specific
half of `.bashrc`, `CLAUDE.md`, and `.gitconfig` lives.
