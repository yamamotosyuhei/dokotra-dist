#!/bin/bash
# check.sh — どこでも翻訳（配布版）が使える状態か点検する
#   bash check.sh   … ✅/⚠/❌ を並べる。❌ が1つでもあれば終了コード1
# 環境変数 DOKOTRA_APP_DIR は install.sh と同じ（普段は触らない）
set -u
APP_DIR="${DOKOTRA_APP_DIR:-/Applications}"
APP="${APP_DIR}/どこでも翻訳.app"
CLI="${APP}/Contents/MacOS/dokotra-cli"
NG=0
ok(){ printf '✅ %s\n' "$1"; }
wa(){ printf '⚠ %s\n' "$1"; }
ng(){ printf '❌ %s\n' "$1"; NG=1; }

if [ "$(uname -m)" = "arm64" ]; then ok "Apple Silicon"; else ng "Apple Silicon 専用（このMacは $(uname -m)）"; fi
V="$(sw_vers -productVersion)"
MAJ="${V%%.*}"; REST="${V#*.}"; MIN="${REST%%.*}"
[ "$REST" = "$V" ] && MIN=0
if [ "$MAJ" -gt 26 ] || { [ "$MAJ" -eq 26 ] && [ "$MIN" -ge 4 ]; }; then ok "macOS ${V}"; else ng "macOS 26.4 以上が要る（このMacは ${V}）"; fi
if [ ! -x "$CLI" ]; then ng "アプリが無い（${APP}）→ install.sh をもう一度"; exit 1; fi
ok "アプリ ${APP}"
if codesign --verify --deep --strict "$APP" 2>/dev/null; then ok "署名"; else ng "署名が壊れている → install.sh をもう一度"; fi
if xattr -p com.apple.quarantine "$APP" >/dev/null 2>&1; then ng "ネットから落とした印が残っている → install.sh をもう一度"; else ok "「開発元を確認できない」の印なし"; fi
if [ "$APP_DIR" = "/Applications" ]; then
  if pgrep -f "MacOS/Dokotra$" >/dev/null 2>&1; then ok "動いている（メニューバーに「訳」）"; else wa "動いていない → アプリケーションフォルダの「どこでも翻訳」を開く"; fi
fi
S="$("$CLI" status 2>/dev/null)"
if echo "$S" | grep -q '"en→ja" : "installed"' && echo "$S" | grep -q '"ja→en" : "installed"'; then
  ok "翻訳の言語データ（英→日・日→英）"
else
  ng "翻訳の言語データが無い → メニューバーの「訳」→「翻訳言語を入れる…」で「日本語」と「英語（米国）」を入れる（いま: $(echo "$S" | tr -d '\n ')）"
fi
T="$("$CLI" selftest 2>&1)"
SUM="$(echo "$T" | grep '項目中' | tail -1)"
BAD="$(echo "$T" | grep -E '^NG')"
if [ -z "$BAD" ] && [ -n "$SUM" ]; then
  ok "自己テスト ${SUM}"
elif [ -n "$BAD" ] && ! echo "$BAD" | grep -qv '内蔵辞書'; then
  wa "自己テスト ${SUM}（単語の辞書だけ未導入＝訳は使える）"
  echo "    → 単語の意味も出すには：辞書アプリ → 設定 →「ウィズダム英和辞典」「ウィズダム和英辞典」にチェック"
else
  ng "自己テスト ${SUM:-（結果が読めない）}"
  echo "$BAD" | sed 's/^/    /' | head -8
fi
U="${HOME}/Library/Application Support/Dokotra/usage.jsonl"
if [ -f "$U" ] && tail -20 "$U" | grep -q '"reason":"permission"'; then
  wa "最近「画面収録の許可が無い」で訳せなかった → システム設定 → プライバシーとセキュリティ → 画面収録 で「どこでも翻訳」をオン → メニューの「訳」→「再起動」"
fi
if [ -f "$U" ] && tail -50 "$U" | grep -q '"kind":"read'; then ok "実際に訳せた記録がある"; fi
wa "画面収録・アクセシビリティの許可は機械では確かめられない → 英語の文にマウスを当てて option＋control＋Y で小窓が出れば、全部そろっている"
exit $NG
