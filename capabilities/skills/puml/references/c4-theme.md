# C4 主题约定（本项目）

提炼自根目录三张实际架构图：
`AI 基础平台-C4架构图.puml`（容器图）、`knowledge-engine-C4组件图.puml`、
`parser-engine-C4组件图.puml`（组件图）。新图保持同一风格。

## 命名约定

- 文件名：平台容器图 `<系统名>-C4架构图.puml`；服务组件图 `<svc>-C4组件图.puml`。
- `@startuml` 图名与文件名（去扩展名）一致。
- alias 用 snake_case，与服务名对应：`api_gateway`、`knowledge_engine`。

## 标准骨架

```plantuml
@startuml <svc>-C4组件图
' ============================================================
' <svc> C4 组件图 (Component Diagram)
' 由 <repo>/<path> 实际代码反向生成        ← 写明事实源
' 架构风格: 六边形架构 (Ports & Adapters)   ← 如适用
' 图例: 实线 = 同步调用 (Sync) ; 虚线 = 异步/外部 (Async/Ext)
' ============================================================
!include <C4/C4_Component>
' 容器图改用: !include <C4/C4_Container>
' 本地无 stdlib 时可改在线引用:
' !include https://raw.githubusercontent.com/plantuml-stdlib/C4-PlantUML/master/C4_Component.puml

title <svc> C4 组件图 (Component Diagram) — <一句话定位>

' ---- 连线样式: 全项目统一双线型 ----
AddRelTag("sync",  $lineStyle=SolidLine(),  $legendText="同步调用 (Sync)")
AddRelTag("async", $lineStyle=DashedLine(), $legendText="异步/外部 (Async/Ext)")

' ============================================================
' 上游调用方与外部系统（容器图则为: 人员 → 外部系统）
' ============================================================
Container(api_gateway, "api-gateway", "JAVA Application", "统一 API 网关\n路由 · 限流 · 鉴权转发")
System_Ext(nexus, "Nexus / AI Gateway", "Embedding / LLM API")
ContainerDb(postgres, "PostgreSQL", "Azure Database", "关键表清单\n用 \n 分行罗列")
ContainerQueue(servicebus, "Azure Service Bus", "Message Broker", "Topic: xxx\nSubscription: xxx")

' ============================================================
' <svc> 容器边界（组件按分层组织，每层加 ' ---- 层名 ---- 注释）
' ============================================================
Container_Boundary(svc, "<svc> (Python / FastAPI)") {
    ' ---- API 层 ----
    Component(xx_api, "Xxx API", "FastAPI Router", "POST /xxx\n职责说明")
    ' ---- 应用层 ----
    ' ---- 领域层 (Ports) ----
    ' ---- 适配器层 ----
    ' ---- 基础设施层 ----
    ' ---- Core 横切 ----
}

' ============================================================
' 关系 (Relationships)  — 按调用方分组，每组加 ' ---- 组名 ----
' ============================================================
' ---- 入口 ----
Rel(api_gateway, xx_api, "REST", "JSON/HTTPS", $tags="sync")
' 同源同语义的并列连线，标签用 " " 省重复文字:
' Rel(api_gateway, yy_api, " ", $tags="sync")

SHOW_LEGEND()
@enduml
```

## 元素选型

| 元素 | 宏 | 用途（本项目实例） |
|---|---|---|
| 人员 | `Person(alias, "名", "职责")` | 管理员/运营/开发人员 |
| 外部系统 | `System_Ext` | SSO、LLM 网关、GitHub、GPU、模型目录 |
| 服务/应用 | `Container(alias, "名", "Container: 技术栈", "职责\n分行")` | ai-portal、api-gateway 等 |
| 数据存储 | `ContainerDb` | PostgreSQL、Redis、Milvus、Blob、Key Vault |
| 消息队列 | `ContainerQueue` | Azure Service Bus（描述里写 topic 名） |
| 系统边界 | `System_Boundary` / `Container_Boundary` | 系统整体 / 单服务内部（可嵌套子边界） |
| 组件 | `Component(alias, "名", "技术", "职责")` | Router/Service/Port/Adapter/Repo |

## 关系写法

```plantuml
Rel(a, b, "动作说明", "协议", $tags="sync")   ' 完整形式
Rel(a, b, " ", $tags="sync")                 ' 并列省文字
BiRel(a, b, "双向语义", $tags="sync")         ' 双向读写
Rel(queue, svc, "订阅 xxx", $tags="sync")     ' 消息订阅: 队列 → 消费者
```

- `$tags="sync"`（实线）：进程内调用、REST 请求、SQL、缓存、gRPC。
- `$tags="async"`（虚线）：出边界的外部调用（LLM/SSO/GitHub）、MQ 投递、
  链路上报（Langfuse）、模型/GPU 加载。
- 协议参数按需写：`HTTPS`、`JSON/HTTP`、`JDBC`、`asyncpg`、`AMQP`、
  `gRPC`、`OAuth2/OIDC`、`MCP Protocol`、`A2A`、`streamble-http`。
- 结尾必须 `SHOW_LEGEND()`。

## 描述文字风格

- 中文为主，技术名词保留英文；多条职责用 `\n1. …\n2. …` 或 `\n` 分行。
- 并列项用 ` · ` 分隔：`路由 · 限流 · 鉴权转发`。
- API 组件描述写方法+路径：`POST /api/v1/parse`。
