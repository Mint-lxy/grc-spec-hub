# Implementation Plan: Parser 模型制品交付

**Branch**: `012-parser-model-delivery` | **Date**: 2026-09-09 |
**Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `specs/012-parser-model-delivery/spec.md`

## Summary

在不修改 EC2 原模型目录的前提下：

1. 从约 40 GiB 下载目录提取约 20 GiB canonical 模型。
2. 生成文件级 SHA256 manifest，并以 manifest hash 派生 bundle ID。
3. 分别构建 Docling、MinerU、OFA 三个模型初始化镜像，推送项目 ACR。
4. 在 AKS `grc-parser` Namespace 创建 128 GiB Premium SSD PVC。
5. 运行一个包含三个顺序 initContainer 的 Model Loader Job，将模型复制到版本化 bundle。
6. 使用最终 verifier 容器执行完整 SHA256 校验，仅成功后写入 `.complete`。
7. 使用 parser 镜像只读挂载 bundle，执行本地模型检查和离线 warmup。

不使用 Blob 中转，不删除 EC2 源模型和重复缓存。实施中若真实 PDF验证发现 parser本地
模型路径与下载脚本漂移，可在测试先行前提下做最小兼容修复；正式应用镜像发布仍不在本
spec范围。

## Technical Context

**Language/Version**: Bash；PowerShell 5.1；Docker 25；Python 3.12；kubectl 1.37；
Azure CLI 2.90

**Primary Dependencies**: ModelScope 下载结果；Docker/ACR；
`managed-csi-premium` Azure Disk CSI；`grc-parser-engine:0.1.0` 验证镜像

**Storage**: 128 GiB、RWO、Premium SSD PVC；版本化 bundle 目录；Helm keep annotation

**Testing**: shell/Python manifest 单测；staging file count/size/hash；Docker image inspection；
ACR digest；Kubernetes dry-run；loader 错误 hash测试；PVC target hash；parser 本地模型检查；
Docling/MinerU/OFA warmup；只读挂载写入拒绝测试

**Target Platform**: AWS China EC2 构建节点；Azure China ACR；
AKS `XAGPMCNINFAKS001` / `gpupool` / Tesla T4

**Project Type**: 不可变模型制品供应链与 AKS 存储初始化

**Performance Goals**: canonical staging ≤24 GiB；EC2→ACR上传可断点复用 Docker layers；
AKS loader 60 分钟内完成；重复 loader 5 分钟内幂等完成

**Constraints**:

- EC2 源模型只读。
- Blob 网络规则阻塞，不能依赖 Storage allowlist。
- `gpupool` demand=1，模型 PVC 为 RWO。
- 所有 AKS 运行镜像必须来自项目 ACR并按 digest引用。
- 不在 Git、日志或镜像中包含凭据。
- ModelScope revision 当前 unresolved，以文件 manifest作为本次事实版本。

**Scale/Scope**: 三个模型镜像、一个 128 GiB PVC、一个 loader Job、一个 parser验证 Pod

## 涉及服务（Affected Services · 必填）

| 服务 | 变更性质 | 说明 |
|------|----------|------|
| grc-parser-engine | 部署制品与兼容修复 | 新增模型 bundle 构建、PVC、loader、验证和 Runbook；允许修复模型目录常量，不修改解析算法 |

## 契约影响（Contract Impact · 必填）

无契约影响。本功能只交付 parser 私有模型文件和部署存储，不改变 REST、事件或共享模型。

对应契约草案 PR：不适用。

## Constitution Check

### Spec 先行

- `specs/012-parser-model-delivery/spec.md` 已人审批准。
- plan 独立人审前不构建模型镜像、不创建 PVC。

### 契约先行

- 无跨服务契约影响。

### 测试先行

- 先建立 staging/manifest/loader 静态测试并确认工件缺失时失败。
- 再创建 bundle 工具和 Kubernetes 工件。
- 错误 SHA256 和只读写入拒绝必须作为负向行为验证。

### 服务边界

- 工件归 `grc-parser-engine/deploy/aks/models/`。
- 不新增服务依赖，不修改 service-map。

### 记忆义务

- tasks 最后一项为更新 Project Memory。
- 完成后创建 retro，更新 parser 服务卡、state 和 watchlist。

### 人类守门点

- spec 已人审。
- 本 plan 必须人审后才能 tasks/实施。
- 最终 parser 仓库和 Memory PR必须人审。

**结论**: 无宪法违反。

## Technical Design

### 1. 源模型与 canonical 目录

源目录：

```text
/home/ec2-user/parser-engine/.models/parser
```

只读提取以下路径：

```text
sources.json
docling/docling-project--docling-layout-heron/
docling/docling-project--docling-models/
docling/rapidocr/
mineru/
ofa-image-caption-coco-large-en/
```

明确排除：

```text
models/
docling/models/
```

当前容量基线：

| 分类 | 容量 |
|------|-----:|
| Docling canonical | 约 4 GiB |
| MinerU canonical | 约 15 GiB |
| OFA | 约 1.9 GiB |
| 合计 | 约 20 GiB |

staging 位于 `/data/grc-model-staging/<bundle-candidate>/parser/`，不写入源目录。

### 2. Manifest 与 bundle ID

使用 Python 工具按 UTF-8 相对路径排序，为每个文件记录：

```json
{
  "path": "parser/...",
  "size": 123,
  "sha256": "..."
}
```

顶层 metadata：

- schemaVersion
- createdAt
- sourceRoot
- source repositories/revisions
- revisionStatus（当前为 `unresolved`）
- totalFiles
- totalBytes
- components

生成：

```text
model-manifest.json
model-manifest.sha256
```

bundle ID：

```text
parser-models-<manifest sha256 前16位>
```

同一 manifest 必须产生同一 bundle ID。

### 3. 模型初始化镜像

ACR repositories：

```text
models/parser-docling:<bundle-id>
models/parser-mineru:<bundle-id>
models/parser-ofa:<bundle-id>
```

三个镜像共享一个固定基础镜像和 loader 脚本，但 payload 分离：

| 镜像 | Payload |
|------|---------|
| Docling | `parser/docling/**`、`parser/sources.json`、完整 manifest |
| MinerU | `parser/mineru/**` |
| OFA | `parser/ofa-image-caption-coco-large-en/**` |

MinerU Dockerfile按稳定子目录分多个 `COPY` 层，降低单层失败重传成本。

镜像不包含：

- 顶层或 Docling ModelScope cache。
- EC2 用户目录、Git、SSH、凭据。
- parser 应用代码。

推送后记录三个 ACR digest，Kubernetes 工件只能引用 digest。

### 4. PVC 与目录布局

Namespace：

```text
grc-parser
```

PVC：

```text
parser-models
128Gi
ReadWriteOnce
managed-csi-premium
helm.sh/resource-policy: keep
```

目录：

```text
/models/
├── bundles/
│   └── <bundle-id>/
│       ├── parser/
│       ├── model-manifest.json
│       ├── model-manifest.sha256
│       └── .complete
└── .locks/
```

不使用可变 `current` symlink。后续 parser 部署显式选择 bundle ID并将：

```text
/models/bundles/<bundle-id>/parser
```

只读挂载到：

```text
/app/.models/parser
```

### 5. Model Loader Job

Job `parser-model-loader-<bundle-short-id>` 调度到 `gpupool`，容忍
`sku=gpu:NoSchedule`，挂载 PVC为 `/target`。

执行顺序：

1. `prepare` initContainer：
   - 原子创建 lock。
   - 如 `.complete` 且 manifest一致，写 skip 状态。
   - 检查目标可用空间 ≥ bundle bytes + 10 GiB。
   - 创建新的 bundle 目录和 `.incomplete`。
2. `docling` initContainer复制 Docling。
3. `mineru` initContainer复制 MinerU。
4. `ofa` initContainer复制 OFA。
5. 主 verifier 容器：
   - 写入 manifest。
   - 逐文件校验 size/SHA256。
   - 校验文件数和总字节。
   - 删除 `.incomplete`，原子写 `.complete`。
   - 释放 lock。

每个复制容器：

- 仅写对应子目录。
- 目标已存在且 hash 一致时跳过。
- 不覆盖其他 bundle。

失败时保留 `.incomplete` 和 Job日志；parser 不得使用 incomplete bundle。

### 6. Parser 验证

使用已构建 parser 镜像，但不长期部署服务。验证 Pod：

- 调度到 `gpupool`。
- 请求 `nvidia.com/gpu: 1`。
- PVC mount 为 readOnly。
- bundle subPath挂载到 `/app/.models/parser`。
- 设置：

```text
REQUIRE_LOCAL_PARSER_MODELS=true
PARSER_MODEL_DIR=/app/.models/parser
DOCLING_MODEL_DIR=/app/.models/parser/docling
MINERU_MODEL_DIR=/app/.models/parser/mineru
LOCAL_IMAGE_MODEL_PATH=/app/.models/parser/ofa-image-caption-coco-large-en
```

执行：

1. 现有本地模型验证。
2. `scripts/warmup.py`。
3. Docling sample PDF。
4. MinerU sample PDF。
5. OFA image caption sample。
6. 尝试在模型目录创建文件，必须因只读失败。

验证期间禁止网络下载；可通过 NetworkPolicy或禁用 downloader配置实现。

### 7. 测试先行

在 `grc-parser-engine/deploy/aks/models/tests/` 先创建：

- `test_manifest.py`
- `test_staging.py`
- `validate-model-delivery.ps1`

红灯条件：

- bundle 工具/manifest/PVC/Job 不存在。

转绿断言：

- canonical allowlist和cache denylist。
- manifest deterministic。
- 路径无越界、无 symlink。
- 三个 ACR digest。
- PVC 128 GiB/Premium/keep。
- loader nodeSelector/toleration/lock/space/hash/complete。
- parser mount readOnly。
- 无公网镜像、`latest`、Secret。

### 8. 错误 manifest 测试

创建一个仅修改 manifest中单个 hash 的测试 ConfigMap/Job：

- loader/verifier 必须失败。
- `.complete` 不得产生。
- 现有已完成 bundle 不变。
- 测试 Job和错误 bundle 目录显式清理。

### 9. 幂等与共享

同一 bundle Job重复执行：

- 读取 `.complete` 和 manifest hash。
- 不重新复制 20 GiB payload。
- 5 分钟内成功退出。

开发环境多个 parser Pod可在同一 GPU 节点共享 RWO PVC只读挂载。生产多节点场景需
Azure Files Premium RWX或每节点独立模型盘，不属于本 spec。

### 10. 回滚与清理

回滚 parser 配置时只切换 bundle ID。旧 bundle不自动删除。

清理脚本必须：

1. 列出 bundle、大小、complete状态。
2. 要求输入 Namespace、PVC、完整 bundle ID。
3. 拒绝通配符和 current bundle。
4. 先 dry-run，显式 `-Execute` 才删除。
5. PVC 删除使用单独命令和额外确认。

## Project Structure

### Documentation

```text
grc-spec-hub/
└── specs/012-parser-model-delivery/
    ├── spec.md
    ├── plan.md
    ├── tasks.md
    └── retro.md
```

### Source Code

```text
grc-parser-engine/
└── deploy/aks/models/
    ├── README.md
    ├── pvc.yaml
    ├── loader-job.yaml
    ├── parser-model-validation-pod.yaml
    ├── scripts/
    │   ├── build-model-bundle.py
    │   ├── model-loader.sh
    │   └── Remove-ParserModelBundle.ps1
    ├── images/
    │   ├── Dockerfile.docling
    │   ├── Dockerfile.mineru
    │   └── Dockerfile.ofa
    └── tests/
        ├── test_manifest.py
        ├── test_staging.py
        └── validate-model-delivery.ps1

ai-portal/
└── docs/temp/
    ├── 部署服务相关任务清单.md
    └── 部署镜像清单.md
```

**Structure Decision**: 模型是 parser 私有运行制品，供应链与 AKS工件归
`grc-parser-engine/deploy/aks/models/`；大文件 staging 不进入 Git。

## Deployment Order

1. plan 人审并提交。
2. 生成 tasks并执行一致性检查。
3. 同步 parser 仓库和模型源基线。
4. 先写 manifest/staging/AKS静态测试并确认红灯。
5. 创建 staging工具，生成 canonical 目录和 manifest。
6. 运行 EC2 parser 本地挂载验证。
7. 构建并推送三个模型初始化镜像。
8. 创建 PVC和 loader工件，完成 dry-run。
9. 在 AKS 加载 bundle并全量校验。
10. 执行 parser只读挂载/warmup验证。
11. 执行错误 hash和幂等测试。
12. 更新文档、retro、Memory并创建 PR。

## Risks and Mitigations

| 风险 | 缓解措施 |
|------|----------|
| 模型来源 revision 未固定 | 明确标记 unresolved；文件级 manifest成为本 bundle事实版本 |
| 误删或污染同事源目录 | 全程只读；staging 位于 `/data` 独立目录 |
| 大镜像上传失败 | 拆为三个镜像；MinerU 拆多个稳定层；Docker layer复用 |
| PVC 空间不足 | 128 GiB；复制前检查 bundle + 10 GiB；保留双版本空间 |
| 部分复制被误用 | `.incomplete/.complete` 状态；parser 只允许完整 bundle |
| RWO 限制多节点 | 开发仅单 GPU 节点；生产独立设计 RWX或每节点盘 |
| 模型目录被容器改写 | parser 只读挂载并执行写入拒绝测试 |
| ACR 模型镜像过大 | 仅 initializer 使用；应用镜像保持独立；模型不随应用迭代重复构建 |
| 重复 cache进入镜像 | staging allowlist + denylist测试 + 容量阈值 ≤24 GiB |

## Complexity Tracking

无宪法违反。采用 ACR initializer 镜像是因为现有 Blob 网络规则阻塞且当前角色无法修改；
相比等待临时公网放行，该方案复用已验证的 ACR权限，同时保持应用和模型解耦。
