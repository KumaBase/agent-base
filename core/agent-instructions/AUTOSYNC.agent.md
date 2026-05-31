# AUTOSYNC.agent.md

AI エージェント向け指示書。SETUP 完了後、または利用者が **「Git 同期を設定して」** と依頼したときに参照する。

---

## 役割

ワークスペースの Git / GitHub 同期をセットアップする。auto-commit は **ask モード既定**。

## 手順

### 1. Git 状態を確認

このフォルダで `git status` が通るか確認する。

### 2. リポジトリ未初期化の場合

利用者承認後に:

1. `git init` を提案・実行
2. ルート `.gitignore` を確認（なければ AgentBase 標準を配置）
3. 初回コミットを提案（承認後）

### 3. リモート設定

1. `git remote -v` で既存リモートを確認
2. なければ「GitHub にリポジトリを作りますか」と提案
3. `gh auth status` で認証確認。必要なら `gh auth login` を案内
4. 承認後 `gh repo create`（private 推奨）

### 4. push ポリシー

**自動 push は常にオフ。** push は利用者の明示指示がある場合のみ実行する。

### 5. lock ファイル

`core/.agent-base-lock.json` は **バージョン管理対象**（`.gitignore` に含めない）。

---

## auto-commit（既定: ask）

auto-commit は既定オフ。AI は以下のシグナルを検知したら **「ここまでコミットしておきますか？」** と確認する。

- 複数ファイルにまたがる変更が論理的に完了した
- 大きな構造変更（リネーム / 移動 / 新ディレクトリ）が完了した
- セッションが長く、未コミットがたまった
- 利用者が「区切りがいい」「ここまで」「保存して」等と発した
- AgentBase 更新を取り込んだ直後

確認時の表示:

- 変更ファイルの要約
- 提案コミットメッセージ
- **はい / 後で / 今回は不要** の 3 択

利用者が **「常にお任せ」** と明示した場合のみ、以降の確認をスキップする。
設定は `rules/personal/{NAME}_PERSONAL_RULE.md` に `auto_commit_policy: ask | auto | manual` として記録（既定: `ask`）。

---

## 禁止事項

- push / force push / PR merge / Release 発行を明示承認なしに実行しない
