#!/bin/bash
set -e

# aqua-code インストーラー（自己完結型）
# curl -fsSL https://raw.githubusercontent.com/YUALAB/aqua-code/main/install.sh -o /tmp/aqua-install.sh && bash /tmp/aqua-install.sh

BIN_DIR="$HOME/bin"
CONFIG_DIR="$HOME/.aqua-code"
DEFAULT_MODEL="glm-5:cloud"

echo "==================================="
echo "  aqua-code インストーラー"
echo "==================================="
echo ""

# --- macOS チェック ---
if [ "$(uname)" != "Darwin" ]; then
  echo "エラー: このツールは macOS 専用です"
  exit 1
fi

# --- Xcode Command Line Tools チェック & インストール ---
if ! xcode-select -p >/dev/null 2>&1; then
  echo "Xcode Command Line Tools をインストール中..."
  echo "ダイアログが表示されたら「インストール」をクリックしてください..."
  xcode-select --install
  # インストール完了を待機
  until xcode-select -p >/dev/null 2>&1; do
    sleep 5
  done
fi
echo "[✓] Xcode Command Line Tools"

# --- Homebrew チェック & インストール ---
if ! command -v brew >/dev/null 2>&1; then
  echo "Homebrew をインストール中..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  # Apple Silicon の場合 PATH を通す
  if [ -f /opt/homebrew/bin/brew ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  fi
fi
echo "[✓] Homebrew"

# --- Node.js チェック & インストール ---
if ! command -v node >/dev/null 2>&1; then
  echo "Node.js をインストール中..."
  brew install node
fi
echo "[✓] Node.js"

# --- Ollama チェック & インストール ---
if ! command -v ollama >/dev/null 2>&1; then
  echo "Ollama をインストール中..."
  brew install ollama
fi
echo "[✓] Ollama"

# --- Claude Code チェック & インストール ---
if ! command -v claude >/dev/null 2>&1; then
  echo "Claude Code CLI をインストール中..."
  npm install -g @anthropic-ai/claude-code
fi
echo "[✓] Claude Code CLI"

# --- Ollama 起動 ---
if ! curl -sf http://localhost:11434/api/tags >/dev/null 2>&1; then
  echo ""
  echo "Ollama を起動中..."
  ollama serve >/dev/null 2>&1 &
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

# --- モデル取得 ---
echo ""
echo "モデル ${DEFAULT_MODEL} を取得中..."
ollama pull "$DEFAULT_MODEL"
echo "[✓] モデル ${DEFAULT_MODEL}"

# --- 設定ディレクトリ作成 ---
mkdir -p "$CONFIG_DIR"
cat > "$CONFIG_DIR/settings.json" << 'SETTINGS'
{
  "permissions": {
    "allow": [],
    "deny": []
  },
  "preferences": {
    "verbose": false
  }
}
SETTINGS
echo "[✓] 設定ディレクトリ: $CONFIG_DIR"

# --- ランチャーを ~/bin に生成（埋め込み） ---
mkdir -p "$BIN_DIR"
cat > "$BIN_DIR/aqua-code" << 'LAUNCHER'
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
LAUNCHER
chmod +x "$BIN_DIR/aqua-code"
echo "[✓] ランチャー: $BIN_DIR/aqua-code"

# --- Homebrew PATH 永続化（~/.zprofile） ---
ZPROFILE="$HOME/.zprofile"
if [ -f /opt/homebrew/bin/brew ]; then
  BREW_LINE='eval "$(/opt/homebrew/bin/brew shellenv)"'
  if [ ! -f "$ZPROFILE" ] || ! grep -qF 'brew shellenv' "$ZPROFILE"; then
    echo "" >> "$ZPROFILE"
    echo "$BREW_LINE" >> "$ZPROFILE"
    echo "[✓] Homebrew PATH を ~/.zprofile に追加しました"
  fi
fi

# --- PATH 設定（~/.zshrc） ---
ZSHRC="$HOME/.zshrc"
PATH_LINE='export PATH="$HOME/bin:$PATH"'

if [ -f "$ZSHRC" ]; then
  if ! grep -qF 'PATH="$HOME/bin' "$ZSHRC"; then
    echo "" >> "$ZSHRC"
    echo "# aqua-code" >> "$ZSHRC"
    echo "$PATH_LINE" >> "$ZSHRC"
    echo "[✓] PATH を ~/.zshrc に追加しました"
  else
    echo "[✓] PATH は既に設定済み"
  fi
else
  echo "# aqua-code" > "$ZSHRC"
  echo "$PATH_LINE" >> "$ZSHRC"
  echo "[✓] ~/.zshrc を作成し PATH を追加しました"
fi

# --- 完了 ---
echo ""
echo "==================================="
echo "  インストール完了！"
echo "==================================="
echo ""
echo "使い方:"
echo "  aqua-code              # 対話モード起動"
echo "  aqua-code \"質問\"       # ワンショット実行"
echo "  aqua-code --help       # ヘルプ表示"
echo ""
echo "モデル変更:"
echo "  AQUA_CODE_MODEL=qwen3-coder:480b-cloud aqua-code"
echo ""
echo "※ 新しいターミナルを開くか、以下を実行してください:"
echo "  source ~/.zshrc"
echo ""
