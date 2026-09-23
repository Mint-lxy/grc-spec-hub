# memory/digests — 周摘要（过程态）

每周一由人触发 `memory-digest` 管线生成 `<year>-W<nn>.md`（如 `2026-W29.md`）。
按服务分组，每服务区分：
- **事实变化**：接口/契约/schema/依赖/配置变更（精确，附 PR 链接）
- **进度变化**：哪些 spec 的哪些 task 完成（一句话）

不注入默认上下文，供 agent/人按需检索。季度末压缩进 `../archive/digests/`。
