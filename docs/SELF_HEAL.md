# 自己修復の仕組み（SELF_HEAL）

`core/` が誤って編集された場合、hash 照合で検出し、復元できます。

## 仕組み

1. セットアップ時に AI が `core/.agent-base-lock.json` を生成
2. `managed_file_hashes` に `core/` 配下各ファイルの sha256 を記録
3. 「健康診断して」で現ファイルと照合
4. 不一致があれば修復オプションを提示

## 修復オプション

| 選択 | 内容 |
|---|---|
| 復元 | Releases から元バージョンを取得して上書き |
| 退避 | 改変内容を `rules/` へ移し、`core/` を復元 |
| 一時許可 | 今回はそのまま（次回も警告） |

## root 雛形について

`AGENTS.md` などルート雛形の改変は **警告レベル** です（利用者所有のため）。
更新時にマージが必要になる可能性がある旨を案内します。

## 依頼方法

AI に **「健康診断して」** と依頼する。

手順の詳細: `core/agent-instructions/SELF_HEAL.agent.md`

## 予防

- `core/DO_NOT_EDIT.md` を読む
- カスタムは `rules/` に書く（`core/agent-instructions/CUSTOMIZE.agent.md`）
