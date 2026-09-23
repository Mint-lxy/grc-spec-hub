# 使用说明书（Manual）

> 目标读者：第一次用本 hub 管项目的人。不需要先读懂整个仓库——按本目录的手册照做即可。
> 原理性内容见根 [README.md](../README.md) 与 [sop/](../sop/README.md)，本目录只讲"怎么做"。

## 第一步：判断你属于哪种场景

| 你的情况 | 用哪份手册 |
|----------|-----------|
| 全新项目，一行代码没写 | [01-new-system.md](01-new-system.md) |
| 已有架构图/设计文档，实现了**部分**服务 | [02-partial-system.md](02-partial-system.md) |
| 系统**已上线运行**，想用 hub 接管后续开发 | [03-live-system.md](03-live-system.md) |

三份手册的公共准备工作都在下面，先做完再翻对应手册。

---

## 公共准备（所有场景，约 1 小时，每台机器一次）

### 1. 安装工具

| 工具 | 用途 | 安装/验证 |
|------|------|-----------|
| git | 版本控制 | `git --version` |
| VS Code + Copilot，或 Claude Code | AI coding 工具（至少一个） | — |
| Node.js ≥ 18 | 契约门禁（redocly/asyncapi CLI 经 npx 拉起） | `node -v` |
| oasdiff | 契约破坏性检测 | `go install github.com/oasdiff/oasdiff@latest` 或[下载二进制](https://github.com/oasdiff/oasdiff/releases)；验证 `oasdiff --version` |
| Spec Kit（specify CLI） | spec 工作流引擎 | `uv tool install specify-cli --from git+https://github.com/github/spec-kit.git`；验证 `specify check` |

Windows 用户额外做一次（否则跑 `.ps1` 脚本会报 `UnauthorizedAccess`）：

```powershell
Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
```

### 2. 建立工作区目录结构

hub 和所有服务仓库必须**克隆在同一个父目录下**（这叫 pull 模型，服务仓库靠
`../<hub>/` 相对路径直读 hub，不复制副本）：

```
<你的工作区>/                ← 随便哪个目录
  grc-spec-hub/             ← hub（本仓库），目录名可自定
  svc-xxx/                  ← 之后的服务仓库都放这一层
  svc-yyy/
```

```powershell
cd <你的工作区>
git clone <hub 仓库地址> grc-spec-hub
```

> 如果你是从模板复制新项目：clone 后执行
> `git checkout --orphan main; git add -A; git commit -m "chore: init hub from template"`
> 重开历史。

### 3. 认识五个最常用的入口（先混个眼熟）

| 你想做什么 | 入口 |
|-----------|------|
| 走流程不知道下一步 | [sop/README.md](../sop/README.md) 阶段状态机 |
| 起草需求/方案/任务 | `/speckit.specify` `/speckit.plan` `/speckit.tasks`（其它框架的命令见 sop/README.md 对照表） |
| 改跨服务接口 | `/contract-change` skill |
| 新增一个服务 | `/new-service` skill |
| 问项目问题（谁定义的/为什么） | `/hub-qa` skill |

skills 在 VS Code 里输入 `/` 即出现（hub 已预置发现配置）；Claude Code 里跑一次
`scripts/link-hub` 后同样可用。

### 4. 逐项核对 LAUNCH-CHECKLIST

[LAUNCH-CHECKLIST.md](../LAUNCH-CHECKLIST.md) 的 B、C 两段（版本控制/守门点、工具依赖）
是所有场景共同的硬前提，现在就把 ⬜ 清掉。

---

准备完毕 → 回到上面的场景表，翻开你的手册。
