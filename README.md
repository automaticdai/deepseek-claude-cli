# deepseek-claude-cli

Run [Claude Code](https://docs.claude.com/en/docs/claude-code/overview) on
[DeepSeek](https://www.deepseek.com/) models through DeepSeek's
Anthropic-compatible API.

`claude-deepseek` is a small shell script, not a compiled binary. It sets the
right environment variables and then starts your normal `claude` command. Your
normal `claude` setup and Anthropic login are not changed, so you can use both
side by side.

## Requirements

- macOS, Linux or WSL
- Claude Code installed, with `claude` on your `PATH`
- `curl` (only for `--check`)
- A DeepSeek API key: <https://platform.deepseek.com/api_keys>

The scripts run with bash, which every Mac and Linux system already has
(including macOS's built-in bash 3.2). You can use them from zsh or bash.

## Install

```bash
git clone https://github.com/automaticdai/deepseek-claude-cli.git
cd deepseek-claude-cli
./install.sh
```

The installer:

1. Copies the launcher to `~/.local/bin`.
2. Sets up your shell (it detects zsh or bash from `$SHELL`):
   - **zsh** (default on macOS): installs tab completion and adds a short block
     to `~/.zshrc` that loads it, plus a `PATH` line if `~/.local/bin` isn't
     already on your `PATH`.
   - **bash**: adds a `PATH` line to `~/.bashrc` (`~/.bash_profile` on macOS),
     only if it's needed.

   It asks before changing the file. Its changes sit between
   `# >>> claude-deepseek >>>` markers, so reinstalling replaces them rather
   than adding duplicates, and `uninstall.sh` removes them cleanly.
3. Asks for your API key.

Open a new terminal afterwards, or `source ~/.zshrc`.

| Option | Effect |
|---|---|
| `--dir DIR` | Install somewhere other than `~/.local/bin` |
| `--link` | Symlink instead of copy, so `git pull` updates it |
| `--shell zsh\|bash` | Set up for this shell instead of your login shell |
| `--no-rc` | Don't edit any rc file; print the lines to add yourself |
| `--no-key` | Skip the API key prompt |

### zsh tab completion

With zsh you can tab-complete the launcher's own flags (`--check`,
`--set-key`, ...), common `claude` flags, and DeepSeek model names after
`--model`:

```zsh
claude-deepseek --model <TAB>
deepseek-flash[1m]  -- DeepSeek V4.1 Flash, 1M context (default)
deepseek-flash      -- DeepSeek V4.1 Flash
deepseek-v4-pro     -- DeepSeek V4 Pro
```

## Usage

```bash
claude-deepseek --check            # send one tiny request to test the key and model
claude-deepseek                    # start Claude Code on DeepSeek
claude-deepseek -p "explain this repo"   # any normal claude arguments work
claude-deepseek --set-key          # save or replace your API key
claude-deepseek --deepseek-help    # launcher help (--help is passed to claude)
```

### Choosing a model

| Model ID | Version | Notes |
|---|---|---|
| `deepseek-flash` | DeepSeek-V4.1-Flash | Default. 1M-token context, reads images, cheaper |
| `deepseek-v4-pro` | DeepSeek-V4-Pro | Stronger, up to 384K-token output, no image input |

```bash
DEEPSEEK_MODEL=deepseek-v4-pro claude-deepseek
```

Model names were checked against DeepSeek's docs on 2026-11-25. If DeepSeek
renames them, set `DEEPSEEK_MODEL` and `DEEPSEEK_FAST_MODEL`, or edit the
defaults at the top of `bin/claude-deepseek`.

## Configuration

| Variable | Default | Purpose |
|---|---|---|
| `DEEPSEEK_API_KEY` | (unset) | API key. Used instead of the saved key file when set |
| `DEEPSEEK_MODEL` | `deepseek-flash[1m]` | Main model (Opus and Sonnet slots) |
| `DEEPSEEK_FAST_MODEL` | `deepseek-flash` | Background tasks and subagents (Haiku slot) |
| `DEEPSEEK_EFFORT` | `max` | Claude Code effort level |
| `DEEPSEEK_BASE_URL` | `https://api.deepseek.com/anthropic` | API endpoint |
| `API_TIMEOUT_MS` | `600000` | Request timeout |
| `CLAUDE_CODE_AUTO_COMPACT_WINDOW` | `786432` | Context size at which Claude Code auto-compacts |

The `[1m]` suffix tells Claude Code that the model has a 1M-token context. It
is not part of the model ID that the API sees.

The key is saved to `~/.config/deepseek/api_key` (or under
`$XDG_CONFIG_HOME`), readable only by you. The launcher unsets
`ANTHROPIC_API_KEY` for its session, so an Anthropic key is never sent to
DeepSeek.

## What it sets

These match [DeepSeek's Claude Code guide](https://api-docs.deepseek.com/quick_start/agent_integrations/claude_code/):

```bash
ANTHROPIC_BASE_URL=https://api.deepseek.com/anthropic
ANTHROPIC_AUTH_TOKEN=<your key>
ANTHROPIC_MODEL=deepseek-flash[1m]
ANTHROPIC_DEFAULT_OPUS_MODEL=deepseek-flash[1m]
ANTHROPIC_DEFAULT_SONNET_MODEL=deepseek-flash[1m]
ANTHROPIC_DEFAULT_HAIKU_MODEL=deepseek-flash
CLAUDE_CODE_SUBAGENT_MODEL=deepseek-flash
CLAUDE_CODE_EFFORT_LEVEL=max
CLAUDE_CODE_AUTO_COMPACT_WINDOW=786432
CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1
```

## Limitations

DeepSeek's endpoint is compatible with the Anthropic API, but not every
feature is supported
([details](https://api-docs.deepseek.com/guides/anthropic_api)):

- Prompt caching (`cache_control`) is ignored.
- MCP servers passed through the API are ignored. MCP servers that Claude Code
  runs locally still work.
- Only DeepSeek's own web search and URL-reading tools are available.
- `deepseek-v4-pro` replaces images with `[Unsupported Image]`.

## Uninstall

```bash
./uninstall.sh            # remove the launcher, completion and rc-file block; keep the key
./uninstall.sh --purge    # also delete the saved key
```

Pass `--dir DIR` if you installed somewhere other than `~/.local/bin`.

## License

[MIT](LICENSE) © automaticdai

## Disclaimer

This is an unofficial community tool. It is not affiliated with or endorsed by
Anthropic or DeepSeek.
