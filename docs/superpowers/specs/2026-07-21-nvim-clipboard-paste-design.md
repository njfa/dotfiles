# Neovim SSH 貼り付けの行単位挙動見直し

## 背景

SSH 先の Neovim では、ヤンク結果を OSC 52 でホスト側のクリップボードへ送信しつつ、貼り付け時の OSC 52 クエリによる待ち時間を避けるため、内部レジスタを clipboard provider の貼り付け元として利用している。

現在の `paste_from_register()` は、レジスタ内容とレジスタ種別を Lua の複数戻り値で返している。しかし Neovim の clipboard provider は、内容リストとレジスタ種別を 1 つのリストとして受け取る必要がある。このため `yy` の行単位種別 `V` が失われ、`p` が文字単位として処理する。

## 目的

- SSH 側で `yy` → `p` を実行したとき、ヤンクした行を改行込みの行単位で挿入する。
- コピーの OSC 52 連携を維持する。
- 貼り付け時に OSC 52 のクリップボード問い合わせを発生させない。
- WSL の `win32yank.exe` 経路の挙動を変更しない。

## 対象外

- 外部クリップボードから SSH 側 Neovim へ `p` で取得する機能の追加。
- OSC 52 の応答待ちや端末互換性の見直し。
- WSL 側の改行変換や `win32yank.exe` 設定の変更。

## 設計

SSH／非 WSL 経路の `paste_from_register()` が、次の 2 要素を持つ単一のリストを返すようにする。

1. `vim.fn.getreg(reg, 1, true)` で取得した行リスト
2. `vim.fn.getregtype(reg)` で取得したレジスタ種別

これにより、`yy` が生成する `V` を clipboard provider から Neovim の put 処理へ渡せる。文字単位・矩形単位のヤンクでも、現在のレジスタ種別をそのまま引き継ぐ。

`vim.opt.clipboard = "unnamed,unnamedplus"`、OSC 52 の copy 関数、`cache_enabled = 0` は維持する。変更は貼り付け関数の戻り値の構造と、それを検証するテストに限定する。

## エラー・境界条件

- 空レジスタや通常の文字単位レジスタは既存の `getreg()`／`getregtype()` の結果をそのまま返す。
- OSC 52 の貼り付け関数は引き続き呼び出さないため、端末が応答しない場合の待ち時間は増えない。
- WSL 経路は既存の外部コマンド provider をそのまま使用する。

## 検証

- 既存の clipboard 設定テストに、paste provider が内容と種別を単一リストで返すことを示す検査を追加する。
- Neovim 0.12 の headless 実行で、行単位レジスタを provider 経由で `p` した結果が別行として挿入される回帰ケースを確認する。
- 既存の shell テスト、Lua 構文チェック、Neovim 設定の読み込み確認を実行する。
