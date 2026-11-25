#!/usr/bin/env bash
# Install claude-deepseek: a launcher that runs Claude Code on DeepSeek's API.
# Works on Linux, macOS and WSL, from bash or zsh.
#
#   ./install.sh                 # install to ~/.local/bin
#   ./install.sh --dir ~/bin     # install somewhere else
#   ./install.sh --link          # symlink instead of copy (updates with `git pull`)
#   ./install.sh --shell zsh     # set up for zsh or bash (default: your login shell)
#   ./install.sh --no-rc         # don't touch ~/.zshrc / ~/.bashrc
#   ./install.sh --no-key        # skip the API key prompt

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="$REPO_DIR/bin/claude-deepseek"
COMP_SRC="$REPO_DIR/completions/_claude-deepseek"
DEST_DIR="$HOME/.local/bin"
COMP_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/zsh/site-functions"
LINK=0
ASK_KEY=1
EDIT_RC=1
TARGET_SHELL="$(basename "${SHELL:-bash}")"

MARK_BEGIN="# >>> claude-deepseek >>>"
MARK_END="# <<< claude-deepseek <<<"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dir)    DEST_DIR="${2:?--dir needs a path}"; shift 2 ;;
    --link)   LINK=1; shift ;;
    --shell)  TARGET_SHELL="${2:?--shell needs zsh or bash}"; shift 2 ;;
    --no-rc)  EDIT_RC=0; shift ;;
    --no-key) ASK_KEY=0; shift ;;
    -h|--help) sed -n '2,/^$/p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "unknown option: $1" >&2; exit 1 ;;
  esac
done

info() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33mwarning:\033[0m %s\n' "$*" >&2; }

# Show a path relative to $HOME so rc files stay portable.
home_path() { case "$1" in "$HOME"/*) printf '$HOME/%s' "${1#"$HOME"/}" ;; *) printf '%s' "$1" ;; esac; }

# install / ln with the right mode
place() {
  local src="$1" dest="$2" mode="$3"
  mkdir -p "$(dirname "$dest")"
  if [[ $LINK -eq 1 ]]; then ln -sfn "$src" "$dest"; else install -m "$mode" "$src" "$dest"; fi
}

# Replace (or add) our marked block in an rc file. $1 = file, stdin = block body.
write_rc_block() {
  local rc="$1" body tmp
  body="$(cat)"
  touch "$rc"
  tmp="$(mktemp)"
  # Drop any old block and trailing blank lines, then append the new block.
  awk -v b="$MARK_BEGIN" -v e="$MARK_END" '
    $0 == b {skip=1; next}
    $0 == e {skip=0; next}
    skip {next}
    /^$/ {held = held $0 "\n"; next}
    {printf "%s", held; held=""; print}' "$rc" > "$tmp"
  # cat > keeps the rc file's permissions and symlinks
  { cat "$tmp"; printf '\n%s\n%s\n%s\n' "$MARK_BEGIN" "$body" "$MARK_END"; } > "$rc"
  rm -f "$tmp"
}

case "$TARGET_SHELL" in
  zsh|bash) ;;
  *) warn "shell '$TARGET_SHELL' not recognised; rc file setup skipped."; EDIT_RC=0 ;;
esac

# 1. Dependencies
command -v curl >/dev/null || warn "curl not found; '--check' will not work."
if ! command -v claude >/dev/null; then
  warn "Claude Code ('claude') is not on your PATH."
  echo "    Install it first: https://docs.claude.com/en/docs/claude-code/setup"
fi

# 2. Launcher
DEST="$DEST_DIR/claude-deepseek"
place "$SRC" "$DEST" 755
info "Installed $DEST$([[ $LINK -eq 1 ]] && echo " -> $SRC")"

ON_PATH=0
case ":$PATH:" in *":$DEST_DIR:"*) ON_PATH=1 ;; esac

# 3. Shell setup
PATH_LINE="export PATH=\"$(home_path "$DEST_DIR"):\$PATH\""
RC_BODY=""
if [[ "$TARGET_SHELL" == zsh ]]; then
  RC="${ZDOTDIR:-$HOME}/.zshrc"
  place "$COMP_SRC" "$COMP_DIR/_claude-deepseek" 644
  info "Installed zsh completion to $COMP_DIR"
  [[ $ON_PATH -eq 0 ]] && RC_BODY="$PATH_LINE"$'\n'
  RC_BODY+="fpath=(\"$(home_path "$COMP_DIR")\" \$fpath)
if (( \$+functions[compdef] )); then
  autoload -Uz _claude-deepseek && compdef _claude-deepseek claude-deepseek
else
  autoload -Uz compinit && compinit -i
fi"
elif [[ "$TARGET_SHELL" == bash ]]; then
  # macOS Terminal opens login shells, which read ~/.bash_profile.
  if [[ "$(uname)" == Darwin ]]; then RC="$HOME/.bash_profile"; else RC="$HOME/.bashrc"; fi
  [[ $ON_PATH -eq 0 ]] && RC_BODY="$PATH_LINE"
fi

if [[ -n "$RC_BODY" ]]; then
  if [[ $EDIT_RC -eq 1 ]]; then
    ok=y
    if [[ -t 0 ]]; then
      read -r -p "Add claude-deepseek setup to $RC? [Y/n] " ok; ok="${ok:-y}"
    fi
    if [[ "$ok" =~ ^[Yy] ]]; then
      printf '%s\n' "$RC_BODY" | write_rc_block "$RC"
      info "Updated $RC (open a new terminal or run: source $RC)"
    else
      EDIT_RC=0
    fi
  fi
  if [[ $EDIT_RC -eq 0 ]]; then
    warn "Shell not configured. Add this to ${RC:-your shell rc file}:"
    printf '%s\n' "$RC_BODY" | sed 's/^/    /'
  fi
fi

# 4. API key
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
