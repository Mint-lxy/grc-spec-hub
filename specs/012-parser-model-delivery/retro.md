# Retro: Parser 模型制品交付

**Date**: 2026-09-10

**Spec**: `specs/012-parser-model-delivery`

**Implementation commit**: `grc-parser-engine@3484fcc`

## 结果

AWS EC2 上的 Docling、MinerU 和 OFA 模型已去重、固化并交付到开发 AKS：

- Bundle ID：`parser-models-0c032755b9083fff`。
- 文件数：518。
- 总字节：21,278,861,712。
- AKS PVC：`grc-parser/parser-models`，128 GiB，RWO，
  `managed-csi-premium`，保留策略已启用。
- EC2 原模型目录未修改；重复 ModelScope cache 未进入 bundle。
- 三个模型初始化镜像和两个验证镜像均已推送项目 ACR并按 digest固定。
- parser模型与应用镜像保持分离。

## 最终模型镜像

| 组件 | ACR digest |
|------|------------|
| Docling | `sha256:906b21c93f4db8834ad5babc115e683a9179192b293cbf38ff0fdf59bd3dc6bb` |
| MinerU | `sha256:c9449466ec0695daf39579e9213a079238397d9d4371cecccddd4890e8ee92d9` |
| OFA | `sha256:fbef3fd0440f35ebe9e829f5d00ecc5c11549c315a90d31105f319a1ffa4a6c7` |

## 验证结果

1. Bundle staging/manifest单测通过；Linux符号链接拒绝行为通过。
2. canonical目录为 518 个文件、21,278,861,712 字节，低于 24 GiB上限。
3. PVC 内 518/518 文件 SHA256与 EC2 manifest一致。
4. 最终镜像热缓存下重复 loader 27.2 秒完成，没有重新复制模型。
5. 错误 SHA Job按预期失败，未写 `.complete`，旧 bundle保持可用。
6. 1 MiB目标盘触发空间不足后，loader释放自身锁。
7. 同名 Job可接管自己的未完成锁，不同 Job仍被互斥锁拒绝。
8. Docling 使用 PDF样例完成真实本地模型预检和离线解析。
9. MinerU 使用 Tesla T4完成三页 PDF离线解析。
10. OFA 在禁止出站网络、模型只读挂载下完成 preload。
11. 模型目录写入探测失败，证明只读挂载生效。
12. 清理 dry-run显示 19.8 GiB bundle但不删除；有精确 subPath或 PVC根挂载时均拒绝清理。
13. Kubernetes client/server dry-run、Ruff、密钥扫描和集群健康检查通过。
14. 验证 Pod、Job、ConfigMap和 NetworkPolicy均已清理，仅保留 PVC和完整 bundle。

## 与 plan 的偏差

1. Blob Storage网络规则为 `Deny` 且当前角色不能修改，因此采用 ACR初始化镜像中转，
   与 plan选定的替代方案一致。
2. MinerU 初始镜像遗漏 `.gitattributes`、`models/README.md` 和 `models/OriCls`；完整性
   校验在进入完成态前发现并修正。
3. 原 parser `warmup.py` 与当前 MinerU接口漂移，验证 Pod改用独立、固定的验证脚本。
4. MinerU会在模型父目录创建临时输出，最终方案以 emptyDir提供可写父目录，仅将
   `models/` 子目录从 PVC只读挂载。
5. OFA正式 parser镜像缺少 ModelScope多模态运行依赖。为证明模型制品可用，使用派生
   validator补齐固定依赖；正式应用镜像仍需在部署前回写依赖。
6. 最终审查发现 parser预检仍查找旧的 `docling-layout-old`，与下载脚本和 canonical
   `docling-layout-heron` 不一致。通过测试先行做一行常量修复，并以 Docling PDF真实解析
   验证，未改变解析算法或跨服务契约。
7. 初版 loader 使用 Pod UID持锁，Pod在 initContainer之间中断会留下不可恢复锁；最终
   改为固定 Job名称持锁，同名 Job重建可恢复，不同 Job保持互斥。
8. 清理脚本从 `.active` 标记改为查询 Namespace 内实时工作负载，精确 subPath、子路径
   和 PVC根挂载都会阻止删除。

## 服务仓库测试基线

本次模型交付专项测试、Docling单元测试及部署门禁全部通过。仓库既有全量测试基线仍有
82 个失败和 5 个错误，集中于既有 API、解析器和测试环境配置；本 spec未扩展修复这些
无关问题。

## 新事实与规则

- 开发 parser模型固定路径为
  `/models/bundles/parser-models-0c032755b9083fff/parser`。
- Docling布局模型的事实目录为 `docling-project--docling-layout-heron`。
- parser Deployment必须按完整 bundle ID使用只读 `subPath`，不能使用可变 current链接。
- 模型初始化镜像只负责填充 PVC，不作为应用运行镜像。
- 开发环境单 GPU节点可共享 RWO盘；生产多节点必须另行设计 RWX或每节点模型盘。

## 后续事项

- 正式 parser镜像补齐并锁定 OFA所需依赖，构建后重新执行三模型离线验证。
- 生产模型存储、更新、容量、并发加载和回滚策略单独立项。
- 模型及验证镜像完成正式漏洞和许可证审查。
