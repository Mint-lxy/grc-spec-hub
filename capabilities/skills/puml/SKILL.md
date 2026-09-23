---
name: puml
description: "生成 PlantUML (.puml) 文件并渲染为 .svg：按需求选择图型（C4 架构/组件图、类图、时序图、活动图、状态机、组件图、用例图、部署图），套用本项目 C4 主题与命名约定，输出可直接渲染的 .puml，并用随附脚本导出同名 .svg。Use when: 画架构图、画组件图、画时序图、生成/更新 .puml、导出/渲染 svg、draw diagram、C4 diagram、render svg。"
argument-hint: "图型与内容，如 'eval-service 的 C4 组件图' 或 '文档接入流程的时序图'"
---
# Skill: 生成 PUML 文件（puml）

## 铁律

1. **产出是独立 `.puml` 文件**：以 `@startuml <图名>` 开头、`@enduml` 结尾，
   **图名与文件名一致**（不要输出 markdown 代码块；只有嵌入 .md 时才用
   ` ```plantuml ` 围栏，绝不用 ` ```text `）。
2. **文件头注释块必填**：图名、事实源（由哪个 spec/代码/drawio 转换或反向生成）、
   图例说明。见 [references/c4-theme.md](references/c4-theme.md) 的骨架。
3. **只画有事实源的内容**（specs/contracts/architecture/实际代码）；
   推测的元素在描述中标 `[待确认]`，不许编造服务、接口或依赖。
4. **每个元素声明 alias**，关系只引用 alias；关系按调用方分组并加
   `' ---- xxx ----` 注释；参数列对齐，多行描述用 `\n`。
5. **C4 图必须套本项目 C4 主题**：`AddRelTag` sync/async 双线型 +
   `SHOW_LEGEND()`，详见 [references/c4-theme.md](references/c4-theme.md)。

## 图型选择

| 需求 | 图型 | 核心语法 |
|---|---|---|
| 系统全景/容器/组件架构 | **C4**（首选） | `!include <C4/C4_Container>`、`Person`/`System_Ext`/`Container`/`Component`/`Rel` → [references/c4-theme.md](references/c4-theme.md) |
| 类结构与关系 | 类图 | `class`/`interface`/`abstract`/`enum`；`<\|--` 继承、`..\|>` 实现、`*--` 组合、`o--` 聚合、`..>` 依赖；可见性 `+ # - ~` |
| 跨服务调用时序 | 时序图 | `participant`/`actor`/`database`、`box..end box` 分组；`->` 同步、`->>` 异步、`-->` 返回、`++/--` 激活；片段 `alt/opt/loop/par/break` |
| 业务/审批流程 | 活动图 | `start`/`stop`、`:动作;`、`if/else`、`fork`、泳道 `\|角色\|` |
| 对象生命周期 | 状态机 | `state`、`[*] --> 状态`、`状态 --> [*]` |
| 模块组织 | 组件/包图 | `component`、`[名称]`、`package "名"`、`interface` |
| 用户-系统交互 | 用例图 | `actor`、`usecase (名)`、`left to right direction` |
| 物理部署 | 部署图 | `node`、`artifact`、`database`、嵌套节点 |

## 步骤

1. **定图型与事实源**：按上表选型；找齐依据（spec/契约/service-map/代码），
   列出元素清单与关系清单再动笔。
2. **起骨架**：`@startuml 图名` + 头注释块 + include/主题 + `title`。
3. **填元素**：按节区组织（C4：人员 → 外部系统 → 边界内容器/组件；
   组件图按分层注释组织），每节加 `' ====` 分隔条。
4. **填关系**：按调用方分组；同源重复语义的连线标签用 `" "`（单空格）省文字；
   写明协议（HTTPS/JDBC/AMQP/gRPC…）与 sync/async 标签。
5. **校验**（完成判据）：
   - [ ] `@startuml/@enduml` 配对，图名=文件名；
   - [ ] 所有关系两端 alias 均已声明，无孤立元素；
   - [ ] C4 图有 RelTag 图例 + `SHOW_LEGEND()`；
   - [ ] 与事实源逐条核对过元素与依赖方向，推测处已标 `[待确认]`。
6. **渲染 SVG**：跑 [scripts/export-svg.ps1](scripts/export-svg.ps1) 生成同名
   `.svg` 并与 `.puml` 一起提交；脚本报 FAIL（HTTP 400）= 语法错误，
   回步骤 5 修图后重跑。见下节。

## 非 C4 图的配色

普通 UML 图用 `skinparam` 统一风格，柔和浅色系：
接口 `#d5e8d4`、抽象类 `#f8cecc`、普通类 `#dae8fc`、枚举 `#fff2cc`、
工具类 `#e1d5e7`、前端 `#96CBFE`、服务 `#A8D08D`、存储 `#F4B183`、外部 `#D5A6E6`。

## 渲染为 SVG

用 [scripts/export-svg.ps1](scripts/export-svg.ps1) 经 PlantUML server 渲染，
**本机无需 Java/GraphViz**。渲染服务器不写死：缺省自动读取 VS Code 用户
`settings.json` 的 `plantuml.server`（代理读 `http.proxy`），与编辑器预览同源：

```powershell
# 单文件（.svg 生成在源文件旁）
powershell -NoProfile -ExecutionPolicy Bypass -File <hub>/capabilities/skills/puml/scripts/export-svg.ps1 `
  -Path architecture/diagrams/foo.puml

# 整个目录批量
powershell -NoProfile -ExecutionPolicy Bypass -File <hub>/capabilities/skills/puml/scripts/export-svg.ps1 `
  -Path architecture/diagrams
```

- 参数：`-Path`（文件/通配/目录，可多个）、`-Server`/`-Proxy`（仅需覆盖
  settings.json 时才传）、`-OutDir`（默认源文件旁）。
- 未配置 `plantuml.server` 时脚本直接报错提示，先在 settings.json 配好再跑。
- 退出码非 0 = 有文件渲染失败；`FAIL ... (400)` 即 puml 语法错误，修完重跑。
- 图源码会发送至所配置的渲染服务器；架构敏感时将 `plantuml.server` 指向
  内网服务（如 `docker run -d -p 8080:8080 plantuml/plantuml-server`）。
- 人工兜底：VS Code jebbs.plantuml 同样按 `plantuml.server` 渲染，
  `Alt+D` 预览、命令面板 *PlantUML: Export Current Diagram* 导出。

## 产出位置

- 平台级架构图 → hub 的 `architecture/diagrams/`；
- 服务级组件图可放服务仓库，命名见 [references/c4-theme.md](references/c4-theme.md)；
- **`.puml` 与同名 `.svg` 成对提交**，改图必须同步重渲。
