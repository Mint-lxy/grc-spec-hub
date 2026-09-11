# Curate 新手快速引导方案
**项目**:Mercedes-Benz GRC AI Agent Portal · Curate 模块(knowledge.html)
**日期**:2026-09-09 · **状态**:评审稿 v1

## 0. 一页速览
- **推荐**:方案 B(分角色聚光引导)+ 方案 D(常驻帮助/空态提示)兜底。
- **轻量首选**:方案 A(首次任务清单);**演示期叠加**:方案 C(自动演示);**二期**:方案 E(平台级学习路径)。
- 核心理由:Curate 是操作型模块,Owner/Contributor/Consumer/Viewer 四种角色能力差异大;聚光引导与系统既有 `body.role-*` 权限机制天然对齐,能直接演示"谁能做什么"。

## 1. 系统现状(影响引导设计的事实)
### 1.1 页面结构与首屏行为
- knowledge.html 为原生 JS 单页(state + renderMain 重绘),与 index/marketplace/build/govern 共享同一套 shell。
- Screen1 Overview(视频 banner、KPI、Build Pipeline、Domain 环形图)在用户向下滚动或点击 "Browse library" 后被 `burnOverview()` 永久移除并锚定到库。**引导不得依赖首屏常驻元素,应在 catalog 就位后启动。**
- Screen2 知识库:`#scope-tabs`(Public/My)、`#kb-side` 目录树、`#kb-detail` 列表/详情;KB 内 tabs = Information / Documents。

### 1.2 角色与权限模型
| 角色 | 默认页签 | 关键能力 | 典型阻塞 |
|---|---|---|---|
| Owner | Documents | +目录/+KB、Add documents、Configure、One-click build、Settings、Permissions | — |
| Contributor | Documents | 上传/配置/构建/删除文档(不可改设置与权限) | 无 Settings 入口 |
| Consumer | Information | 只读文档与元数据、检索 | 不能编辑 |
| Viewer | Information | 只读;受限库渲染 No-access 页,给出 Alice 角色 ID 申请入口 | 受限库被拦 |

机制:`body.role-{owner|contributor|consumer|viewer}` + CSS `.perm-owner/.perm-edit` 显隐;`defaultKbTab()` 按 `canEdit()` 决定默认页签;顶栏 role-switch 即"换视角"开关。

### 1.3 可复用交互原语
全屏浮层 `kb-modal-overlay` / `fd-overlay` / `soon-overlay`(`.open` 切换)、toast `#msg-wrap`、`popconfirm`、`data-tip` 提示、空态内建 CTA(空目录/无文档)、localStorage 可用。

### 1.4 设计 token
`--accent:#0078D6`、`--accent-bright:#4DA8EE`、`--muted:#9a9a9a`、`--ok:#2ea36b`;黑壳顶栏 + 浅色内容卡;嵌入 MB 字体。

## 2. 新手定义与引导目标
**新手**:首次进入 Curate 的演示用户(默认 Owner)与未来真实平台新成员。
**目标**:① 60 秒内明白 Curate 做什么、自己角色能做什么;② 走完一条最小闭环(浏览/选库 → 看懂 Documents 与四段管线 → 编辑角色完成上传/构建,或只读角色完成阅读/权限申请);③ 不打扰有经验用户。
**原则**:只看一次(localStorage)、可跳过(Esc/Skip)、可重播、角色适配、移动端降级可用。

## 3. 方案清单(按成本从低到高)
### 方案 A · 首次任务清单(Welcome Checklist)
- **形态**:落地时弹一次全屏欢迎卡(复用 kb-modal 版式),3~5 个真实可点任务;"去完成"按钮直接调现成函数(`goList(null)`、`openKb(...)`、`openNewKbModal()`、`openUploadSourceMenu`);完成打勾 + 进度条,全部完成 toast;localStorage 记忆,角落可重播。
- **Owner 示例任务**:浏览库 → 打开 Ready 库看管线 → 添加文档 → 一键构建 → 查看权限/设置。
- **契合点**:是"空态 CTA/通知"的结构化升级,不需要 DOM 镂空定位,改动集中。
- **优劣**:✅ 成本最低、带进度与成就感、能驱动真实操作;❌ 不演示每一步,观看型用户略被动。
- **工作量**:S(1 overlay + 30~50 行 JS + 少量 CSS)。
- ![方案A](images/scheme-a.svg)
- 分步示意:
  - ![任务1](images/steps/a-1.png) ![任务2](images/steps/a-2.png) ![任务3](images/steps/a-3.png) ![任务4](images/steps/a-4.png) ![任务5](images/steps/a-5.png)

### 方案 B · 分角色聚光引导(Spotlight Tour)★ 主推
- **形态**:深色遮罩 + 目标镂空高亮 + 箭头气泡 + Prev/Next/Skip/Done;按 role-switch 当前角色分发两条 tour:
  - Owner/Contributor(6 步):目录树 → 库列表(状态/Docs/Chunks/覆盖)→ 打开示例库看 Documents 与 Parse→Chunk→Enhancer→Embedding 四段 → Add documents → One-click build → 文件详情(fd-overlay)。
  - Consumer/Viewer(4 步):库/目录浏览 → Information 页签(描述/归属/角色与访问)→ 受限库 No-access + Alice ID → 检索测试。
- **实现**:现成选择器/补 `data-guide` 锚点;步骤切换=更新气泡 + rect 定位 + 滚动聚焦;跳步复用现成函数;抽象成可复用 mini 组件。
- **契合点**:与 `defaultKbTab`、`.perm-*` 天然对齐;切 consumer 重播即演示"角色差异",是本系统引导的最大卖点。
- **优劣**:✅ 最直观、演示质感强、权限边界讲得清、真实产品可沿用;❌ 需定位/遮罩逻辑与高质量措辞,需做好"只看一次 + 可跳过"。
- **工作量**:M(120~200 行共享代码)。
- ![方案B](images/scheme-b.svg)
- 分步示意(Owner/Contributor,6 步):
  - ![b1](images/steps/b-1.png) ![b2](images/steps/b-2.png) ![b3](images/steps/b-3.png) ![b4](images/steps/b-4.png) ![b5](images/steps/b-5.png) ![b6](images/steps/b-6.png)
- 分步示意(Consumer/Viewer,4 步):
  - ![bc1](images/steps/b-c1.png) ![bc2](images/steps/b-c2.png) ![bc3](images/steps/b-c3.png) ![bc4](images/steps/b-c4.png)

### 方案 C · 自动演示模式(Guided Demo)
- **形态**:"▶ Watch 3-min tour" 按钮,按剧本自动驱动 UI:burn 首屏 → 库列表 → 打开 "AML Regulatory Updates" → 切 Documents 播管线动画 → 打开文件详情 → 收尾 toast;支持暂停/退出。
- **契合点**:页面已有大量 setTimeout 驱动的模拟(build/jobs/管线状态),剧本只是串时间轴。
- **优劣**:✅ 3 分钟讲完模块,评审/汇报极佳;❌ 对要自己动手的人价值低,剧本需随 UI 维护,可能与手动操作冲突。
- **工作量**:M+。仅演示期叠加。
- ![方案C](images/scheme-c.svg)
- 分步示意(剧本 5 幕):
  - ![c1](images/steps/c-1.png) ![c2](images/steps/c-2.png) ![c3](images/steps/c-3.png) ![c4](images/steps/c-4.png) ![c5](images/steps/c-5.png)

### 方案 D · 常驻帮助体系(Contextual Help,三件可拆)
1. 页头 "?" 按钮 → Curate 帮助浮层:按"我的角色"讲能做什么/怎么申请权限/Alice 是什么;
2. 空态引导卡升级:现纯文字 CTA 升级为"插图 + 下一步按钮"小卡;
3. 首见提示:复用 `data-tip`,第一次看到四段管线/No-access 时自动解释一次。
- **契合点**:与现有空态逻辑同源;无障碍友好;永不打扰。
- **优劣**:✅ 成本最低、永久可用;❌ 无任务推进感。
- **工作量**:S(可只做 1~2 件)。
- ![方案D](images/scheme-d.svg)
- 分步示意(三件可拆):
  - ![d1](images/steps/d-1.png) ![d2](images/steps/d-2.png) ![d3](images/steps/d-3.png)

### 方案 E · 平台级学习路径(Onboarding Hub)
- **形态**:平台层出现"导览"卡片(Chat→Explore→Curate→Build→Govern),带 `?guide=curate` 跳入本页,本页检测参数自动启动模块 tour;共享引导引擎拷入各页。
- **契合点**:贴合门户叙事,新人先有全局认知。
- **优劣**:✅ 全域视角;❌ 跨文件改动面大,二期再铺开。
- **工作量**:M。
- ![方案E](images/scheme-e.svg)
- 分步示意:
  - ![e1](images/steps/e-1.png) ![e2](images/steps/e-2.png)

## 4. 对比矩阵
| 维度 | A 清单 | B 聚光 | C 演示 | D 帮助 | E 平台级 |
|---|---|---|---|---|---|
| 首访理解效率 | ★★★☆ | ★★★★★ | ★★★★★ | ★★☆ | ★★★★ |
| 驱动自己动手 | ★★★★ | ★★★★☆ | ★☆ | ★★ | ★★★★ |
| 演示/汇报价值 | ★★☆ | ★★★★ | ★★★★★ | ★★ | ★★★★ |
| 真实产品可复用 | ★★★★ | ★★★★★ | ★★ | ★★★★★ | ★★★★★ |
| 原型落地成本 | S | M | M+ | S | M |
| 打扰度 | 中 | 中 | 高 | 极低 | 低 |
| 角色差异呈现 | 一般 | **强** | 中 | 中 | 强 |
| 综合定位 | 轻量首选 | **主推** | 演示期叠加 | 常驻兜底 | 二期 |

## 5. 推荐组合与理由
**主引导 = B**:聚光最适合讲"哪里能点、哪里不能点";与 role-switch 联动可直接演示权限差异;引擎解耦,后续 A/E 可复用。
**兜底 = D**:错过/跳过引导的人随时自救;localStorage 记忆,无后端依赖。
**条件叠加 C**:近期有对外评审时,给 B 加"自动播放"入口(同一剧本)。

## 6. 推荐方案(B)落地蓝图
### 6.1 触发与记忆
```js
var tour = new GuideTour("curate", {
  seenKey: "grc.curate.tour.seen.v1",
  autoplay: /[?&]guide=curate/.test(location.search) || !localStorage.getItem("grc.curate.tour.seen.v1"),
  role: function(){ return document.getElementById("role-switch").value; }
});
```
首次自动播;页头"重播引导"入口;Esc、Skip、"不再显示"三路退出,退出写 seen。

### 6.2 步骤表
**Owner/Contributor(6 步)**
| # | 锚点/动作 | 气泡要点 | 下一步动作 |
|---|---|---|---|
| 1 | `.kb-side` 目录树 | 知识库按目录组织;Public/My 顶部切换 | 滚动聚焦 + 展开目录 |
| 2 | `#kb-detail` 首行 | 每行=一个库;Status/Docs/Chunks/Coverage | `openKb(...)` |
| 3 | `.pipe` / 行内 `pipe-flow` | Parse→Chunk→Enhancer→Embedding;FAILED 可点修 | 回 Documents |
| 4 | `#kb-upload` | 上传后自动解析入库 | 高亮停留 |
| 5 | One-click build 批量钮 | 选中文档一次构建;可单个 Configure | — |
| 6 | 行文档(触发 `openFile`) | 文件详情=段落/分块/引用预览 | toast + 写 seen |

**Consumer/Viewer(4 步)**:库/目录浏览 → Information(描述/归属/角色与访问)→ 受限库 No-access(Alice ID)→ 检索测试。

### 6.3 视觉规格
遮罩 `rgba(5,10,18,.6)`;聚光框 2px 虚线 `--accent-bright` + 8px 圆角 + 柔影;气泡卡白底/深色标题,圆角 10px,箭头自动指向;按钮复用 `.btn.btn-secondary`(Back/Skip)与 `.btn.btn-solid`(Next/Done);右上 "n/6" + 分段圆点;文案用系统词表(Owner/Contributor/Consumer、Alice、Pipeline、Retrieval)。

### 6.4 集成注意事项
1. 启动时机:overview burn 之后或以 catalog 为目标,不依赖首屏元素;
2. render 函数 innerHTML 重绘会替换节点,每步重新 `querySelector` 锚点;
3. Viewer/受限库步骤替换为 No-access 页 + Alice ID,顺带完成权限教育;
4. ≤960px 时 `.kb-layout` 单列,聚光改"整块滚动定位 + 全宽气泡";
5. 角色切换期间如引导在播,按新角色重排剩余步骤。

### 6.5 验收标准
- 首次进入自动起播,关闭后刷新不再出现;手动重播可用;
- Owner 与 Consumer 两条路径步骤、默认页签正确;
- 每步目标元素可见、聚焦、无遮挡;Esc/Skip 全程可用;
- 与 modal/fd-overlay/role-switch/面包屑返回互不干扰;
- localStorage 清除后可复现首播。

## 7. 风险与缓解
| 风险 | 缓解 |
|---|---|
| 气泡措辞与真实文案脱节 | 文案走评审,纳入术语表 |
| 重绘导致锚点丢失 | 每步重查选择器 + 兜底跳过该步 |
| 演示剧本(C)与手动操作冲突 | 演示期间锁定输入,退出即恢复 |
| 多页(E)代码漂移 | 引擎抽公共文件,页面仅配置步骤 |

## 8. 附录
### A. 截图标注指引(自制 shot-*.png)
- shot-1-overview:首屏 Overview(banner/KPI/Build Pipeline/环形图),`#4DA8EE` 2px 虚线框 + ①②③ 圆点标注;
- shot-2-catalog:库页(目录树、scope tabs、列表表头与空态 CTA);
- shot-3-kb-documents:KB 详情 Documents 页签(Add documents、One-click build、四段管线、某行 FAILED);
- shot-4-noaccess:Viewer 角色受限库 No-access 页(Alice 角色 ID、Request in Alice)。
### B. 图片清单
scheme-a/b/c/d/e.svg(本包内嵌);flow-tour.svg(两条角色路径流程图);steps/ 目录 25 张分步示意(a-1~5、b-1~6、b-c1~4、c-1~5、d-1~3、e-1~2,SVG + PNG 各一份);shot-1~4.png(按附录A补)。
### C. docx 转换
`pandoc 本文件.md -o GRC-Curate-新手引导方案.docx --resource-path=.`;或 Word 打开 HTML 另存。
### D. 术语
Owner/Contributor/Consumer/Viewer(角色);Alice(IAM 权限系统);Pipeline(Parse→Chunk→Enhancer→Embedding);KB(知识库);Retrieval(检索)。
