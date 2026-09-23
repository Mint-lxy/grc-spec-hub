# 评审标准

> AI 自审 → Copilot Code Review → 人审 的三段分工。

## 三段分工

1. **AI 自审（agent 提 PR 前）**
   - 自查是否符合 spec 验收标准与本 `standards/`；
   - 自查契约一致性、测试红→绿、安全基线；
   - 在 PR 描述中列出自查清单与关联 spec/issue。

2. **Copilot Code Review（自动）**
   - 对 PR 做一轮自动评审，捕捉常见缺陷与风格问题。

3. **人审（守门点）**
   - 必审四处：spec / plan / 契约 / `memory/now/`（宪法第六条）；
   - 服务仓库：coding agent 的 PR 必须由人 approve，发起人不可自批；
   - 重点核对：契约破坏性、跨服务影响、记忆条目的证据链（PR 链接）。

## 合并前检查单

- [ ] 关联 spec/issue
- [ ] 门禁全绿（lint/测试/契约/密钥扫描）
- [ ] 契约变更已获消费者确认（如适用）
- [ ] 记忆更新已随 PR 提交（spec 收尾 task）
