# SETUP.agent.md

AI エージェント向け指示書。利用者が展開フォルダを開いて **「セットアップして」** と依頼したときに実行する。

---

## 役割

初回セットアップを完了させ、利用者固有のルールと lock ファイルを生成する。

## 前提

- 作業ディレクトリは AgentBase ワークスペースの root である。
- `core/` 配下は編集禁止。`rules/` 側に書き出す。
- 実行環境の前提：
  - **macOS / Linux**：標準環境で動作
  - **Windows**：[Git for Windows](https://git-scm.com/download/win) の **Git Bash** 上で実行することを前提。PowerShell は未対応（今後の拡張対象）。Windows 利用者には先に Git for Windows のインストールを案内する。
  - 必須ツール：`bash`（3.2 以上）・`curl`・`git`・`shasum` または `sha256sum`・`unzip` または `tar`

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
4. `auto_update_policy: auto` を Personal Rule に記録する（既定）
   - `auto`: セッション開始時に新版があれば案内（推奨）
   - `ask`: セッション開始時に新版があれば確認
   - `manual`: セッション開始時の自動チェックを無効化（`/core-update` で手動実行）
   - `compact`: `manual` と同じ（コンテキスト節約を好む場合）

### 5. ルート入口ファイルを更新

ルート `AGENTS.md` のプレースホルダを置換する。

- `{WORKSPACE_ROOT}` → 実際のパスまたはフォルダ名
- `{COMPANY_NAME}` → 組織名
- `{USER_NAME}` → 利用者名

`workspace-index.md` も `core/templates/workspace-index-template.md` を参考に初期化する。

### 6. lock ファイルを生成

`core/updater/lib/lock.sh` の `lock_regenerate` 関数を使用するか、以下を手動で実施:

1. `core/` 配下すべて（`core/.agent-base-lock.json` 自身を除く）の sha256 を計算
2. 以下のルート雛形ファイルの sha256 を計算

**managed_file_hashes**（編集禁止・更新時に丸ごと差し替え）:

- `core/` 配下の全ファイル（本 lock ファイル自身を除く）
  - `core/rules/`, `core/runtime/`, `core/templates/`, `core/agent-instructions/`
  - `core/updater/`（アップデータ本体）
  - `core/git-hooks/`（pre-commit 等）
  - `core/DO_NOT_EDIT.md`

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
- `.claude/settings.json`（Claude Code 設定・hooks 登録）
- `.claude/hooks/session-start.sh`（セッション開始時フック）
- `.claude/skills/core-update/SKILL.md`（`/core-update` Skill）

lock の形式:

```json
{
  "version": "{VERSION from VERSION file}",
  "source": "https://github.com/KumaBase/agent-base/archive/refs/tags/v{VERSION}.zip",
  "installed_at": "{ISO8601}",
  "last_update_check_at": null,
  "managed_file_hashes": { "...": "sha256:..." },
  "root_template_hashes": { "...": "sha256:..." }
}
```

`last_update_check_at` は `check-update.sh` 実行時に更新される（24h レート制限用）。

### 7. Git 同期を提案（強く推奨）

`core/agent-instructions/AUTOSYNC.agent.md` を読み、Git 同期セットアップを提案する。

**Git は強く推奨**。AgentBase は Git と組み合わせることで真価を発揮するため。ユーザーが Git 不慣れな場合は特に、以下のメリットを分かりやすく伝える：

- **更新時のロールバック**: `/core-update` で問題が起きても、1コマンドで元の状態に戻せる
- **core/ の誤編集・不正編集からの保護**: `git config core.hooksPath core/git-hooks` で事前検知
- **変更履歴**: ルール変更や作業の進捗が全て残る
- **バックアップ**: リモート（GitHub 等）に Push すれば PC 故障時も復元可能

AI の挙動：
- 強制はしない。ユーザーが明確に「Git は使わない」と言ったら従う
- その場合、`rules/personal/*_PERSONAL_RULE.md` に `git_setup_policy: dismissed` を記録する
- dismissed の場合は以降のセッションで Git 推奨メッセージを出さない
- Git なしでも基本機能は動くが、ロールバック・保護・履歴は効かない旨を伝える

提案の形式（ユーザーが Git 不慣れなら特に簡潔に）：

> 続いて、Git というバージョン管理の設定をおすすめします（強く推奨）。
> 設定しておくと：
> - AgentBase の更新で問題が起きてもすぐ元に戻せる
> - ファイルを誤って編集してしまっても検知できる
> - 作業履歴が残る
>
> 「Git 同期を設定して」と声をかけていただければ、私が手順を案内します。

### 8. 完了レポート

以下を簡潔に出力する。

- 生成したルールファイルのパス
- ルール読み込み順（`AGENTS.md` 参照）
- 自己修復: 「健康診断して」または `/self-heal`
- 更新: 「AgentBase を更新して」または `/core-update`（Claude Code）
- Git 同期の状態
- **Git hooks の有効化**（推奨）:
  ```bash
  git config core.hooksPath core/git-hooks
  ```
  これにより `core/` 配下の誤編集・不正編集が pre-commit でブロックされる。
  詳細は `core/git-hooks/README.md` 参照。

---

## 禁止事項

- `core/` 配下のルール本文を利用者向けに書き換えない
- push / 外部公開 / リモート作成を明示承認なしに実行しない
