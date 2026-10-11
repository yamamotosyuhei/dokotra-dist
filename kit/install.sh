#!/bin/bash
# install.sh — どこでも翻訳（配布版）を、このMacで使える状態にする
#
#   bash install.sh            … 全部やる（アプリを置く・起動する・点検する）
#   bash install.sh --dry-run  … 何をするかを表示するだけ（何も変えない）
#   bash install.sh --help     … この説明
#
# 守ること: ①何度実行しても壊れない（前の版はゴミ箱へ退避してから入れ替える）
#           ②アプリは作り直さない・署名し直さない＝丸ごとコピーだけ ③rm -rf を使わない
# AI（Claude Code / Codex）が スタートアップ.md に従って実行する前提。人が直接実行しても動く。
# パスワードは聞かない（管理者の権限は要らない）。
#
# 環境変数（検証用・普段は触らない）:
#   DOKOTRA_APP_DIR=/Applications   アプリの置き場
#   DOKOTRA_TRASH=~/.Trash          前の版の退避先
#   DOKOTRA_SKIP_LAUNCH=1           起動しない
set -u
KIT="$(cd "$(dirname "$0")" && pwd)"
NAME="どこでも翻訳.app"
SRC="${KIT}/${NAME}"
APP_DIR="${DOKOTRA_APP_DIR:-/Applications}"
APP="${APP_DIR}/${NAME}"
TRASH="${DOKOTRA_TRASH:-$HOME/.Trash}"
NEED_MAJOR=26
NEED_MINOR=4
DRY=""
for a in "$@"; do
  case "$a" in
    --dry-run) DRY=1 ;;
    -h|--help) sed -n '2,7p' "$0"; exit 0 ;;
  esac
done
step(){ printf '\n▶ %s\n' "$1"; }
ok(){ printf '  ✅ %s\n' "$1"; }
warn(){ printf '  ⚠ %s\n' "$1"; }
fail(){ printf '  ❌ %s\n' "$1"; }
run(){ if [ -n "$DRY" ]; then printf '  （dry-run）%s\n' "$*"; else "$@"; fi; }
# 動いている本体を指す印。/Applications 以外（検証）では、その置き場の本体だけを指す（このMacの普段の本体を止めない）
if [ "$APP_DIR" = "/Applications" ]; then PAT="MacOS/Dokotra$"; else PAT="${APP_DIR}/.*/Contents/MacOS/Dokotra$"; fi

# 0. 前提
step "前提を確認"
if [ "$(uname -m)" != "arm64" ]; then
  fail "Apple Silicon（M1以降）のMac専用です。このMacは $(uname -m)"; exit 1
fi
V="$(sw_vers -productVersion)"
MAJ="${V%%.*}"; REST="${V#*.}"; MIN="${REST%%.*}"
[ "$REST" = "$V" ] && MIN=0
if [ "$MAJ" -lt "$NEED_MAJOR" ] || { [ "$MAJ" -eq "$NEED_MAJOR" ] && [ "$MIN" -lt "$NEED_MINOR" ]; }; then
  fail "macOS ${NEED_MAJOR}.${NEED_MINOR} 以上が要ります（このMacは ${V}）。システム設定 → 一般 → ソフトウェアアップデート で上げてから、もう一度"; exit 1
fi
if [ ! -d "$SRC" ]; then
  fail "キットの中に ${NAME} が見当たりません。GitHub の「Code → Download ZIP」には本体が入っていません。Releases の zip（dokotra-日付.zip）を落として、展開したフォルダで実行してください"; exit 1
fi
ok "Apple Silicon・macOS ${V}・キットの場所 ${KIT}"

# 1. 入れ替えのため、動いている本体を止める
step "動いている どこでも翻訳 を止める（入れ替えのため）"
if pgrep -f "$PAT" >/dev/null 2>&1; then
  run pkill -f "$PAT"
  if [ -z "$DRY" ]; then
    for i in 1 2 3 4 5 6 7 8 9 10; do pgrep -f "$PAT" >/dev/null 2>&1 || break; sleep 0.3; done
  fi
  ok "止めました"
else
  ok "動いていません"
fi

# 2. アプリを置く
step "アプリを置く（${APP}）"
if [ -d "$APP" ]; then
  OLD="${TRASH}/どこでも翻訳_前の版_$(date +%Y%m%d%H%M%S).app"
  run mkdir -p "$TRASH"
  run mv "$APP" "$OLD" || { fail "前の版をどかせませんでした（${APP}）"; exit 1; }
  ok "前の版はゴミ箱へ（${OLD##*/}）"
fi
run ditto "$SRC" "$APP" || { fail "置けませんでした（${APP_DIR} に書き込めない？）"; exit 1; }
# ネットから落とした印（quarantine）を外す。外さないと「開発元を確認できない」で開けない
run xattr -dr com.apple.quarantine "$APP" 2>/dev/null
if [ -z "$DRY" ]; then
  if codesign --verify --deep --strict "$APP" 2>/dev/null; then ok "署名OK"; else fail "署名の確認に失敗（zip が壊れているかもしれません。もう一度落としてください）"; exit 1; fi
  if xattr -p com.apple.quarantine "$APP" >/dev/null 2>&1; then fail "ネットから落とした印が外れません"; exit 1; fi
  ok "置きました（「開発元を確認できない」で止まらない状態）"
fi

# 3. 起動する（初回はアクセシビリティの許可を尋ねる画面が出る・ログイン時に起動がオンになる）
step "起動する"
if [ -n "${DOKOTRA_SKIP_LAUNCH:-}" ]; then
  warn "起動を飛ばしました（検証用）"
else
  run open "$APP"
  if [ -z "$DRY" ]; then
    for i in $(seq 1 20); do pgrep -f "$PAT" >/dev/null 2>&1 && break; sleep 0.3; done
    if pgrep -f "$PAT" >/dev/null 2>&1; then ok "起動しました（画面右上のメニューバーに「訳」）"; else fail "起動しませんでした"; fi
  fi
fi

# 4. 点検
step "点検"
if [ -n "$DRY" ]; then echo "  （dry-run）bash check.sh"; exit 0; fi
DOKOTRA_APP_DIR="$APP_DIR" bash "${KIT}/check.sh"
code=$?
printf '\n次は人の手が要ります（スタートアップ.md の §3・§4）：アクセシビリティと画面収録の許可\n'
exit $code
