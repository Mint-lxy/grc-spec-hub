---
name: new-service
description: "新服务孵化：从脚手架建仓（与 hub 同级目录）、登记 service-map、建记忆卡、link-hub 接通上下文。Use when: 新增/孵化一个服务仓库、把服务接入平台管线、onboard a new service、bootstrap microservice repo。"
argument-hint: "服务名与仓库，如 'svc-order (your-org/svc-order), owner @alice'"
---
# Skill: 新服务孵化

把一个新服务从零接入平台的完整步骤（pull 模型：服务仓库与 hub 同级 clone，
直读 hub 事实源，不复制副本）。

## 前置
- 该服务边界已在 `specs/000-platform` 或某个 spec 中论证过。
- 已确定服务名 `<svc>`、仓库 `owner/<repo>`、owner。

## 步骤

1. **创建服务仓库**，克隆到 **hub 的同级目录**，用 `templates/service-repo/` 脚手架实例化：
   - `AGENTS.template.md` → `AGENTS.md`；`CLAUDE.template.md` → `CLAUDE.md`
   - `copilot-instructions.template.md` → `.github/copilot-instructions.md`
   - `instructions/` → `.github/instructions/`（tests/api/db 路径级指令）
   - 替换全部占位符：`{{SERVICE_NAME}}` `{{HUB_REPO}}` `{{HUB_DIR}}` `{{BUILD_CMD}}` `{{TEST_CMD}}`

2. **link-hub 接线**：在服务仓库根目录运行
   `../<hub-dir>/scripts/link-hub.ps1`（或 `.sh`），生成 skills 链接与多根工作区，
   校验全部通过。

3. **在 hub 登记** `architecture/service-map.md`：新增一段
   ```
   ### <svc>
   - repo: owner/<repo>
   - owner: @handle
   - provides: contracts/openapi/<svc>.yaml
   - consumes: ...
   - depends-on: ...
   ```
   并更新依赖图（不得成环）；同时回填 `architecture/services.manifest.yaml`。

4. **建记忆卡**：用 `memory/now/services/_TEMPLATE.md` 生成
   `memory/now/services/<svc>.md`，填初始职责与状态。（走人审 PR。）

5. **冒烟**：用多根工作区打开服务仓库，跑一个最小任务，验证 agent 能沿
   `../<hub-dir>/` 读到宪法、记忆卡与契约。

## 完成判据
- service-map 已登记且图无环；manifest 已回填；记忆卡存在；
  link-hub 校验全部通过；冒烟任务能读到 hub 上下文。
