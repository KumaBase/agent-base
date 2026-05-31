# 更新の仕組み（UPDATE）

AgentBase の更新は **`core/` だけを差し替える** 設計です。利用者の作業成果物は触りません。

## 何が更新されるか

| 領域 | 更新時の扱い |
|---|---|
| `core/` 全体 | 新版で丸ごと差し替え |
| `rules/`, `work/`, `modules/` 等 | **触らない** |
| ルート雛形（`AGENTS.md` 等） | 改変状況に応じて安全マージ |

## lock ファイル

`core/.agent-base-lock.json` に以下を記録します。

- **managed_file_hashes**: `core/` 配下の hash（改変検出・修復用）
- **root_template_hashes**: ルート雛形の配布時 hash（更新時マージ判定用）

## ルート雛形の 3-way 判定

1. 現ファイルの hash = lock の `root_template_hashes` → **未改変** → 新版で静かに上書き
2. hash が不一致 → **利用者が改変済み** → diff を提示し、マージ方針を選ばせる

## 依頼方法

AI に **「AgentBase を更新して」** と依頼する。

手順の詳細: `core/agent-instructions/UPDATE.agent.md`

## バージョン管理

- AgentBase 本体: `VERSION` / `CHANGELOG.md` / GitHub Releases（semver）
- あなたのワークスペース（Instance）: Git の commit 履歴のみ。Instance 自体に semver は付けない
