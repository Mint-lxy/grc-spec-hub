#!/usr/bin/env bash
# link-hub.sh — 在服务仓库根目录运行，把该仓库接到同级目录的 hub（pull 模型）。
# 用法: ../grc-spec-hub/scripts/link-hub.sh [hub-path]
# 幂等，可重复运行。行为需与 link-hub.ps1 保持同步。
set -euo pipefail

HUB_PATH="${1:-../grc-spec-hub}"
FAILED=0

ok()   { printf '✓ %s\n' "$1"; }
fail() { printf '✗ %s\n' "$1" >&2; FAILED=1; }

# 0) 必须在服务仓库根目录运行
[ -d .git ] || { echo "✗ 请在服务仓库根目录运行本脚本。" >&2; exit 1; }

# 1) 校验 hub 可达
if [ ! -f "$HUB_PATH/hub.config.yaml" ]; then
  echo "✗ 找不到 hub：'$HUB_PATH' 不存在或缺少 hub.config.yaml。" >&2
  echo "  请把 hub 与本服务仓库克隆到同一父目录。" >&2
  exit 1
fi
HUB_FULL="$(cd "$HUB_PATH" && pwd)"
ok "hub 可达: $HUB_FULL"

# 2) .claude/skills -> <hub>/capabilities/skills（symlink，幂等）
mkdir -p .claude
LINK=".claude/skills"
if [ -L "$LINK" ]; then rm "$LINK"; fi
if [ -e "$LINK" ]; then
  fail "$LINK 已存在且不是链接——请人工处理（不要把 hub 内容复制进来）。"
else
  ln -s "$HUB_FULL/capabilities/skills" "$LINK"
  ok ".claude/skills -> $HUB_FULL/capabilities/skills"
fi

# 确保 .claude/skills 被忽略（本地生成物，不入库）
if ! grep -qxF ".claude/skills" .gitignore 2>/dev/null; then
  echo ".claude/skills" >> .gitignore
  ok ".gitignore 已加入 .claude/skills"
fi

# 3) 多根工作区文件（服务仓库 + hub），已存在则不覆盖
SVC_NAME="$(basename "$PWD")"
if ! ls ./*.code-workspace >/dev/null 2>&1; then
  cat > "$SVC_NAME.code-workspace" <<EOF
{
  "folders": [
    { "path": "." },
    { "path": "$HUB_PATH" }
  ],
  "settings": {
    "chat.agentSkillsLocations": { "$HUB_PATH/capabilities/skills": true }
  }
}
EOF
  ok "已生成 $SVC_NAME.code-workspace（多根工作区：服务仓库 + hub）"
else
  ok "已存在 .code-workspace，跳过生成"
fi

# 4) 校验 AGENTS.md
if [ ! -f AGENTS.md ]; then
  fail "缺少 AGENTS.md——请从 hub 的 templates/service-repo/ 实例化。"
elif grep -qE '\{\{[A-Z_]+\}\}' AGENTS.md; then
  fail "AGENTS.md 仍含 {{...}} 占位符——孵化未完成，请替换后重跑。"
else
  ok "AGENTS.md 就绪"
fi

[ "$FAILED" -eq 0 ] || exit 1
printf '\nlink-hub 完成：本仓库已接通 hub（pull 模型）。\n'
