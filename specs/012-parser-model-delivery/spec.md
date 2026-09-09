# Feature Specification: Parser 模型制品交付

**Feature Branch**: `012-parser-model-delivery`

**Created**: 2026-09-09

**Status**: Implemented

**Input**: 将 AWS EC2 上已下载的 Docling、MinerU 和 OFA 模型去重、固化并传输到
Azure 中国云，使后续 `grc-parser-engine` Pod 通过独立持久卷只读挂载模型，而不是把
约 20–40 GiB 模型打入应用镜像。

## 背景与目标

AWS EC2 当前模型目录约 40 GiB，其中包含两套 ModelScope snapshot/cache 副本。根据
下载脚本的目标路径，实际运行所需 canonical 目录约 20 GiB：

- Docling：约 4 GiB。
- MinerU：约 15 GiB。
- OFA image caption：约 1.9 GiB。

`grc-parser-engine:0.1.0` 应用镜像约 6.9 GiB，但 `/app/.models` 为空。将全部模型打入
应用镜像会导致应用迭代、镜像拉取和多副本启动成本过高。

原计划通过 Azure Blob 中转，但实际验证显示：

- Blob Storage `defaultAction=Deny`。
- EC2 和本机访问均被网络规则拒绝。
- 当前 Application Contributor 角色不能修改 Storage 网络规则。

因此开发环境采用无需平台网络变更的交付方式：

1. 将 canonical 模型拆成 Docling、MinerU、OFA 三个独立初始化镜像。
2. 通过现有 EC2 Docker/Azure CLI 推送到项目 ACR。
3. 在 AKS 创建 128 GiB Premium SSD 模型 PVC。
4. 使用一次性 Model Loader Job 将三个镜像内容复制到版本化目录并校验 SHA256。
5. 后续 parser Pod 将该 PVC 只读挂载到 `/app/.models/parser`。

模型初始化镜像仅用于填充 PVC，不作为 parser 应用运行镜像。

## User Scenarios & Testing

### User Story 1 - 模型可被完整交付到 AKS (Priority: P1)

运维人员能从 EC2 将固定版本模型推送到 ACR，并通过一次性 Job写入 AKS 模型 PVC，
且目标文件与源文件逐项一致。

**Why this priority**: parser 应用镜像不包含模型；模型 PVC 未准备完成前，parser 无法
启动或解析真实文档。

**Independent Test**: 从 EC2 canonical 目录生成文件清单和 SHA256，在 AKS Model
Loader Job完成后重新计算目标清单，断言文件数量、相对路径、大小和 SHA256 全部一致。

**Acceptance Scenarios**:

1. **Given** EC2 原始模型目录不变, **When** 创建 canonical staging,
   **Then** staging 仅包含 approved target 路径，不包含重复 ModelScope cache。
2. **Given** 三个模型镜像已推送 ACR, **When** Model Loader Job运行,
   **Then** 模型被写入 PVC 的唯一 bundle 目录且 Job 成功退出。
3. **Given** PVC 已填充, **When** 目标端执行清单校验,
   **Then** 所有文件路径、大小和 SHA256 与源 manifest 一致。

---

### User Story 2 - Parser 可只读使用共享模型 (Priority: P1)

同一 GPU 节点上的 parser Pod 可以只读挂载模型 PVC，并通过本地模型检查与 warmup，
而不会在运行时下载模型。

**Why this priority**: 交付模型的最终价值是 parser 能离线启动并使用 Docling、MinerU、
OFA；仅传文件不足以证明可用。

**Independent Test**: 使用 parser 镜像创建一次性验证 Pod，将 bundle 目录只读挂载为
`/app/.models/parser`，设置本地模型强制开关，执行模型校验和 Docling/MinerU/OFA
warmup，断言无网络下载且退出码为 0。

**Acceptance Scenarios**:

1. **Given** 模型 PVC 校验成功, **When** parser 验证 Pod启动,
   **Then** `/app/.models/parser` 为只读挂载，所有必需目录存在。
2. **Given** 禁止运行时下载, **When** 执行 parser 模型预检,
   **Then** Docling、MinerU 和 OFA 均从本地目录加载。
3. **Given** 多个 parser Pod位于同一 `gpupool` 节点,
   **When** 同时挂载同一 RWO PVC,
   **Then** Pod可共享只读模型且不会写入模型目录。

---

### User Story 3 - 模型版本可追溯、可切换 (Priority: P2)

运维人员能够识别当前 bundle 版本，加载新 bundle 后切换 parser 配置，并在失败时回到
上一 bundle，而不破坏旧模型。

**Why this priority**: 模型变化频率低，但必须能够审计来源、升级并回滚，不能覆盖唯一副本。

**Independent Test**: 在 PVC 创建两个测试 bundle 目录，将 parser 验证 Pod分别指向
两个 bundle；失败 bundle 不更新 active metadata，旧 bundle 继续可用。

**Acceptance Scenarios**:

1. **Given** bundle 已加载, **When** 查看 bundle metadata,
   **Then** 能看到 bundle ID、来源、创建时间、总大小和 manifest SHA256。
2. **Given** 新 bundle 校验失败, **When** Job退出,
   **Then** 旧 bundle 保持不变，不产生成功形态的 active 标记。
3. **Given** 新 bundle 验证通过, **When** parser 配置切换到新 bundle,
   **Then** 可重新 warmup；回滚只需恢复旧 bundle 路径。

---

### User Story 4 - 失败可诊断、清理受控 (Priority: P2)

模型上传、镜像拉取、PVC 写入或校验失败时有明确错误；旧 bundle 与 PVC 只能通过独立、
显式确认的流程清理。

**Why this priority**: 模型体积大且重新传输耗时，错误清理可能导致 parser 长时间不可用。

**Independent Test**: 使用错误 SHA256 运行 loader，确认 Job失败且保留诊断信息；运行
清理 dry-run列出候选目录，未提供精确 bundle ID 时拒绝删除。

**Acceptance Scenarios**:

1. **Given** ACR 镜像或文件校验失败, **When** Job执行,
   **Then** Job非零退出并保留日志，不更新 bundle 完成标记。
2. **Given** 需要清理旧 bundle, **When** 未输入精确 bundle ID,
   **Then** 清理命令拒绝执行。
3. **Given** Helm 或 parser 卸载, **When** 检查模型 PVC,
   **Then** PVC 和模型 bundle 不被自动删除。

### Edge Cases

- EC2 源目录包含新增或缺失文件时，manifest 变化必须产生新的 bundle ID。
- 模型文件名含空格、Unicode 或深层目录时，清单和复制必须保持原相对路径。
- Model Loader Job中途终止时，未完成 bundle 必须标记 incomplete，不得被 parser 使用。
- PVC 剩余空间不足时，Job必须在复制前失败，不得部分覆盖旧 bundle。
- ACR 大镜像拉取超时时必须明确失败，不得改用公网源或运行时下载。
- 同一 bundle 重复执行时应幂等，不重复复制已验证文件。
- 多个 loader Job不得并发写同一 PVC。
- 普通 Azure Disk RWO 只能跨 Pod共享于同一节点；生产多节点副本不适用本方案。

## Requirements

### Functional Requirements

- **FR-001**: 系统 MUST 保持 EC2 原始模型目录只读，不得原地删除、移动或改写文件。
- **FR-002**: canonical staging MUST 仅包含：
  - `docling/docling-project--docling-layout-heron`
  - `docling/docling-project--docling-models`
  - `docling/rapidocr`
  - `mineru`
  - `ofa-image-caption-coco-large-en`
  - `sources.json`
- **FR-003**: staging MUST NOT 包含顶层 `models/` 或 `docling/models/` 缓存副本。
- **FR-004**: 系统 MUST 为每个文件记录相对路径、字节数和 SHA256，并生成 bundle 总
  manifest SHA256。
- **FR-005**: manifest MUST 记录来源 repo ID、已知 revision、模型类别、创建时间和总大小；
  当前 revision 未固定的来源 MUST 明确标记 `unresolved`，不得伪造 revision。
- **FR-006**: Docling、MinerU、OFA MUST 分别构建独立模型初始化镜像，禁止与 parser
  应用镜像合并。
- **FR-007**: 三个模型镜像 MUST 使用固定 bundle ID/tag 推送项目 ACR，并在 AKS
  工件中按 digest引用；MUST NOT 使用 `latest`。
- **FR-008**: 模型镜像 MUST 仅包含对应 canonical 模型、manifest 和复制工具；
  MUST NOT 包含 Azure 凭据、SSH 密钥、源代码工作区或重复缓存。
- **FR-009**: 开发环境 MUST 创建一个 128 GiB、RWO、`managed-csi-premium` PVC，
  并配置保留策略。
- **FR-010**: 模型 PVC MUST 绑定到 `gpupool` 所在可用区，Model Loader 和 parser
  验证 Pod MUST 显式调度到 `gpupool` 并容忍 `sku=gpu:NoSchedule`。
- **FR-011**: Model Loader MUST 将文件写入
  `/models/bundles/<bundle-id>/parser/`，不得覆盖其他 bundle。
- **FR-012**: Model Loader MUST 在复制前检查目标可用空间，复制后校验全部 SHA256；
  仅验证成功后创建完成标记。
- **FR-013**: Model Loader MUST 幂等；已存在且 manifest 一致的完整 bundle 应跳过复制。
- **FR-014**: parser 验证 Pod MUST 将指定 bundle 只读挂载到
  `/app/.models/parser`，并设置禁止运行时下载/强制本地模型的配置。
- **FR-015**: 系统 MUST 执行 Docling、MinerU、OFA 本地模型预检和 warmup；
  任一失败不得标记交付完成。
- **FR-016**: parser 验证 Pod MUST 在无模型目录写权限的情况下成功运行。
- **FR-017**: 系统 MUST 提供 bundle 列表、manifest 校验、空间检查、加载、验证和显式
  清理 Runbook。
- **FR-018**: 普通 parser/Helm 卸载 MUST NOT 删除模型 PVC 或 bundle。
- **FR-019**: 模型清理 MUST 要求精确 Namespace、PVC 和 bundle ID 二次确认，
  MUST NOT 提供模糊匹配批量删除。
- **FR-020**: 实施完成后 MUST 更新模型镜像清单、retro 和 Project Memory。

## 非目标 / 边界

- 不部署 `grc-parser-engine` 长期运行服务。
- 除修复 Docling 本地模型目录常量与下载目标的既有漂移外，不修改 parser 业务逻辑或
  模型算法。
- 不使用 Azure Blob 中转；当前网络规则不允许自助上传。
- 不删除 EC2 原始模型或重复缓存。
- 不为生产多节点 parser 设计 RWX 存储；生产方案需独立评审。
- 不使用运行时联网下载模型。
- 不改变 GPU 节点数量、自动扩缩容或 Device Plugin。
- 不修改任何服务间契约。

## Key Entities

- **Canonical Model Set**: 去除下载缓存副本后的 Docling、MinerU、OFA 运行目录。
- **Model Manifest**: 文件级路径/大小/SHA256 和来源元数据。
- **Bundle ID**: 由 manifest SHA256 派生的不可变版本标识。
- **Model Initializer Image**: 只携带单类模型并负责复制到 PVC 的 ACR 镜像。
- **Model PVC**: 开发 AKS 中 128 GiB Premium SSD 模型盘。
- **Bundle Directory**: PVC 中版本化、不可覆盖的模型目录。

## Success Criteria

### Measurable Outcomes

- **SC-001**: canonical staging 总大小不超过 24 GiB，且不包含两个已识别缓存目录。
- **SC-002**: 三个模型初始化镜像均在 ACR 有固定 digest。
- **SC-003**: 128 GiB模型 PVC 为 Bound，使用 `managed-csi-premium`。
- **SC-004**: AKS 目标 bundle 的文件数、路径、大小和 SHA256 与 EC2 manifest 100%一致。
- **SC-005**: Model Loader 重复执行同一 bundle 时 5 分钟内幂等成功且不重复复制。
- **SC-006**: parser 验证 Pod只读挂载模型后，Docling、MinerU、OFA预检/warmup全部成功。
- **SC-007**: 模型目录在验证前后无新增或修改文件。
- **SC-008**: 任一错误 SHA256 测试导致 Job失败且旧 bundle 继续可用。
- **SC-009**: 集群无新增 CrashLoopBackOff/ImagePullBackOff，GPU 和 Milvus 保持健康。

## Assumptions

- 当前 canonical 模型约 20 GiB，128 GiB PVC提供足够更新和双版本共存空间。
- 开发环境只有一个 GPU 节点，RWO PVC可被该节点上的多个 parser Pod只读共享。
- ACR 网络和 `AcrPull` 已验证，EC2 可推送大镜像。
- `gpupool` 已配置 `sku=gpu:NoSchedule`，可分配 `nvidia.com/gpu: 1`。
- 当前 ModelScope revision 信息缺失，以文件 manifest作为本次 bundle 的不可变事实；
  后续重新下载必须显式固定 revision。
- 本功能无契约影响。

## 未决问题

无。生产多节点共享存储和模型更新治理在后续独立 spec 中处理。
