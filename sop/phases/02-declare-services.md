# 阶段 2 · 声明服务清单（半天）

把**已拆解好的全部子服务**一次性声明为机器可读清单，作为批量孵化的唯一输入。

## 输入
- 阶段 1 完成；服务拆解已在 `specs/000-platform` 论证。

## 步骤
1. 填 [`architecture/services.manifest.yaml`](../../architecture/services.manifest.yaml)：
   每个服务 `name / repo / owner / domain / provides / consumes / depends-on / milestone`。
2. 自查拓扑：服务名唯一；`depends-on` 只引用清单内服务；依赖**单向无环**。

## 产出
- 完整的 `services.manifest.yaml`。

## 出口判据
- [ ] 清单覆盖所有已拆解服务
- [ ] 依赖图拓扑排序成功（无环）；成环 → 回到设计，改事件解耦并写 ADR
