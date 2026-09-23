# 阶段 0 · 绑定项目（半天）

一个 hub 只服务一个平台项目。本阶段把 hub 锚定到唯一项目并建立版本基线。

## 输入
- 项目名称、组织、一句话定位。

## 步骤
1. 填 [`hub.config.yaml`](../../hub.config.yaml)：`project.id / name / org / description`、`hub.repo`（清掉 `[待确认]`）。
2. `git init` 并首次提交；创建远程仓库并推送（若使用远程托管）。
3. 对四个守门点路径开启合并必审（远程托管用分支保护；纯本地协作则写入团队评审约定）：
   `specs/**`、`contracts/**`、`memory/now/**`、`.specify/memory/constitution.md`。

## 产出
- 落实的 `hub.config.yaml`；git 基线；守门点保护生效。

## 出口判据
- [ ] `hub.config.yaml` 无 `[待确认]`，`scope.single_project: true`
- [ ] 仓库有远程或明确的协作基线
- [ ] 四个守门点路径的人审机制已生效
