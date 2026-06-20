#!/usr/bin/env bash
# codex-image.sh — 用 Codex 订阅的内置 $imagegen 工具生成图片。
#   纯靠本地 codex CLI(读 ~/.codex 的登录态),不需要 OpenAI API key,也不需要 Open Design。
#   机制照搬自 Open Design 的 renderCodexImage:codex exec 里发一条以 "$imagegen " 开头的
#   prompt,codex 用订阅额度生成图,落在 ~/.codex/generated_images/<thread_id>/ig_*.png,
#   本脚本解析出 thread_id、找到 ig_ 图、拷到你指定的输出路径。
#
# 用法:
#   codex-image.sh "<prompt>" <输出路径> [aspect=1:1] [参考图路径(做图生图/编辑)]
# 例:
#   codex-image.sh "a silver mechanical keycap with a glowing starburst, dark bg" out.png 16:9
#
# 环境变量(可选):
#   CODEX_BIN            codex 可执行文件路径(默认自动探测)
#   CODEX_HOME           codex 数据目录(默认 ~/.codex)
#   CODEX_IMAGEGEN_MODEL 编排模型(默认 gpt-5.5)
set -euo pipefail

PROMPT="${1:-}"
OUT="${2:-}"
ASPECT="${3:-1:1}"
REF="${4:-}"

if [ -z "$PROMPT" ] || [ -z "$OUT" ]; then
  echo "usage: codex-image.sh \"<prompt>\" <output-path> [aspect=1:1] [reference-image]" >&2
  exit 2
fi

# --- 定位 codex CLI ---
CODEX="${CODEX_BIN:-}"
if [ -z "$CODEX" ]; then
  if command -v codex >/dev/null 2>&1; then CODEX="$(command -v codex)"
  elif [ -x "/Applications/Codex.app/Contents/Resources/codex" ]; then CODEX="/Applications/Codex.app/Contents/Resources/codex"
  elif [ -x "$HOME/.local/bin/codex" ]; then CODEX="$HOME/.local/bin/codex"
  else
    echo "! 找不到 codex CLI。请先安装 Codex 并登录(codex login),或设置 CODEX_BIN。" >&2
    exit 3
  fi
fi

ROOT="${CODEX_HOME:-$HOME/.codex}/generated_images"
mkdir -p "$ROOT"
MODEL="${CODEX_IMAGEGEN_MODEL:-gpt-5.5}"
SCRATCH="$(mktemp -d)"
trap 'rm -rf "$SCRATCH"' EXIT

# --- 组 prompt:有参考图走"编辑"前缀,否则普通生成;末尾附 Aspect ratio ---
if [ -n "$REF" ]; then
  [ -f "$REF" ] || { echo "! 参考图不存在: $REF" >&2; exit 2; }
  REF_ABS="$(cd "$(dirname "$REF")" && pwd)/$(basename "$REF")"
  MSG="\$imagegen Edit the attached reference image: ${PROMPT}"$'\n'"Aspect ratio: ${ASPECT}."
  REFARGS=(-i "$REF_ABS")
else
  MSG="\$imagegen ${PROMPT}"$'\n'"Aspect ratio: ${ASPECT}."
  REFARGS=()
fi

# --- 跑 codex exec(非交互、workspace-write 沙箱、允许联网、放开 generated_images 写权限) ---
# win32 需要 danger-full-access 沙箱(本脚本面向 macOS/Linux,未处理)。
if ! OUTJSON="$(printf '%s' "$MSG" | "$CODEX" exec --json --skip-git-repo-check \
      --sandbox workspace-write -c sandbox_workspace_write.network_access=true \
      -c 'default_permissions=":workspace"' -C "$SCRATCH" --add-dir "$ROOT" \
      --model "$MODEL" ${REFARGS[@]+"${REFARGS[@]}"} 2>"$SCRATCH/err.txt")"; then
  echo "! codex 生成失败:" >&2
  tail -c 800 "$SCRATCH/err.txt" >&2
  exit 4
fi

# --- 从 JSONL 输出里解析 thread.started 的 thread_id ---
TID="$(printf '%s' "$OUTJSON" | python3 -c "import sys,json
t=''
for line in sys.stdin:
    line=line.strip()
    if not line: continue
    try:
        o=json.loads(line)
        if o.get('type')=='thread.started' and o.get('thread_id'):
            t=o['thread_id']
    except Exception:
        pass
print(t)")"

if [ -z "$TID" ]; then
  echo "! codex 没有返回 thread_id(输出尾部):" >&2
  printf '%s\n' "$OUTJSON" | tail -5 >&2
  exit 5
fi

# --- 在 thread 目录里找 ig_* 图,拷到输出路径 ---
IMG=""
for ext in png jpg jpeg webp; do
  for f in "$ROOT/$TID"/ig_*."$ext"; do
    [ -e "$f" ] && { IMG="$f"; break 2; }
  done
done
if [ -z "$IMG" ]; then
  echo "! 未在 $ROOT/$TID 找到 ig_* 图片" >&2
  exit 6
fi

mkdir -p "$(dirname "$OUT")"
cp "$IMG" "$OUT"
echo "$OUT"
