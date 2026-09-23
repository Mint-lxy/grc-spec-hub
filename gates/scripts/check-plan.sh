#!/usr/bin/env bash
# check-plan.sh — spec 门禁（本地版）：校验 plan.md 含「涉及服务」「契约影响」两章。
# 在 hub 根目录运行: ./gates/scripts/check-plan.sh [spec-dir]
# 不带参数时检查所有 specs/*/plan.md。行为需与 check-plan.ps1 保持同步。
set -uo pipefail

FAILED=0
if [ $# -ge 1 ]; then
  PLANS="$1/plan.md"
  [ -f "$PLANS" ] || { echo "✗ 找不到 $PLANS" >&2; exit 1; }
else
  PLANS=$(find specs -name plan.md -type f)
fi

for p in $PLANS; do
  for section in "涉及服务" "契约影响"; do
    if ! grep -qE "^#{1,3}[[:space:]]*.*$section" "$p"; then
      echo "✗ $p 缺少「$section」章节"
      FAILED=1
    fi
  done
  if grep -q '\[待确认\]' "$p"; then
    echo "⚠ $p 仍含 [待确认]，进入实现前需清零"
  fi
done

if [ "$FAILED" -ne 0 ]; then printf '\nspec 门禁：未通过（plan 模板两章缺失）。\n' >&2; exit 1; fi
printf '\nspec 门禁：通过。\n'
