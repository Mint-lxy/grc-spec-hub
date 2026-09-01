---
applyTo: "**/tests/**,**/*.test.*,**/*.spec.*"
---
# 测试路径级指令

- 遵循 hub `standards/testing.md`：禁止恒真断言，先红后绿，断言行为非实现。
- 契约相关行为必须有 provider/consumer 契约测试。
- 覆盖 happy path 与错误/边界/并发/幂等重放路径。
