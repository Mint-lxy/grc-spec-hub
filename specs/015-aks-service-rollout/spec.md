# Feature Specification: EC2 已验证版本滚动更新至 AKS

**Feature Branch**: `015-aks-service-rollout`

**Created**: 2026-09-13

**Status**: Reviewed

**Input**: 将已更新并在 EC2 环境运行的 GRC 业务服务，以可追溯、可回滚的不可变镜像方式
更新到 Azure 中国云开发 AKS，并交付可由运维人员独立执行的详细更新 Runbook。

## 背景与目标

当前 XAG AKS 已运行 Portal、Gateway、Auth、Mgmt、Knowledge、Parser，并已通过真实
上传、解析、切片、向量化和检索验收。EC2 发布分支在此后继续更新，但各仓库与 AKS
运行清单发生分叉，不能把“分支最新”直接等同于“EC2 已验证版本”。

本轮目标是建立并执行一条可重复的更新流程：

`EC2 运行版本取证 → Git commit 映射 → 测试/契约/迁移门禁 → ACR digest → AKS 分阶段更新 → E2E → 回滚`

更新不得降低 non-root、安全配置、Secret 隔离和真实演示能力。经 2026-09-13 人工裁定，
为次日客户演示可在 XAG 私网环境临时放行 Knowledge 开放接口并跳过 Gateway JWT；该例外
不得进入生产环境，且必须登记后续恢复项。

## User Scenarios & Testing

### User Story 1 - 运维识别唯一可发布版本 (Priority: P1)

运维人员能够从 EC2 运行容器、Git 和镜像元数据中确定每个服务的准确版本，而不是根据
可变 tag 或分支名称猜测。

**Independent Test**: 对每个候选服务记录 EC2 容器镜像 ID/digest、Git SHA、构建时间和
目标 ACR digest，并证明三者映射关系。

**Acceptance Scenarios**:

1. **Given** EC2 正在运行某服务，**When** 采集发布证据，**Then** 必须得到可追溯的镜像
   digest 或准确 Git SHA。
2. **Given** 运行镜像无法映射到源码，**When** 评估发布，**Then** 该服务保持原 AKS 版本，
   不得通过 `docker commit` 或猜测分支继续。
3. **Given** EC2 与 Azure 使用不同配置，**When** 复制镜像，**Then** Secret、地址和环境
   配置不进入镜像，继续由 AKS 配置注入。

### User Story 2 - 在不降低安全与契约兼容性的前提下更新服务 (Priority: P1)

开发与运维可以逐个更新服务，并在每一步通过鉴权、契约、数据库和健康检查门禁。

**Independent Test**: 对候选版本执行服务测试、契约一致性检查、镜像 smoke 和 AKS
单服务 rollout；任何门禁失败时不更新后续服务。

**Acceptance Scenarios**:

1. **Given** Gateway 新增 Knowledge 开放路由，**When** 部署到 XAG 私网演示环境，
   **Then** 可按人工裁定临时跳过 Gateway JWT；该路由不得经公网暴露，且必须保留恢复计划。
2. **Given** Mgmt 或 Knowledge 修改已发布 API，**When** 与 Hub 契约不一致，
   **Then** 必须先完成 contract-change，禁止混合版本上线。
3. **Given** Knowledge 或 Parser 需要数据库结构变化，**When** 缺少可验证迁移，
   **Then** 对应服务保持原版本。
4. **Given** 新镜像准备完成，**When** 更新 AKS，**Then** Deployment 必须引用 ACR digest，
   且上一通过 digest 可立即恢复。

### User Story 3 - 更新后保持真实演示链路 (Priority: P1)

更新后，VPN 用户仍可从 Portal 完成登录、知识库访问、文档上传、解析、向量化和检索。

**Independent Test**: 使用固定 DOCX 执行一次完整 E2E，并记录文档状态、chunks、vectors
和检索结果。

**Acceptance Scenarios**:

1. **Given** 用户通过 SAML-Azure VPN 访问，**When** 打开 `http://172.27.104.8/`，
   **Then** Portal 正常加载并调用真实 Gateway。
2. **Given** 无有效身份，**When** 调用受保护知识库接口，**Then** 仍返回未认证错误。
3. **Given** 固定文档上传成功，**When** 构建完成，**Then** 文档达到 `ACTIVE`，并存在
   可验证的切片与向量。
4. **Given** 任一关键验收失败，**When** 触发停止条件，**Then** 在 10 分钟内恢复到本轮前
   digest 集合。

### User Story 4 - 运维独立执行后续更新 (Priority: P2)

未参与本次开发的运维人员可以仅依赖 Runbook 完成版本盘点、发布、验证和回滚。

**Independent Test**: 按 Runbook 在不读取聊天记录、不获取源码仓库 Secret 的前提下，
完成一次 dry-run 和单服务回滚演练。

**Acceptance Scenarios**:

1. **Given** 新 commit 已在 EC2 验证，**When** 运维执行 Runbook，**Then** 可生成固定 tag、
   ACR digest 和发布证据。
2. **Given** 发布失败，**When** 执行 Runbook 回滚，**Then** 应用恢复且不删除数据库、
   Blob、Milvus 或模型 PVC。

## 已识别的候选版本与门禁

| 服务 | 候选版本 | 当前判定 |
|---|---|---|
| Portal | EC2 运行版本待取证；远端仓库当前不可访问 | 阻塞，保持现有 digest |
| Auth | `feature/release260831@c62dcd9` | 与当前 AKS 基线一致，无需更新 |
| Gateway | `feature/release260831@3e63ec1` | 可修复后部署：人工接受临时鉴权例外；须同步运行清单 |
| Mgmt | `feature/release260831@7fdc5a3` | 阻塞：契约漂移、授权回退、配置键变化 |
| Knowledge | `feature/release260831@843ee71` | 阻塞：缺失迁移 007、分支分叉、Docker/契约回退 |
| Parser | `feature/release260831@1b88123` | 仅允许从现有 AKS 基线集成窄范围 PNG 修复后验证 |

以上 Git SHA 仅为候选版本；在获得 EC2 运行容器证据前，不得宣称其为 EC2 实际版本。

## Requirements

### Functional Requirements

- **FR-001**: 本轮 MUST 仅更新 XAG 开发 AKS，不得创建或修改 PAG 生产资源。
- **FR-002**: 每个更新服务 MUST 记录 EC2 运行镜像、Git SHA、ACR digest 和部署时间。
- **FR-003**: 无法证明来源的运行容器 MUST NOT 通过 `docker commit` 发布。
- **FR-004**: 所有 AKS Deployment MUST 使用 ACR digest，MUST NOT 使用 `latest`。
- **FR-005**: Portal、Gateway、Auth、Mgmt、Knowledge、Parser 的 Secret 和环境配置 MUST
  与镜像分离，不得从 EC2 镜像复制凭据。
- **FR-006**: 跨服务接口 MUST 符合 Hub 已合并契约；不兼容变化必须先走 contract-change。
- **FR-007**: Gateway 的 Auth/Mgmt 受保护接口 MUST 保持未认证拒绝；Knowledge
  `/open/v1/**` 可在 XAG 私网演示环境临时跳过 Gateway JWT。该例外 MUST 记录适用环境、
  入口范围、回滚方式和后续恢复项，MUST NOT 进入生产环境。
- **FR-008**: 数据库变更 MUST 提供向前迁移、备份验证和应用回滚兼容性说明；缺少迁移时
  MUST 阻止发布。
- **FR-009**: Java/Python 镜像 MUST 保留已验收的 AKS 端口、non-root、安全上下文和
  健康检查行为，除非计划同时更新并验证清单。
- **FR-010**: Parser MUST 使用 `Recreate` 策略并保留 GPU、模型 PVC 与当前模型目录兼容性。
- **FR-011**: 每个服务更新后 MUST 独立通过 readiness、日志和 smoke，失败时停止后续 rollout。
- **FR-012**: 完整更新后 MUST 通过 VPN Portal、登录、未认证拒绝、知识库列表、固定文档构建
  和检索 E2E。
- **FR-013**: 必须保留本轮前完整 digest 集合，并演练至少一个业务服务的回滚。
- **FR-014**: 必须更新镜像清单，并在 `docs/temp/` 交付不含凭据的详细运维更新 Runbook。
- **FR-015**: Runbook MUST 包含前置条件、取证、构建/复制、扫描、发布、数据库门禁、
  分阶段 rollout、验证、停止条件、回滚、故障排查和证据模板。
- **FR-016**: 必须提供 EC2 一键 ACR 发布脚本，支持单服务和全部服务、clean worktree
  检查、可选调用既有构建流水线、运行容器 image ID 核对、不可变 commit tag、防覆盖、
  ACR digest 查询和脱敏发布记录；脚本 MUST NOT 更新 AKS。

## 非目标 / 边界

- 不更新 Milvus、etcd、MinIO、GPU 插件或 Parser 模型 bundle。
- 不把开发环境 Secret、数据库或存储复制到生产。
- 不为追求“版本最新”而跳过失败测试、契约门禁或数据库迁移。
- 不在本轮解决 Service Bus 权限、最小权限数据库账号之外的全部生产化事项。
- 不在未解决契约、配置和数据库迁移问题时发布 Mgmt/Knowledge 完整候选分支。

## Success Criteria

- **SC-001**: 六个服务均有明确的“更新/无需更新/阻塞”结论和可审计证据。
- **SC-002**: 所有实际更新服务的 ACR digest、Git SHA 和运行 Deployment 一一对应。
- **SC-003**: 更新过程没有使用 `latest`、没有提交 Secret、没有未经批准的数据库破坏性操作。
- **SC-004**: VPN Portal 与完整文档 E2E 通过，或任何失败服务已恢复至更新前 digest。
- **SC-005**: Runbook 可由运维人员独立执行，且包含本轮发现的分支分叉与契约/迁移风险。

## Assumptions

- 用户已授权更新 XAG 开发环境业务服务，但 spec、契约、服务 PR、数据库迁移和 Project Memory
  仍遵循各自的人类守门点。
- 当前环境无法直接访问 EC2；部署前需由具备权限的人员提供只读运行版本输出，或提供批准的
  SSH/SSM 访问。为满足演示时限，可将已推送的远端 release commit 作为可复现构建来源，
  但不得宣称其与 EC2 运行镜像 digest 完全一致。
- 当前 AKS digest 集合是回滚基线，直到新版本完成完整 E2E 后才可替换。

## Clarifications

### Session 2026-09-13

- Q: Gateway 新增 Knowledge 开放路由并跳过 Gateway JWT 是否阻塞演示更新？
  → A: 不阻塞。该行为是次日客户演示的临时处理决策，当前以服务正常运行和演示成功为首要
  目标；后续补齐正式鉴权。
- Q: 临时例外是否可进入生产？
  → A: 不可。仅限 XAG 私网 Internal LoadBalancer 与公司 VPN 路径，生产发布前必须恢复
  Gateway/Knowledge 的正式鉴权与 scope 校验。
- Q: 后续 EC2 代码更新如何一键同步镜像？
  → A: 在 EC2 提供 `publish-to-acr.sh`，一键完成取证、构建（可选）、tag、push 和 digest
  记录；AKS 更新继续保留人工审批。
