# aqua-code

Claude Code + Ollama ワンコマンドランチャー。

`aqua-code` と打つだけで、Ollama 経由の Claude Code が起動します。
既存の Claude Code 設定（`~/.claude/`）とは完全に分離されています。

## インストール

ターミナルにこれを貼るだけ:

```bash
curl -fsSL https://raw.githubusercontent.com/YUALAB/aqua-code/main/install.sh | bash
```

全部自動でインストールされます:

- Xcode Command Line Tools
- Homebrew
- Node.js
- Ollama
- Claude Code CLI
- `glm-5:cloud` モデル
- `~/.aqua-code/settings.json`（分離設定）
- `~/bin/aqua-code`（ランチャー）
- `~/.zshrc` に PATH 追加（重複時スキップ）

## 使い方

```bash
# 対話モード
aqua-code

# ワンショット実行
aqua-code "このコードの問題点を教えて"

# ヘルプ
aqua-code --help

# 引数をそのまま claude に渡せる
aqua-code --verbose "デバッグモードで質問"
```

## モデル変更

デフォルトは `glm-5:cloud` です。`AQUA_CODE_MODEL` 環境変数で変更できます:

```bash
# 一時的に変更
AQUA_CODE_MODEL=qwen3-coder:480b-cloud aqua-code

# 永続化（~/.zshrc に追加）
echo 'export AQUA_CODE_MODEL=qwen3-coder:480b-cloud' >> ~/.zshrc
```

## 仕組み

```
aqua-code コマンド
    ↓
Ollama 起動確認（停止中なら自動起動）
    ↓
環境変数をインラインで設定（export しない = 親シェルに影響なし）
  - CLAUDE_CONFIG_DIR=$HOME/.aqua-code  ← ~/.claude/ と完全分離
  - ANTHROPIC_BASE_URL=http://localhost:11434
  - ANTHROPIC_API_KEY=ollama
    ↓
claude --model glm-5:cloud "$@"
```

## アンインストール

```bash
# ランチャー削除
rm ~/bin/aqua-code

# 設定ディレクトリ削除
rm -rf ~/.aqua-code

# プロジェクトディレクトリ削除（オプション）
rm -rf ~/aqua-code

# ~/.zshrc から aqua-code 関連行を削除（オプション）
# "# aqua-code" と次の export PATH 行を手動で削除
```

## 依存関係

| ソフトウェア | 最低バージョン |
|---|---|
| macOS | - |
| Homebrew | - |
| Ollama | 0.17+ |
| Claude Code CLI | - |

## トラブルシューティング

**`aqua-code: command not found`**
→ `source ~/.zshrc` を実行するか、新しいターミナルを開いてください

**Ollama が起動しない**
→ `ollama serve` を手動実行して確認してください

**モデルが見つからない**
→ `ollama pull glm-5:cloud` で手動取得してください
