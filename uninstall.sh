#!/usr/bin/env bash
# Remove claude-deepseek, its zsh completion and its block in your shell rc files.
#
#   ./uninstall.sh                 # remove ~/.local/bin/claude-deepseek
#   ./uninstall.sh --dir ~/bin     # if you installed elsewhere
#   ./uninstall.sh --purge         # also delete the saved API key

set -euo pipefail

DEST_DIR="$HOME/.local/bin"
COMP_FILE="${XDG_DATA_HOME:-$HOME/.local/share}/zsh/site-functions/_claude-deepseek"
PURGE=0
MARK_BEGIN="# >>> claude-deepseek >>>"
MARK_END="# <<< claude-deepseek <<<"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dir)   DEST_DIR="${2:?--dir needs a path}"; shift 2 ;;
    --purge) PURGE=1; shift ;;
    -h|--help) sed -n '2,/^$/p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "unknown option: $1" >&2; exit 1 ;;
  esac
done

remove() { if [[ -e "$1" || -L "$1" ]]; then rm -f "$1"; echo "Removed $1"; fi; }

remove "$DEST_DIR/claude-deepseek"
remove "$COMP_FILE"

# Strip our marked block (and the blank line before it) from rc files.
for rc in "${ZDOTDIR:-$HOME}/.zshrc" "$HOME/.bashrc" "$HOME/.bash_profile"; do
  if [[ ! -f "$rc" ]] || ! grep -qxF "$MARK_BEGIN" "$rc"; then continue; fi
  tmp="$(mktemp)"
  awk -v b="$MARK_BEGIN" -v e="$MARK_END" '
    $0 == b {skip=1; held=""; next}
    $0 == e {skip=0; next}
    skip {next}
    /^$/ {held = held $0 "\n"; next}
    {printf "%s", held; held=""; print}
    END {printf "%s", held}' "$rc" > "$tmp"
  cat "$tmp" > "$rc"   # keeps the file's permissions and symlinks
  rm -f "$tmp"
  echo "Removed claude-deepseek block from $rc"
done

KEY_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/deepseek"
if [[ $PURGE -eq 1 ]]; then
  rm -f "$KEY_DIR/api_key"; rmdir "$KEY_DIR" 2>/dev/null || true
  echo "Removed saved API key"
elif [[ -e "$KEY_DIR/api_key" ]]; then
  echo "Kept API key at $KEY_DIR/api_key (use --purge to delete it)"
fi
