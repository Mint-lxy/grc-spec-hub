# AGENTS.md — {{SERVICE_NAME}}

> 面向任意 coding agent（Claude Code / Copilot / Cursor / …）的统一入口。
> 本服务属于平台项目 `{{HUB_REPO}}`，事实源在中枢仓库 hub。

## 上下文来源（pull 模型）

hub 与本仓库克隆在**同级目录**：`../{{HUB_DIR}}/`。
若不可达，先执行 `git clone <hub-repo> ../{{HUB_DIR}}`，
再在本仓库根目录运行 `../{{HUB_DIR}}/scripts/link-hub.ps1`（或 `.sh`）。

**开始任何任务前，先拉新 hub，再按序读四份文件**：

0. `git -C ../{{HUB_DIR}} pull --ff-only` —— pull 模型没有自动同步，
   读过期上下文比没有上下文更危险。
1. `../{{HUB_DIR}}/.specify/memory/constitution.md` — 项目宪法（不可协商）
2. `../{{HUB_DIR}}/memory/now/services/{{SERVICE_NAME}}.md` — 本服务记忆卡
   （可能写着"上周换了 X 库，别再用旧库"之类的关键近期变化）
3. `../{{HUB_DIR}}/contracts/` 中本服务 provides/consumes 的契约
   （清单见记忆卡与 service-map）
4. `../{{HUB_DIR}}/architecture/service-map.md` — 依赖方向与邻居

## 铁律

1. **契约先行**：跨服务交互只经 hub `contracts/` 中**已合并**的契约；
   不直连他人数据库、不隐式耦合。需要新接口 → 在 hub 走 `/contract-change` skill。
2. **测试先行**：实现前先写测试，先红后绿；禁止恒真断言
   （hub `standards/testing.md`）。
3. **Spec 可追溯**：每个 PR 引用 hub 的 `specs/NNN-<slug>`。
4. **不改 hub 事实源的守门内容**：`specs/** contracts/** memory/now/**` 与宪法
   只能经 PR 人审变更。

## 构建与测试

- 构建：`{{BUILD_CMD}}`
- 测试：`{{TEST_CMD}}`

## 门禁（合并前必须全绿）

lint · 单测 · 契约一致性（provider/consumer）· 密钥扫描 · 依赖许可证
（清单与阈值见 hub `gates/GATES.md`）。coding agent 的 PR 必须由人类 approve，发起人不可自批。

## 路径级指令

见 `.github/instructions/`（tests / api / db 各有专门约定）。
