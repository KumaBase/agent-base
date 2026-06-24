# 更新の仕組み（UPDATE）

AgentBase の更新は **`core/` だけを差し替える** 設計です。利用者の作業成果物は触りません。

## 実行方法

### Claude Code の場合（推奨）

```
/core-update
```

Slash Command を実行すると、Skill が `core/updater/*.sh` を呼び出して更新を行います。

### すべての AI ツール

AI に **「AgentBase を更新して」** と依頼します。`core/agent-instructions/UPDATE.agent.md` に従い、`core/updater/*.sh` を実行します。

### セッション開始時の自動チェック

Claude Code を使う場合、セッション開始時に自動的に新版の有無をチェックします。
新版があれば案内が表示されます（`auto_update_policy` で挙動を変更可能）。

## auto_update_policy

優先順位:
1. `rules/personal/*_PERSONAL_RULE.md` の `auto_update_policy`
2. `.claude/settings.json` の `auto_update_policy`
3. デフォルト `auto`

| 値 | セッション開始時の挙動 |
|---|---|
| `auto` | 新版があれば AI が案内（推奨） |
| `ask` | 新版があれば AI が確認 |
| `manual` | チェックしない（`/core-update` のみ） |
| `compact` | `manual` と同じ（コンテキスト節約向け） |

## 何が更新されるか

| 領域 | 更新時の扱い |
|---|---|
| `core/` 全体 | 新版で丸ごと差し替え |
| `rules/`, `work/`, `modules/` 等 | **触らない** |
| ルート雛形（`AGENTS.md` 等） | 改変状況に応じて安全マージ |

## 完全性検証

GitHub Release には `checksums.txt` が添付され、以下の SHA256 を記録します:

- ZIP アーカイブ全体
- `core/` 配下の各ファイル

`apply-update.sh` は ZIP ダウンロード後に `checksums.txt` で検証します。
検証失敗時は更新を中止します。

> **注意**: v0.0.1 には `checksums.txt` が添付されていません。v0.0.2 以降のみ検証対象です。

## lock ファイル

`core/.agent-base-lock.json` に以下を記録します。

- `version`: 現在のバージョン
- `source`: 配布元 URL
- `installed_at`: セットアップ日時
- `last_update_check_at`: 最終更新確認日時（24h レート制限用）
- **managed_file_hashes**: `core/` 配下の hash（改変検出・修復用）
- **root_template_hashes**: ルート雛形の配布時 hash（更新時マージ判定用）

## ルート雛形の 3-way 判定

1. 現ファイルの hash = lock の `root_template_hashes` → **未改変** → 新版で静かに上書き
2. hash が不一致 → **利用者が改変済み** → 新版を `{file}.new` として保存し、マージを案内

## ロールバック

`apply-update.sh` は事前に `chore: snapshot before agent-base update` コミットを作成します。
戻す場合:

```bash
git reset --hard HEAD~1
```

（更新コミットが1つの場合。スナップショットが2つ前の場合は `HEAD~2`）

## Git hooks による保護

```bash
git config core.hooksPath core/git-hooks
```

で `core/` 配下の不正編集を pre-commit でブロックします。
公式アップデート（`/core-update` 経由）のみ許可されます。

詳細は `core/git-hooks/README.md` 参照。

## 手順の詳細

- AI 向け手順書: `core/agent-instructions/UPDATE.agent.md`
- アップデータ本体: `core/updater/`（`README.md` 参照）

## バージョン管理

- AgentBase 本体: `VERSION` / `CHANGELOG.md` / GitHub Releases（semver）
- あなたのワークスペース（Instance）: Git の commit 履歴のみ。Instance 自体に semver は付けない

## 対応環境

- **macOS / Linux**：標準環境で動作
- **Windows**：[Git for Windows](https://git-scm.com/download/win) の **Git Bash** で使用（PowerShell 版は未対応・今後の拡張対象）
- 依存ツール：`bash` 3.2+ / `curl` / `git` / `shasum` または `sha256sum` / `unzip` または `tar`
