# architecture/ — 架构事实源

| 内容 | 位置 |
|------|------|
| 服务地图（依赖关系、消费方清单） | [service-map.md](service-map.md) |
| 服务声明清单（批量孵化输入） | [services.manifest.yaml](services.manifest.yaml) |
| 跨服务架构决策（ADR） | [adr/](adr/README.md) |
| 跨切面规范（认证、错误码、可观测性） | [cross-cutting/](cross-cutting) |
| 独立大图（.puml + .svg 成对） | [diagrams/](diagrams/README.md) |

## 绘图约定

原则：**图必须以文本源码存在**——可 diff、可人审、可被 agent 直读。像素图不能作为唯一事实源。

1. **Mermaid 内嵌（默认）**：图直接写在它所解释的文档里（依赖图进 service-map、
   决策示意进对应 ADR、跨切面图进 cross-cutting/*.md）。GitHub/VS Code 原生渲染，
   零工具链，图与上下文不分离。
2. **PlantUML（仅当 Mermaid 表达力不够，如复杂 C4/部署图）**：
   `diagrams/<topic>.puml` 与同名 `<topic>.svg` **成对提交**（本地 `plantuml -tsvg` 渲染），
   正文用相对链接引用两者。PR 中源码与渲染不一致视为未完成。
3. **png / draw.io / 截图**：只能作补充附件，且旁边必须有等价文本描述
   （Mermaid/puml 或文字），否则对 agent 不可读，禁止合并。
4. 图随事实更新：改依赖必改 service-map 中的图；孤儿图（正文无引用）在季度归档时清理。
