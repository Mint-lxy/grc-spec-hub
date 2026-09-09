# Retro: Milvus 开发环境部署

**Date**: 2026-09-09

**Spec**: `specs/011-milvus-dev-deployment`

**Implementation commit**: `grc-knowledge-engine@8593554`

## 结果

开发 AKS `XAGPMCNINFAKS001` 已部署 Milvus 2.5.12 Standalone：

- Helm Chart：4.2.49，vendored SHA256
  `7DEC3D23171B0B096F15587535F60A3EABD5856C576CFC799F7C4766AA7F2596`。
- Milvus Standalone + Rocksmq：1 个 Pod。
- etcd 3.5.18-r1：1 个 Pod。
- MinIO `RELEASE.2025-09-07T16-13-09Z`：1 个 Pod。
- 三个 64 GiB `managed-csi-premium` PVC。
- 全部组件运行于 `milvuspool`，节点池 taint 为 `sku=milvus:NoSchedule`。
- Service 为 ClusterIP，仅暴露集群内 19530/9091。
- Milvus authorization 已开启，默认 root 密码已轮换并验证失效。

## 验证结果

1. 静态部署策略测试通过。
2. Smoke 客户端单测 4/4 通过。
3. Ruff、Helm lint/template/server dry-run 通过。
4. CRUD/search smoke test 返回预期向量主键。
5. Milvus Pod 重建后数据查询成功。
6. etcd Pod 重建后数据查询成功。
7. MinIO Pod 重建后数据查询成功。
8. 三个 PVC 在全部重建测试前后 UID 和容量保持不变。
9. 无 Milvus toleration 的普通 Pod 被 `sku=milvus:NoSchedule` 拒绝调度。
10. Helm revision 2 回滚到 revision 1 后数据查询成功。
11. Helm uninstall 后 Secret 和三个 PVC 保留。
12. 使用同一 Chart/values 重装后复用相同 PVC UID，原 collection 仍可查询。
13. 重装后 CRUD/search 再次通过。
14. 四个 AKS 节点均 Ready，无新增 CrashLoopBackOff/ImagePullBackOff。

## 资源与存储

| 组件 | CPU request/limit | Memory request/limit | PVC |
|------|-------------------|----------------------|-----|
| Milvus | 1500m / 2500m | 8 GiB / 16 GiB | `milvus` 64 GiB |
| etcd | 250m / 500m | 512 MiB / 1 GiB | `data-milvus-etcd-0` 64 GiB |
| MinIO | 250m / 500m | 1 GiB / 2 GiB | `milvus-minio` 64 GiB |

稳定运行时节点利用率约为 4% CPU / 6% memory，仍有开发测试余量。

## 与 plan 的偏差

1. `pulsar.enabled=false` 不会关闭 Chart 4.2.49 默认启用的 Pulsar v3；实施中补充
   `pulsarv3.enabled=false`，静态镜像门禁发现并阻止了未批准公网镜像。
2. Bitnami etcd 子 Chart 会自动为 repository 添加 `docker.io`；values 改为
   `etcd.global.imageRegistry=<ACR>` + 相对 repository。
3. etcd PVC 使用 StatefulSet `volumeClaimTemplates`，Helm render 中只有两个独立 PVC
   Kind；静态测试据此校验“两 PVC + 一 claim template”，运行时仍为三个 PVC。
4. PyMilvus 默认依赖包含本地版 `milvus-lite/faiss/pyarrow`，不适合最小远程验收镜像；
   smoke 镜像仅安装远程 MilvusClient 所需的固定依赖，再以 `--no-deps` 安装
   pymilvus 2.5.18。
5. PyMilvus 新密码探测在构造客户端时抛出 `grpc.RpcError`，而不是
   `MilvusException`；认证脚本收窄为仅捕获这两类已知连接异常。
6. Helm 4 已弃用 `--atomic`，Runbook 使用 `--rollback-on-failure --wait`。
7. Helm uninstall 返回后，旧 Pod 仍可能短暂处于 Terminating；重装前 Runbook 必须
   等待 Namespace 中旧 Pod 全部退出。

## 服务仓库测试基线

`grc-knowledge-engine` 的部署专项测试全部通过。现有服务测试在临时 editable 安装
`grc-python-sdk` 后仍有 8 个与本次部署工件无关的失败：

- OpenAPI provider contract `$ref` 断言。
- readiness 可选能力字段。
- 未配置 DATABASE_URL。
- 空 query 参数归一化。
- Dify 请求字段严格性。
- SourceItem `run_mode` 校验。

本 spec 未修改应用代码，不在部署任务中修复这些既有失败。

## 新事实与规则

- 开发 Milvus 内部地址：
  `http://milvus.milvus.svc.cluster.local:19530`。
- `MILVUS_TOKEN` 必须由 Secret 动态构造，不得写入 values 或 Git。
- Milvus Chart 4.2.49 同时存在 `pulsar` 和 `pulsarv3` 开关，Standalone 必须都关闭。
- 普通 Helm uninstall 不删除数据；真正删除 PVC 会因 StorageClass `Delete` 同步删除
  Azure Disk，必须独立二次确认。
- 当前部署是开发单节点拓扑，不具备生产 HA 或 RPO/RTO 承诺。

## 后续事项

- 部署 knowledge-engine 时注入 Milvus URI/token并执行应用集成测试。
- 生产 Milvus 需独立设计 Cluster 拓扑、备份、恢复、RPO/RTO 和多可用区策略。
- 增加 PVC 80% 容量告警、Milvus 指标和组件健康告警。
- 完成 Milvus、MinIO、etcd、PyMilvus 及基础镜像的正式许可证/漏洞审查。
