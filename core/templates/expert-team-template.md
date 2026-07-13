# {OWNER_NAME}_EXPERT_TEAM

Date: {YYYY-MM-DD}
Layer: Company / Client / Project / Team / Personal Rule の拡張（置いた階層に従う）
Owner: {OWNER_NAME}
Status: Draft / Approved

---

## 0. 位置づけ

この文書は、バーチャル専門家チーム（`core/agent-instructions/EXPERT_TEAM.agent.md`）の役割カタログ（Core の既定セット）を {OWNER_NAME} 向けに拡張するものである。

置き場所（カスタマイズしたい階層に置く）:

- Company: `rules/company/{COMPANY}_EXPERT_TEAM.md`
- Client: `rules/clients/{CLIENT}/{CLIENT}_EXPERT_TEAM.md`
- Project: `rules/projects/{PROJECT}/{PROJECT}_EXPERT_TEAM.md`
- Team: `rules/teams/{TEAM}/{TEAM}_EXPERT_TEAM.md`
- Personal: `rules/personal/{NAME}_EXPERT_TEAM.md`

制約:

- 上位ルール（Core Rule 等）を緩和または上書きしてはならない
- 上位階層が無効化した役割を下位階層で復活させることはできない（制約は下位で強める方向のみ）
- 「会議の結論は利用者の承認を代替しない」原則はこの文書でも変更できない

---

## 1. 追加する専門家

組織・個人に固有の専門家を定義する。AI は会議の人選時にカタログへ加える。

| 役割名 | 視点・専門 | 発言の特徴 |
|---|---|---|
| {ROLE_NAME_1} | {PERSPECTIVE_1} | {STYLE_1} |
| {ROLE_NAME_2} | {PERSPECTIVE_2} | {STYLE_2} |

記入例:

| 役割名 | 視点・専門 | 発言の特徴 |
|---|---|---|
| 顧問税理士 | インボイス、節税、資金繰り | 数字の根拠を必ず求める |
| 業界メンター | {業界名} の商習慣、相場観 | 経験談ベースで現実的な落とし所を示す |

---

## 2. 既定の編成（任意）

- **default_team**: {よく使う編成。例: CEO, CFO, 現場の人, 悪魔の代弁者}
- **disabled_roles**: {編成に含めない役割。例: 占い師}

---

## 3. 議論スタイルの好み（任意）

- {例: 結論から先に。会議ログは短く}
- {例: 反対意見を最低 1 つは必ず出す}
- {例: 金額に関わる議題では CFO を必ず入れる}
