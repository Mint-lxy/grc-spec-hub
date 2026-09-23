# scripts/ — hub 接入与本地检查脚本

pull 模型的"接线器"。每个脚本提供 **PowerShell (`.ps1`)** 与 **Bash (`.sh`)** 两版，行为一致；
修改其一时必须同步另一个。

| 脚本 | 在哪运行 | 作用 |
|------|----------|------|
| `link-hub.{ps1,sh}` | **服务仓库**根目录 | 把该仓库接到同级目录的 hub：校验 hub 可达、生成 `.claude/skills` 链接、生成多根 `.code-workspace`、校验 `AGENTS.md` 占位符已替换 |
| `check-contracts.{ps1,sh}`（见 [gates/scripts](../gates/scripts/README.md)） | hub 根目录 | 契约门禁本地版：语法校验 + 破坏性检测 |

## link-hub 用法

前置：服务仓库与 hub **克隆在同一父目录**：

```
<workspace-root>/
  grc-spec-hub/
  svc-order/        ← 在这里运行
```

```powershell
# 服务仓库根目录（Windows / pwsh）
../grc-spec-hub/scripts/link-hub.ps1            # hub 默认取 ../grc-spec-hub
../grc-spec-hub/scripts/link-hub.ps1 -HubPath ../my-hub
# 若报 UnauthorizedAccess：先跑 Set-ExecutionPolicy -Scope Process Bypass -Force
```

```bash
# 服务仓库根目录（macOS / Linux）
../grc-spec-hub/scripts/link-hub.sh [hub-path]
```

脚本做的事（幂等，可重复运行）：
1. 校验 hub 路径存在且含 `hub.config.yaml`；
2. 生成 `.claude/skills` → `<hub>/capabilities/skills` 链接（Windows 用 junction），
   并确保 `.claude/skills` 在服务仓库 `.gitignore` 中；
3. 若无 `*.code-workspace`，生成多根工作区文件（服务仓库 + hub，含
   `chat.agentSkillsLocations` 指向 hub skills）；
4. 校验 `AGENTS.md` 存在且不再含 `{{...}}` 占位符、hub 相对路径可达。

任何一步失败以非零退出码结束并给出修复提示。
