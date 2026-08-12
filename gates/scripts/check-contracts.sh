#!/usr/bin/env bash
# check-contracts.sh — 契约门禁（本地版）：语法校验 + 破坏性变更检测。
# 在 hub 根目录运行: ./gates/scripts/check-contracts.sh [base-ref]
# 依赖（缺失则对应检查降级为警告）: npx redocly / npx @asyncapi/cli / oasdiff
# 行为需与 check-contracts.ps1 保持同步。
set -uo pipefail

BASE_REF="${1:-}"
# 未指定基准分支时自动探测（main → master）
if [ -z "$BASE_REF" ]; then
  if git rev-parse --verify --quiet main >/dev/null 2>&1; then BASE_REF=main; else BASE_REF=master; fi
fi
FAILED=0
[ -d contracts ] || { echo "✗ 请在 hub 根目录运行。" >&2; exit 1; }

# 1) OpenAPI 语法校验
OPENAPI_FILES=$(find contracts -path '*/openapi/*' \( -name '*.yaml' -o -name '*.yml' \) -type f)
if [ -n "$OPENAPI_FILES" ] && command -v npx >/dev/null; then
  for f in $OPENAPI_FILES; do
    npx --yes @redocly/cli lint "$f" --format=summary || FAILED=1
  done
elif [ -n "$OPENAPI_FILES" ]; then
  echo "⚠ 缺 npx/redocly，跳过 OpenAPI 语法校验"
fi

# 2) AsyncAPI 语法校验
ASYNCAPI_FILES=$(find contracts \( -name '*.asyncapi.yaml' -o -name '*.asyncapi.yml' \) -type f)
if [ -n "$ASYNCAPI_FILES" ] && command -v npx >/dev/null; then
  for f in $ASYNCAPI_FILES; do
    npx --yes @asyncapi/cli validate "$f" || FAILED=1
  done
elif [ -n "$ASYNCAPI_FILES" ]; then
  echo "⚠ 缺 npx/@asyncapi/cli，跳过 AsyncAPI 语法校验"
fi

# 3) 破坏性变更检测（对比 BASE_REF 上的旧版本）
if command -v oasdiff >/dev/null; then
  CHANGED=$(git diff --name-only "$BASE_REF...HEAD" -- 'contracts/**' 2>/dev/null | grep -E 'openapi/.*\.ya?ml$' || true)
  for rel in $CHANGED; do
    OLD=$(mktemp)
    if git show "$BASE_REF:$rel" > "$OLD" 2>/dev/null && [ -s "$OLD" ]; then
      if BREAKING=$(oasdiff breaking "$OLD" "$rel") && [ -n "$BREAKING" ]; then
        echo "✗ 破坏性变更: $rel"
        echo "$BREAKING"
        echo "  → 按 contracts/POLICY.md 处理：列出 service-map 中全部消费方并取得逐一确认。"
        FAILED=1
      fi
    fi
    rm -f "$OLD"
  done
else
  echo "⚠ 缺 oasdiff，跳过破坏性检测（安装: go install github.com/oasdiff/oasdiff@latest）"
fi

if [ "$FAILED" -ne 0 ]; then printf '\n契约门禁：未通过。\n' >&2; exit 1; fi
printf '\n契约门禁：通过（破坏性变更为零或已按 POLICY 处理）。\n'
