# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

> **ベータ方針**
> AgentBase は **v1.0.0 に到達するまでベータ扱い** です。0.x 系のリリースでは、ルール体系・ディレクトリ構成・`core/` の内容・エージェント指示書が破壊的に変更される可能性があります。GitHub Releases では `--prerelease` で配布されます。
> 利用者は AI に「AgentBase を更新して」と依頼することで、`core/` のみが安全に差し替わります（`rules/`, `work/`, `modules/` 等の利用者領域は触られません）。詳細は [`docs/UPDATE.md`](docs/UPDATE.md) を参照。

## [Unreleased]

## [0.0.2] - 2026-07-09

### Added

- 自動アップデート機能（`core/updater/`）
  - `check-update.sh`: GitHub Releases との比較で新版の有無を確認。24h レート制限付き
  - `apply-update.sh`: ZIP ダウンロード → `checksums.txt` で完全性検証 → `core/` 差し替え → `lock.json` 再生成 → コミットまで一括実行。`--dry-run`, `--skip-snapshot` オプション
  - `self-test.sh`: `lock.json` と `core/` の hash 整合性を検証（`--json` 出力対応）
  - `lib/hash.sh`, `lib/lock.sh`, `lib/github.sh`, `lib/policy.sh`, `lib/root-merge.sh`: 基盤ライブラリ
- Claude Code Slash Command `/core-update`（`.claude/skills/core-update/SKILL.md`）
  - ホワイトリスト形式の `allowed-tools` / `disallowed-tools`（`git push`, `rm -rf` 等をブロック）
- セッション開始時の自動更新チェック（`.claude/hooks/session-start.sh`）
  - `auto_update_policy`（`auto` | `ask` | `manual` | `compact`）で挙動切替可能
  - `compact` リジューム時はスキップ（コンテキスト節約）
  - ネットワークエラー時は常に exit 0 でセッションをブロックしない
- `.claude/settings.json`: `SessionStart` フック登録、`auto_update_policy` デフォルト値
- `core/` 技術的保護（`core/git-hooks/`）
  - `commit-msg`: `core/` 配下の変更を検知し、公式アップデート（コミットメッセージ + `lock.json` ステージのセット判定）以外はブロック。`lock.json` 単体の変更（更新確認時刻の記録・セットアップ時の lock 生成）は許可
  - 有効化: `git config core.hooksPath core/git-hooks`
- GitHub Actions CI
  - `release.yml`: `v*` タグ push で Release を作成し `checksums.txt` を添付。0.x 系は `--prerelease`
  - `integrity.yml`: PR 時に `lock.json` と `core/` の整合性を検証
- `lock.json` に `last_update_check_at` フィールドを追加
- セッション開始時にセットアップ未完了（`lock.json` の version が null）を検知した場合、AI がユーザーへセットアップの案内を自発的に行うよう `session-start.sh` を拡張
- `/core-update` Skill でセットアップ未完了を検知した場合のユーザー向け案内文を平易な日本語で明確化
- Git 設定の推奨（`git_setup_policy: auto|dismissed`）
  - セッション開始時に Git 未初期化・リモート未設定・hooks 未有効化を検知した場合、AI がユーザーへ設定を推奨
  - `SETUP.agent.md` で Git 同期を「強く推奨」に格上げ、メリット（ロールバック・保護・履歴・バックアップ）を明記
  - `/core-update` 実行時に Git 未設定を検知した場合、更新前に注意喚起（ロールバック不可など）
  - ユーザーが意図的に Git を使わない場合は `git_setup_policy: dismissed` で案内を抑制可能
- `UPDATE.agent.md`, `SETUP.agent.md`, `DO_NOT_EDIT.md`, `docs/UPDATE.md` に新しい仕組み（`/core-update`・自動チェック・`checksums` 検証・Git hooks）の記載を追加
- v0.0.1 からの移行手順書 `docs/UPGRADE-0.0.1-to-0.0.2.md`（AI に渡すプロンプト付き。v0.0.1 には updater が無いため、この移行のみ手動手順）

### Changed

- **`jq` 依存を削除**。`core/updater/lib/json.sh`（純 bash/awk）で JSON 読み書きを代替。macOS 標準環境（bash 3.2）で動作
- **ZIP 展開を `unzip` → `tar` フォールバック付きに変更**。`unzip` が無くても `tar`（macOS bsdtar・Windows 10 tar 含む）があれば動作
- `apply-update.sh` の依存ツールチェックから `jq` を削除
- `core/updater/README.md` の依存ツール表示を更新（bash 3.2+ / `jq` 不要 / `unzip` または `tar`）

### Windows 対応（プレリリース）

- Windows は [Git for Windows](https://git-scm.com/download/win) の **Git Bash** 上で動作することを `README.md`・`docs/UPDATE.md`・`SETUP.agent.md` に明記
- `integrity.yml` CI を `ubuntu-latest` / `macos-latest` / `windows-latest` の3プラットフォームに拡張
- すべての CI で `jq` インストールを廃止し、`core/updater/lib/json.sh` を使用

### 今後の拡張（未実装）

- PowerShell 向けネイティブ実装（`core/updater/` のポート）。現状は Git Bash 経由で Windows 利用可能
- GPG 署名による配布元検証
- 専用 build による固定ファイル構成（Source code (zip) 以外）
- SELF_HEAL と apply-update.sh の自動連携

## [0.0.1] - 2026-05-31

### Added

- AgentBase の初期リリース
- `core/rules/AI_AGENT_CORE_RULE.md`（出力側・入力側のセキュリティ、プロンプトインジェクション対策を含む）
- `core/rules/AI_AGENT_RULE_HIERARCHY.md`
- `core/rules/AI_WORKSPACE_DESIGN.md`
- `core/runtime/AGENTS.md`（AI エージェント共通の実行ルール。信頼できない入力ソースの取り扱いを含む）
- `core/templates/` 7 ファイル
  - `company-rule-template.md`
  - `team-rule-template.md`
  - `client-rule-template.md`
  - `project-rule-template.md`
  - `personal-rule-template.md`
  - `workspace-index-template.md`
  - `rule-change-proposal-template.md`
- `core/agent-instructions/` 6 ファイル
  - `INTRODUCE.agent.md`
  - `SETUP.agent.md`
  - `UPDATE.agent.md`
  - `SELF_HEAL.agent.md`
  - `AUTOSYNC.agent.md`
  - `CUSTOMIZE.agent.md`
- `core/DO_NOT_EDIT.md`
- `core/.agent-base-lock.json`（セットアップ時に AI が生成する lock のプレースホルダ）
- ワークスペース骨格
  - `rules/`
  - `_inbox/`
  - `_misc/`
  - `work/`
  - `presentation/`
  - `modules/`
- AI ツール向け入口
  - `AGENTS.md`
  - `CLAUDE.md`
  - `.cursor/rules/agent-base.mdc`
  - `.github/copilot-instructions.md`
  - `GEMINI.md`
  - `.windsurfrules`
  - `.agents/rules/agent-base.md`
  - `.agent/rules/agent-base.md`
- `docs/RULE_LAYERS.md`
- `docs/UPDATE.md`
- `docs/SELF_HEAL.md`
- `workspace-index.md`
- `VERSION` (0.0.1)
- `LICENSE` (MIT)
- `README.md`
- `CHANGELOG.md`
- `.gitignore`, `.gitattributes`

### Notes

- v0.0.1 は 0.x 系の最初のベータです。v1.0.0 に到達するまでは破壊的変更が入る可能性があります（冒頭「ベータ方針」を参照）。
- AgentBase 本体のバージョンは `VERSION` で一元管理します。Core Rule や Runtime など個別ファイルごとのバージョンは持ちません。
- 特定組織固有のルールは AgentBase 本体には含まれません。Instance 側で管理してください。
- 配布物の zip は GitHub Release が自動生成する `Source code (zip)` を利用します。専用 build script は持ちません。
- 展開後フォルダ名がバージョン付きになるため、README では任意のワークスペース名へのリネームを案内します。
