# どこでも翻訳

マウスを当てた英語・日本語を、その場で訳す Mac のアプリです。
VS Code・Chrome・Discord・メール・PDF など、どのアプリの上でも動きます。訳も文字の読み取りも、すべて Mac の中で行います。

- **本体は Releases の zip（`dokotra-日付.zip`）に入っています。**「Code → Download ZIP」には本体が入っていません
- **入れ方**：zip を展開して、フォルダの中の `スタートアップ.md` を AI（Claude Code / Codex）に読ませるだけ
- **要る物**：Apple Silicon（M1 以降）の Mac・macOS 26.4 以上
- **使い方**：英語にマウスを当てて option＋control＋Y。詳しくは [kit/説明書.md](kit/説明書.md)（zip の中の 説明書.html と同じ）

## このリポジトリの中身

| 場所 | 中身 |
|:--|:--|
| `kit/スタートアップ.md` | AI に読ませるセットアップの手順（zip にも入っている） |
| `kit/説明書.md`・`kit/説明書.html` | 使い方・困った時・消し方 |
| `kit/install.sh`・`kit/check.sh` | 入れる・点検する（zip の中で使う） |
| Releases | 本体（`どこでも翻訳.app`）入りの zip |
