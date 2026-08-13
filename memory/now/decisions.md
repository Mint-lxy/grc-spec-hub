# 现行有效决策（摘要）

> 每条一行，指向权威 ADR。被替代的决策移入 `../archive/decisions-superseded.md`。
> 新 ADR 合并时在此增补一行（宪法第五条 / PIPELINE 写入入口 ③）。

| 决策 | 摘要 | ADR | 生效日期 |
|------|------|-----|----------|
| 服务拆分 | 8 服务 + 前端架构，mgmt-service 大后端内部模块化，Python/Java 双栈分界 | [ADR-001](../../architecture/adr/001-service-split.md) | 2026-08-13 |
| 错误码统一规范 | RFC 9457 错误格式 + 按模块注册前缀 + 类别分级 + 幂等/超时约定 | [ADR-002](../../architecture/adr/002-error-codes.md) | 2026-08-13 |
