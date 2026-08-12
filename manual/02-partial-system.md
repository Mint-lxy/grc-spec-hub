# 手册二：部分开发的系统（有架构图 + 部分服务已实现）

> 前提：已完成 [公共准备](README.md)。
> 与全新系统的差别：阶段 1–3 从"创作"变成"**逆向登记存量 + 正向孵化增量**"。
> 核心原则：**hub 先如实记录现状，再谈改进**——改进走正常 spec 流程，不在登记时夹带。

---

## 阶段 0：绑定项目（与手册一相同）

按 [手册一·阶段 0](01-new-system.md#阶段-0把-hub-绑定到你的项目半天) 做：
填 hub.config.yaml → 推远程 → 守门点保护。

---

## 阶段 1：奠基——用存量资产反填（1–3 天）

### 1.1 宪法（照常共写）

与手册一相同。额外注意：如果存量代码里有明显违反草案宪法的做法（比如服务间直连数据库），
**不要为了迁就现状削弱宪法**——照写硬规则，把违规项记入
[memory/now/watchlist.md](../memory/now/watchlist.md) 作为已知技术债。

### 1.2 架构图 → hub 格式

你手里的架构图（draw.io/PPT/白板照片）要转成文本格式才对 agent 有用：

1. 把图发给 agent：*"把这张架构图转成 Mermaid 依赖图，并按
   architecture/service-map.md 的机器可读约定为每个服务生成一段登记块"*。
2. 人工核对生成结果（服务名、依赖方向别转错），替换
   [architecture/service-map.md](../architecture/service-map.md) 中的占位样例。
3. 原图如果还有价值，按 [绘图约定](../architecture/README.md) 存为
   `architecture/diagrams/<topic>.puml + .svg`，或直接弃用（Mermaid 已是事实源）。

### 1.3 存量设计决策 → ADR 补记

把当年拍过的重要板子（为什么选 Kafka、为什么拆这几个服务）补记成 ADR：

- 每条复制 [architecture/adr/template.md](../architecture/adr/template.md)，
  状态标 `Accepted（追溯补记）`，日期写当时的大致时间；
- 记不清依据的写 `[待确认]` @ 当事人，**不要编造理由**；
- 同时在 [memory/now/decisions.md](../memory/now/decisions.md) 各加一行摘要。

### 1.4 000-platform 反填

[specs/000-platform/](../specs/000-platform/spec.md) 按**现状**填：里程碑从"当前进度"起算，
服务划分依据写实际采用的逻辑。已实现部分在 spec 里标注"已实现"。

---

## 阶段 2：服务清单——存量与增量一起声明（半天）

填 [services.manifest.yaml](../architecture/services.manifest.yaml)，**存量服务与未实现服务都写进去**，
用 `milestone` 区分（存量的写 `M0-已实现`，未实现的写真实里程碑）。
依赖关系照实填；如果存量依赖成环——这是真实的架构问题，记 watchlist + ADR，暂不阻塞登记。

---

## 阶段 3A：存量服务接入（每个约 1 小时，不动业务代码）

对**每个已实现的服务**：

1. **搬到同级目录**（若不在）：
   ```powershell
   cd <你的工作区>
   git clone <svc 仓库地址> svc-xxx
   ```
2. **补 agent 入口文件**（从 hub 模板实例化，替换 `{{...}}` 占位符）：
   - `templates/service-repo/AGENTS.template.md` → 服务仓库 `AGENTS.md`
   - `CLAUDE.template.md` → `CLAUDE.md`；`copilot-instructions.template.md` → `.github/copilot-instructions.md`
   - `instructions/` → `.github/instructions/`
   - `{{BUILD_CMD}}`/`{{TEST_CMD}}` 填该服务**实际的**构建/测试命令
3. **接线**：在服务仓库根目录跑
   ```powershell
   ../grc-spec-hub/scripts/link-hub.ps1
   ```
   全绿即接通。以上产物提一个 PR 进服务仓库。

## 阶段 3B：契约逆向提取（最重要的一步，每服务 0.5–1 天）

存量系统最缺的就是契约。没有契约，hub 的裁判机制全部落空。

1. 在服务仓库工作区对 agent 说：
   *"读本服务对外暴露的全部接口（controller/handler/路由 + 事件发布），
   逆向生成 OpenAPI 3.1 / AsyncAPI 2.x 契约文件，不确定的字段标 [待确认]"*。
2. **以代码实际行为为准**，不以过时的接口文档为准；有文档冲突时标注出来。
3. 人工核对后放入 hub：`contracts/openapi/<svc>.yaml`、`contracts/events/<domain>.asyncapi.yaml`。
4. 跑门禁 `./gates/scripts/check-contracts.ps1`（首次只做语法校验），提 PR → 人审合并。
5. 每个服务建记忆卡：复制 [_TEMPLATE.md](../memory/now/services/_TEMPLATE.md) 为
   `memory/now/services/<svc>.md`，"已知问题"如实填（这是给 agent 的防坑指南）。

> 提取顺序建议：先做被依赖最多的服务（service-map 里入度最高的），它的契约最多人等着用。

## 阶段 3C：未实现服务正常孵化

对清单里还没实现的服务，逐个走 `/new-service`（或数量多时一次 `/onboard-services`，
它会跳过已登记的存量服务——在参数里说明哪些已存在）。

---

## 阶段 4 起：与手册一完全相同

从第一个新需求开始走 [手册一·阶段 4](01-new-system.md#阶段-4第一个-feature跑通一圈之后每个需求都这样走) 的 feature 循环。
唯一差别：**改动触及存量接口时，一律先补/改契约再动代码**（宪法第二条从此刻起生效）。

## 常见问题

- **存量代码和逆向契约对不上怎么办？** 契约以代码现状为准登记；想改成"应该的样子"→ 开一个 spec 走正常变更。
- **要不要给存量代码补测试？** 不强制回补；宪法第三条只约束**新变更**。关键路径缺测试记 watchlist。
- **一部分服务还在别人手里/另一个团队？** 照常登记 service-map（owner 写清楚），契约由对方确认后合并；他们的仓库可以暂不接 link-hub。
