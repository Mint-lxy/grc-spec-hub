# gates/scripts — 本地门禁检查脚本（跨平台）

每个脚本提供 **PowerShell (`.ps1`)** 与 **Bash (`.sh`)** 两个版本，行为一致；
修改其一时必须同步另一个。全部在 **hub 根目录**运行，合并对应 PR 前必跑。

| 脚本 | 作用 | 何时跑 |
|------|------|--------|
| `check-contracts.{ps1,sh}` | 契约语法校验 + 破坏性变更检测（默认自动探测基准分支 main/master） | `contracts/**` 有变更时 |
| `check-plan.{ps1,sh}` | 校验 plan.md 含「涉及服务」「契约影响」两章 | `specs/**` 有变更时 |

> Windows PowerShell 若报 `UnauthorizedAccess`，先执行
> `Set-ExecutionPolicy -Scope Process Bypass -Force`（或用
> `powershell -ExecutionPolicy Bypass -File <script>` 调用）。

## 依赖（缺失时降级为警告）

- `npx`（Node.js）— 拉起 `@redocly/cli` 与 `@asyncapi/cli`
- `oasdiff` — 破坏性检测（`go install github.com/oasdiff/oasdiff@latest` 或下载二进制）
- `git`

## 示例

```powershell
./gates/scripts/check-contracts.ps1              # 基准分支自动探测，也可 -BaseRef 指定
./gates/scripts/check-plan.ps1 -SpecDir specs/013-order-query
```

```bash
gates/scripts/check-contracts.sh
gates/scripts/check-plan.sh specs/013-order-query
```
