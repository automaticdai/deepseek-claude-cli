#!/usr/bin/env bash
# Install claude-deepseek: a launcher that runs Claude Code on DeepSeek's API.
#
#   ./install.sh                 # install to ~/.local/bin
#   ./install.sh --dir ~/bin     # install somewhere else
#   ./install.sh --link          # symlink instead of copy (updates with `git pull`)
#   ./install.sh --no-key        # skip the API key prompt

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="$REPO_DIR/bin/claude-deepseek"
DEST_DIR="$HOME/.local/bin"
LINK=0
ASK_KEY=1

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dir)    DEST_DIR="${2:?--dir needs a path}"; shift 2 ;;
    --link)   LINK=1; shift ;;
    --no-key) ASK_KEY=0; shift ;;
    -h|--help) sed -n '2,8p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "unknown option: $1" >&2; exit 1 ;;
  esac
done

info() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33mwarning:\033[0m %s\n' "$*" >&2; }

# 1. Dependencies
command -v curl >/dev/null || warn "curl not found; '--check' will not work."
if ! command -v claude >/dev/null; then
  warn "Claude Code ('claude') is not on your PATH."
  echo "    Install it first: https://docs.claude.com/en/docs/claude-code/setup"
fi

# 2. Install the launcher
mkdir -p "$DEST_DIR"
DEST="$DEST_DIR/claude-deepseek"
if [[ $LINK -eq 1 ]]; then
  ln -sfn "$SRC" "$DEST"
  info "Linked $DEST -> $SRC"
else
  install -m 755 "$SRC" "$DEST"
  info "Installed $DEST"
fi

case ":$PATH:" in
  *":$DEST_DIR:"*) ;;
  *) warn "$DEST_DIR is not on your PATH. Add this to your shell rc file:"
     echo "    export PATH=\"$DEST_DIR:\$PATH\"" ;;
esac

# 3. API key
KEY_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/deepseek/api_key"
if [[ $ASK_KEY -eq 1 && -z "${DEEPSEEK_API_KEY:-}" && ! -s "$KEY_FILE" ]]; then
  if [[ -t 0 ]]; then
    info "No DeepSeek API key found (get one at https://platform.deepseek.com/api_keys)."
    "$DEST" --set-key || warn "Key not saved; run 'claude-deepseek --set-key' later."
  else
    warn "No API key found. Run 'claude-deepseek --set-key' later."
  fi
else
  info "API key already configured (or skipped)."
fi

info "Done. Try:  claude-deepseek --check   then   claude-deepseek"
