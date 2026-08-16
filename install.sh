#!/usr/bin/env bash
# 把 Claude Code 四角色 Agents 工作流装到一个项目,或装到全机器。
#
#   ./install.sh ~/我的项目      装到一个项目
#   ./install.sh --global        装到 ~/.claude(全机器生效)
#   ./install.sh ~/我的项目 --force   允许覆盖已存在的 CLAUDE.md

set -euo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

GLOBAL=0
FORCE=0
TARGET=""

for arg in "$@"; do
  case "$arg" in
    --global) GLOBAL=1 ;;
    --force)  FORCE=1 ;;
    -*)       echo "未知参数: $arg" >&2; exit 1 ;;
    *)        TARGET="$arg" ;;
  esac
done

usage() {
  cat <<'EOF'

用法:
  ./install.sh <项目根目录>    装到一个项目
  ./install.sh --global        装到 ~/.claude(全机器生效)
  加 --force 允许覆盖已存在的 CLAUDE.md

EOF
  exit 1
}

if [ "$GLOBAL" -eq 0 ] && [ -z "$TARGET" ]; then usage; fi

if [ "$GLOBAL" -eq 1 ]; then
  CLAUDE_DIR="$HOME/.claude"
  AGENTS_DIR="$CLAUDE_DIR/agents"
  MD_PATH="$CLAUDE_DIR/CLAUDE.md"
  SCOPE="全机器 ($CLAUDE_DIR)"
else
  [ -d "$TARGET" ] || { echo "ERROR: 目标目录不存在: $TARGET" >&2; exit 1; }
  TARGET="$(cd "$TARGET" && pwd)"
  [ "$TARGET" != "$SRC" ] || { echo "ERROR: 目标目录就是本仓库,换一个真实的项目目录" >&2; exit 1; }
  AGENTS_DIR="$TARGET/.claude/agents"
  MD_PATH="$TARGET/CLAUDE.md"
  SCOPE="项目 ($TARGET)"
fi

echo
echo "安装范围: $SCOPE"
echo

# --- agents ---
mkdir -p "$AGENTS_DIR"
shopt -s nullglob
agents=("$SRC"/agents/*.md)
[ "${#agents[@]}" -gt 0 ] || { echo "ERROR: 本仓库的 agents/ 目录里没有 .md 文件" >&2; exit 1; }

for f in "${agents[@]}"; do
  cp -f "$f" "$AGENTS_DIR/"
  echo "  OK   .claude/agents/$(basename "$f")"
done

# --- CLAUDE.md ---
[ -f "$SRC/CLAUDE.md" ] || { echo "ERROR: 本仓库缺少 CLAUDE.md" >&2; exit 1; }

if [ -f "$MD_PATH" ] && [ "$FORCE" -eq 0 ]; then
  SIDECAR="$(dirname "$MD_PATH")/CLAUDE.agents-workflow.md"
  cp -f "$SRC/CLAUDE.md" "$SIDECAR"
  echo "  SKIP CLAUDE.md 已存在,没有覆盖"
  echo "       新内容写到了: $SIDECAR"
  echo "       请自己合并,或重跑加 --force 覆盖"
else
  cp -f "$SRC/CLAUDE.md" "$MD_PATH"
  echo "  OK   $(basename "$MD_PATH")"
fi

cat <<'EOF'

装完了。还差两步:

  1. 重开编辑器窗口 —— .claude/agents/ 只在启动时扫一次,不重开等于没装
  2. 新会话里问一句「现在有哪些 subagent 可用?」
     看到 auditor / implementer / scout 三个才算真的生效

  可选:打开 .claude/agents/auditor.md,把本项目「长得像 BUG 其实是刻意设计」
        的地方填进底部的 PROJECT-SPECIFIC TRAPS 注释里。

EOF
