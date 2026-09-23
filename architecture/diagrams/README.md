# diagrams/ — 独立大图

仅存放 Mermaid 表达力不够的复杂图（C4、部署拓扑等）。

规则（详见 [../README.md](../README.md) 绘图约定）：

- `<topic>.puml` 源码 + 同名 `<topic>.svg` 渲染 **成对提交**；
- 本地渲染：`plantuml -tsvg <topic>.puml`（或 VS Code PlantUML 插件导出）；
- 每张图必须被 architecture/ 或 specs/ 下某个正文文档引用，孤儿图定期清理。
