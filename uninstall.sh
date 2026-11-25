#!/usr/bin/env bash
# Remove claude-deepseek.
#
#   ./uninstall.sh                 # remove ~/.local/bin/claude-deepseek
#   ./uninstall.sh --dir ~/bin     # if you installed elsewhere
#   ./uninstall.sh --purge         # also delete the saved API key

set -euo pipefail

DEST_DIR="$HOME/.local/bin"
PURGE=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dir)   DEST_DIR="${2:?--dir needs a path}"; shift 2 ;;
    --purge) PURGE=1; shift ;;
    -h|--help) sed -n '2,6p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "unknown option: $1" >&2; exit 1 ;;
  esac
done

DEST="$DEST_DIR/claude-deepseek"
if [[ -e "$DEST" || -L "$DEST" ]]; then
  rm -f "$DEST"; echo "Removed $DEST"
else
  echo "Nothing at $DEST"
fi

KEY_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/deepseek"
if [[ $PURGE -eq 1 ]]; then
  rm -f "$KEY_DIR/api_key"; rmdir "$KEY_DIR" 2>/dev/null || true
  echo "Removed saved API key"
elif [[ -e "$KEY_DIR/api_key" ]]; then
  echo "Kept API key at $KEY_DIR/api_key (use --purge to delete it)"
fi
