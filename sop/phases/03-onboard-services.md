# 阶段 3 · 批量孵化服务（1–2 天）

从服务清单一次性生成：service-map、记忆卡、各服务仓库脚手架，并让每个服务仓库
**本地引入 hub**（pull 模型）。执行入口：`/onboard-services` skill。

## 输入
- 阶段 2 的 `services.manifest.yaml` 已人审。

## 步骤
1. **校验清单**（失败即停）：与 `hub.config.yaml` 项目一致、服务名唯一、依赖无环。
2. **生成 [`service-map.md`](../../architecture/service-map.md)**：每服务一段机器可读块 + Mermaid 依赖图。
3. **批量建记忆卡**：`memory/now/services/<svc>.md`（用 [`_TEMPLATE.md`](../../memory/now/services/_TEMPLATE.md)）。
4. **人审合并**（守门点）：service-map + 记忆卡作为一个 PR——这是服务拓扑的正式确认点。
5. **批量实例化服务仓库**：每个服务用 [`templates/service-repo/`](../../templates/service-repo)
   建仓（替换占位符），与 hub **克隆在同级目录**：
   ```
   <workspace-root>/
     grc-spec-hub/      ← 本 hub
     svc-order/         ← 服务仓库（同级）
     svc-billing/
   ```
6. **接通 hub（pull 模型）**：在每个服务仓库运行 hub 的
   [`scripts/link-hub`](../../scripts/README.md)，生成各 AI 工具的指针
   （skills 发现、入口指令中的 hub 路径）。
7. **冒烟**：挑 1–2 个入口服务，在"服务仓库 + hub"双目录工作区里跑一个最小任务，
   验证 agent 能读到宪法/记忆卡/契约。

## 产出
- service-map、全部记忆卡、全部服务仓库（已 link hub）。

## 出口判据
- [ ] manifest ↔ service-map 一致（数量、依赖方向）
- [ ] 每个服务有：记忆卡、仓库、已通过 link-hub 校验
- [ ] 冒烟服务的 agent 能直接读取 hub 事实源

> 后续单个新增服务用 `/new-service`（记得回填 manifest）；本阶段是一次性批量动作。
