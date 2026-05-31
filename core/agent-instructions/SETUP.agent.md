# SETUP.agent.md

AI エージェント向け指示書。利用者が展開フォルダを開いて **「セットアップして」** と依頼したときに実行する。

---

## 役割

初回セットアップを完了させ、利用者固有のルールと lock ファイルを生成する。

## 前提

- 作業ディレクトリは AgentBase ワークスペースの root である。
- `core/` 配下は編集禁止。`rules/` 側に書き出す。

## 手順

### 1. セットアップ済みか確認

`core/.agent-base-lock.json` を読む。

- `version` が null または未設定 → **初回セットアップ** モード
- `version` が設定済み → 「既にセットアップ済み（v{version}）」と伝えて終了

### 2. 利用者に対話で質問

以下を確認する（推測で埋めない）。

- 会社 / 組織名
- 利用者の名前
- 主な役割（自由記述）
- AI 活用の主目的（自由記述）

### 3. Company Rule を生成

1. `core/templates/company-rule-template.md` を読む
2. プレースホルダを埋め、`rules/company/{COMPANY}_COMPANY_RULE.md` として書き出す
   - `{COMPANY}` は英大文字・数字・アンダースコアの識別子（例: `ACME`）

### 4. Personal Rule を生成

1. `core/templates/personal-rule-template.md` を読む
2. `rules/personal/{NAME}_PERSONAL_RULE.md` として書き出す
3. `auto_commit_policy: ask` を Personal Rule に記録する（既定）

### 5. ルート入口ファイルを更新

ルート `AGENTS.md` のプレースホルダを置換する。

- `{WORKSPACE_ROOT}` → 実際のパスまたはフォルダ名
- `{COMPANY_NAME}` → 組織名
- `{USER_NAME}` → 利用者名

`workspace-index.md` も `core/templates/workspace-index-template.md` を参考に初期化する。

### 6. lock ファイルを生成

`core/` 配下すべてと、以下のルート雛形ファイルの sha256 を計算し、`core/.agent-base-lock.json` を生成する。

**managed_file_hashes**（編集禁止・更新時に丸ごと差し替え）:

- `core/` 配下の全ファイル（本 lock ファイル自身を除く）

**root_template_hashes**（利用者が編集しうる雛形）:

- `AGENTS.md`
- `CLAUDE.md`
- `workspace-index.md`
- `.cursor/rules/agent-base.mdc`
- `.github/copilot-instructions.md`
- `GEMINI.md`
- `.windsurfrules`
- `.agents/rules/agent-base.md`
- `.agent/rules/agent-base.md`

lock の形式:

```json
{
  "version": "{VERSION from VERSION file}",
  "source": "https://github.com/KumaBase/agent-base/archive/refs/tags/v{VERSION}.zip",
  "installed_at": "{ISO8601}",
  "managed_file_hashes": { "...": "sha256:..." },
  "root_template_hashes": { "...": "sha256:..." }
}
```

### 7. Git 同期を提案

`core/agent-instructions/AUTOSYNC.agent.md` を読み、Git 同期セットアップを提案する（強制しない）。

### 8. 完了レポート

以下を簡潔に出力する。

- 生成したルールファイルのパス
- ルール読み込み順（`AGENTS.md` 参照）
- 自己修復: 「健康診断して」
- 更新: 「AgentBase を更新して」
- Git 同期の状態

---

## 禁止事項

- `core/` 配下のルール本文を利用者向けに書き換えない
- push / 外部公開 / リモート作成を明示承認なしに実行しない
