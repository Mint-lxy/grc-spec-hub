# EC2 镜像发布脚本

`publish-to-acr.sh` 将 EC2 当前运行的 GRC 镜像发布到 Azure China ACR。脚本只负责
镜像发布与证据生成，不修改 AKS。

## 安装到 EC2

从 `grc-spec-hub` 仓库复制：

```bash
cd /home/mb_ai_platform/dev_deploy
install -m 0750 \
  grc-spec-hub/scripts/deployment/publish-to-acr.sh \
  workspace/scripts/publish-to-acr.sh
```

如 Hub 不位于该目录，先把脚本通过批准的文件传输方式复制到 EC2，再执行：

```bash
chmod 0750 /home/mb_ai_platform/dev_deploy/workspace/scripts/publish-to-acr.sh
```

## 前置条件

1. Azure CLI 已登录 `AzureChinaCloud`。
2. 当前身份具有 ACR push 权限。
3. Docker daemon 正常。
4. 服务仓库位于 `workspace/repositories/<service>`。
5. 运行容器使用脚本登记的本地镜像 tag。
6. Git 工作树 clean。

确认：

```bash
az cloud set --name AzureChinaCloud
az account show
docker ps
```

脚本不会执行 `az login`，避免在自动化中保存账号或密码。

## 常用命令

发布单服务当前运行镜像：

```bash
cd /home/mb_ai_platform/dev_deploy/workspace/scripts
./publish-to-acr.sh grc-knowledge-engine
```

发布全部服务：

```bash
./publish-to-acr.sh --all
```

先调用服务原有 `run-pipeline.sh`，再发布：

```bash
./publish-to-acr.sh --build grc-api-gateway
```

仅验证、不推送：

```bash
./publish-to-acr.sh --dry-run --all
```

## 发布规则

- OCI revision label 与完整 Git SHA 一致时，ACR tag 为 `git-<12位commit>`。
- 旧镜像无 revision label 时使用 `image-<12位image-id>`，不得宣称 Git 归因。
- tag 已存在时立即失败，绝不覆盖。
- 本地 tag 的 image ID 必须与运行容器 image ID 一致。
- OCI revision label 存在时必须是与 Git HEAD 完全一致的 40 位 SHA。
- 无 revision label 时会明确警告，发布记录标记为 `runtime-image-id-only`。
- 推送完成后将 ACR artifact 设置为禁止写入和删除。
- 镜像必须为 `linux/amd64`。
- 任一服务失败即停止，不继续发布后续服务。

## 输出

默认写入：

```text
/home/mb_ai_platform/dev_deploy/workspace/release-evidence/
```

每次生成：

```text
release-<UTC时间>.tsv
release-<UTC时间>.md
```

记录内容包括服务、分支、Git SHA、本地 image ID、ACR tag、ACR digest、状态和时间。
不记录环境变量、Secret、SAS URL 或容器完整 inspect。

## 并发与异常恢复

脚本通过以下目录防止并发发布：

```text
workspace/.publish-to-acr.lock
```

正常退出会自动删除。若进程被强制终止，确认没有其他发布进程后再删除：

```bash
ps -ef | grep '[p]ublish-to-acr.sh'
rm -rf /home/mb_ai_platform/dev_deploy/workspace/.publish-to-acr.lock
```

## 测试

```bash
cd /path/to/grc-spec-hub
bash -n scripts/deployment/publish-to-acr.sh
bash scripts/deployment/tests/test-publish-to-acr.sh
```
