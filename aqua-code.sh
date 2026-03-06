#!/bin/bash
set -e

# aqua-code: Claude Code + Ollama ワンコマンドランチャー
# ~/.claude/ とは完全に分離された環境で動作します

# Homebrew の PATH を確保（Apple Silicon / Intel 両対応）
if [ -f /opt/homebrew/bin/brew ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -f /usr/local/bin/brew ]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi

# デフォルトモデル（環境変数で上書き可能）
MODEL="${AQUA_CODE_MODEL:-glm-5:cloud}"

# Ollama が起動しているか確認、なければ起動
if ! curl -sf http://localhost:11434/api/tags >/dev/null 2>&1; then
  echo "Ollama を起動中..."
  ollama serve >/dev/null 2>&1 &
  # 起動待ち（最大15秒）
  for i in {1..15}; do
    sleep 1
    if curl -sf http://localhost:11434/api/tags >/dev/null 2>&1; then
      break
    fi
    if [ "$i" -eq 15 ]; then
      echo "エラー: Ollama が起動できませんでした"
      exit 1
    fi
  done
  echo "Ollama 起動完了"
fi

# Claude Code を Ollama 経由で起動（完全分離）
# インライン環境変数のため親シェルには影響しない
CLAUDE_CONFIG_DIR="$HOME/.aqua-code" \
ANTHROPIC_API_KEY=ollama \
ANTHROPIC_BASE_URL=http://localhost:11434 \
DISABLE_AUTOUPDATER=1 \
DISABLE_TELEMETRY=1 \
  claude --model "$MODEL" "$@"
