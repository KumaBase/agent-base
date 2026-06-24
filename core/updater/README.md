# core/updater/

AgentBase の自動アップデート機能本体。Claude Code の Slash Command `/core-update` やセッション開始時の自動チェックから呼び出される。

## 構成

```
core/updater/
├── README.md           # このファイル
├── DO_NOT_EDIT.md      # 配布管理下である旨
├── lib/
│   ├── hash.sh         # SHA256 計算・検証
│   ├── lock.sh         # lock.json 読み書き
│   ├── github.sh       # GitHub Releases API
│   ├── policy.sh       # auto_update_policy 読み取り
│   └── root-merge.sh   # ルート雛形 3-way マージ判定
├── check-update.sh     # 更新確認
├── apply-update.sh     # ダウンロード＋検証＋差し替え＋コミット
└── self-test.sh        # lock との hash 整合性検証
```

## 公開 API

### check-update.sh

```
exit 0  = 既に最新
exit 10 = 新版あり（stdout に JSON）
exit 20 = ネットワークエラー
exit 21 = GitHub API rate limit
exit 22 = セットアップ未完了
```

新版ありの場合、stdout に以下の JSON:

```json
{
  "current": "0.0.1",
  "latest": "0.0.2",
  "tag": "v0.0.2",
  "zip_url": "https://...",
  "release_url": "https://...",
  "release_name": "...",
  "changelog": "...",
  "body": "..."
}
```

`--force` で 24h レート制限をバイパス。

### apply-update.sh

```bash
core/updater/apply-update.sh --tag vX.Y.Z [--dry-run] [--skip-snapshot]
```

手順:
1. スナップショットコミット作成（`chore: snapshot before agent-base update`）
2. GitHub から ZIP ダウンロード
3. checksums.txt で完全性検証
4. 展開
5. `core/` を差し替え
6. ルート雛形を 3-way 判定で更新
7. `lock.json` 再生成
8. 更新コミット（`chore: update agent-base to vX.Y.Z`）

`--dry-run` で変更を適用せず差分を表示。

### self-test.sh

```
exit 0 = 全一致
exit 1 = 不一致あり
exit 2 = lock 未生成
```

`--json` で JSON 出力。

## 依存ツール

- bash 3.2+（macOS 標準で動作。連想配列不使用）
- curl
- git
- shasum (macOS) / sha256sum (Linux)
- unzip **または** tar（ZIP 展開。macOS bsdtar / Windows 10 tar でも可）

## auto_update_policy

優先順位:
1. `rules/personal/*_PERSONAL_RULE.md` の `auto_update_policy: auto|ask|manual|compact`
2. `.claude/settings.json` の `auto_update_policy`
3. デフォルト `auto`

| 値 | セッション開始時 |
|---|---|
| `auto` | 新版あれば AI が案内 |
| `ask` | 新版あれば AI が確認 |
| `manual` | スキップ（`/core-update` のみ） |
| `compact` | スキップ（コンテキスト節約） |

## 利用者領域への配慮

`rules/`, `work/`, `modules/`, `_inbox/`, `_misc/` は一切触らない。
