# MEMORY (long-term)

## Conventions

- **语言**：用户偏好中文沟通；项目代码/标识符英文。
- **交付物**：文档类一律落到 `C:\Users\mintli\OneDrive - Deloitte (CN)\Documents`；记忆类落到 `C:\Memory`（如用户要求）。
- **工作区**：未经允许或确认，不动当前工作区的内容；所有改动要问一句。
- **原型文件**：用户提到 `C:\Users\mintli\Downloads\China AI portal\*.html` 时，这些原型在 spec-hub 工作区外，按用户指令动手不算"改动工作区"。
- **本机工具**：node 在 `C:\Users\mintli\.workbuddy\binaries\node\versions\22.22.2-2\node.exe`（无 PATH 版的 node/python）；`install_binary` 装 Node 20.19.0 报 EPERM；`execute_command` 会吞 `$`，校验类脚本走 `.js` 文件 + PowerShell 免变量调用。
- **spec 工作副本（`specs/001-conversation/spec 3.md` 这类）**：用户要求「现有部分不能改动，只做增加」——只允许在既有块之间**插入**新章节，绝不重写既有行（header 的 Created/Status、文末「附录：原 AC 编号对照」标题都不要动，改动会被撤销）。排版须与该文件原生风格一致：子节 `### 中文短语（对齐 USx / FR-00x~FR-00y）` 不带字母编号；条目 `- **标签**: 内容`；不确定性写「（缺口）」「（候选）」「（待确认）」；界面文案用「」不用反引号（反引号只给 `detail` 等字段名）；说明前用 `> 注：...` 单行引用 + `**标签**: 内容` 段落；表格分隔行 `|-------|--------|`；正文避免 `+`/`→`/`↔`，改写中文「加」「到」；范围用 `~`（ID）与 `–`（数值）。

## Recurring pitfalls

- **localStorage/IndexedDB 注入种子必须配版本号**：代码改完种子数据后，旧对象已落盘到 localStorage，「按 id dedup-skip」的注入逻辑会让浏览器**永远读不到新版本**（用户截图：英文代码 + 中文用户气泡）。修复模式：声明一个 `SEED_VER` 常量，版本 mismatch 时按种子 id 集**丢弃并重建**，用户自建会话不动。原型 `marketplace - agent.html` 已落地：抽出 `makeSeed1` + `CHAT_SEED_REV="5"`。
- **`file://` 直开的原型在 Chrome 中按文件隔离 origin**——同一个文件夹下的两个 html 各自一套 localStorage；调试跨页共享状态要起本地静态服务器（`_serve.js` / `python -m http.server`）。
- **预览静态 HTML 服务**：开发服务器 `Host` 必须用 `localhost`，`127.0.0.1` 会被 `vite/serve` 拒绝并返回 `400 Invalid Hostname`。

## User preferences

- **对话风格**：直接、要点先行；不主动寒暄；术语保留英文。
- **可视化**：交付物倾向带图（页面截图标注 / AI 生成方案示意图 / 流程图）。