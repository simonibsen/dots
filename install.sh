#!/usr/bin/env bash
# dots installer — idempotently symlink tracked dotfiles into $HOME.
#
# SAFE BY CONSTRUCTION:
#   - already-correct symlinks are left alone (idempotent)
#   - any existing real file is BACKED UP before being replaced with a symlink
#   - --status makes no changes at all (dry-run)
#
# Usage:
#   ./install.sh            create/repair the symlinks
#   ./install.sh --status   show what would change, touch nothing
#
# "Update dots" = `git pull` (symlinked files update instantly) then rerun
# ./install.sh to pick up any newly-tracked files.
set -euo pipefail

DOTS="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"

# Files to link:  $HOME/<path>  ->  $DOTS/<path>
# .bashrc is the general/public part; machine-local bits are sourced from
# ~/.bashrc.local (not tracked).
MANIFEST=(
  .bashrc
  .vimrc
  .gitconfig
  .claude/CLAUDE.md
  .claude/statusline-command.sh
  .claude/subagent-statusline.sh
  .claude/agents/search-haiku.md
  .claude/agents/worker-sonnet.md
  .claude/agents/reason-fable.md
)

DRY=0
[ "${1:-}" = "--status" ] && DRY=1

link_one() {
  local rel="$1" src="$DOTS/$rel" dst="$HOME/$rel"
  if [ ! -e "$src" ]; then
    echo "  MISSING-IN-REPO  $rel"
    return
  fi
  if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
    echo "  ok               $rel"
    return
  fi
  if [ -e "$dst" ] || [ -L "$dst" ]; then
    echo "  BACKUP+LINK      $rel  (existing -> ~/.dotfiles-backup/)"
    if [ "$DRY" = 0 ]; then
      mkdir -p "$BACKUP/$(dirname "$rel")"
      mv "$dst" "$BACKUP/$rel"
    fi
  else
    echo "  LINK             $rel"
  fi
  if [ "$DRY" = 0 ]; then
    mkdir -p "$(dirname "$dst")"
    ln -s "$src" "$dst"
  fi
}

# Git hooks to deploy. Unlike dotfiles these are not $HOME symlinks: each is
# symlinked into the git template dir (so new clones/inits inherit it) and into
# this repo's own .git/hooks (so dots itself is covered now). We deliberately do
# NOT set core.hooksPath globally — that would silently disable every other
# repo's own hooks.
GIT_TEMPLATE_HOOKS="$HOME/.git_templates/hooks"
HOOKS=(
  prepare-commit-msg
)

link_hook() {
  local name="$1"
  local src="$DOTS/git-hooks/$name"
  if [ ! -e "$src" ]; then
    echo "  MISSING-IN-REPO  git-hooks/$name"
    return
  fi
  [ "$DRY" = 0 ] && chmod +x "$src"
  local dst
  for dst in "$GIT_TEMPLATE_HOOKS/$name" "$DOTS/.git/hooks/$name"; do
    if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
      echo "  ok               hook $dst"
      continue
    fi
    if [ -e "$dst" ] || [ -L "$dst" ]; then
      echo "  BACKUP+LINK      hook $dst  (existing -> ~/.dotfiles-backup/)"
      if [ "$DRY" = 0 ]; then
        mkdir -p "$BACKUP/hooks"
        mv "$dst" "$BACKUP/hooks/$(basename "$dst").$(basename "$(dirname "$(dirname "$dst")")")"
      fi
    else
      echo "  LINK             hook $dst"
    fi
    if [ "$DRY" = 0 ]; then
      mkdir -p "$(dirname "$dst")"
      ln -s "$src" "$dst"
    fi
  done
}

echo "dots at: $DOTS"
[ "$DRY" = 1 ] && echo "(dry-run — nothing will change)"
for rel in "${MANIFEST[@]}"; do
  link_one "$rel"
done
for hook in "${HOOKS[@]}"; do
  link_hook "$hook"
done
if [ "$DRY" = 0 ] && [ -d "$BACKUP" ]; then
  echo "replaced files backed up to: $BACKUP"
fi
echo "done."
echo
echo "note: existing repos cloned before this hook won't have it — re-run"
echo "      'git init' inside them to re-apply the template, or symlink"
echo "      $DOTS/git-hooks/prepare-commit-msg into <repo>/.git/hooks/."
