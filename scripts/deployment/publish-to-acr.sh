#!/usr/bin/env bash
set -Eeuo pipefail

readonly DEFAULT_WORKSPACE_ROOT="/home/mb_ai_platform/dev_deploy/workspace"
readonly DEFAULT_ACR_NAME="XAGPMCNINFCTREG001"
readonly REQUIRED_AZURE_CLOUD="AzureChinaCloud"

WORKSPACE_ROOT="${WORKSPACE_ROOT:-$DEFAULT_WORKSPACE_ROOT}"
ACR_NAME="${ACR_NAME:-$DEFAULT_ACR_NAME}"
OUTPUT_DIR=""
RUN_BUILD=false
DRY_RUN=false
PUBLISH_ALL=false
SELECTED_SERVICES=()
LOCK_DIR=""
LOCK_ACQUIRED=false

readonly ALL_SERVICES=(
  "grc-ai-portal"
  "grc-api-gateway"
  "grc-auth-service"
  "grc-mgmt-service"
  "grc-knowledge-engine"
  "grc-parser-engine"
)

usage() {
  cat <<'EOF'
Usage:
  publish-to-acr.sh [options] <service> [service...]
  publish-to-acr.sh [options] --all

Publishes EC2 runtime images to Azure China ACR with immutable Git commit tags.
It never updates AKS.

Options:
  --all                    Publish all supported services.
  --build                  Run each service's existing run-pipeline.sh first.
  --dry-run                Validate provenance without tagging or pushing.
  --workspace-root PATH    EC2 workspace root.
  --output-dir PATH        Directory for sanitized TSV/Markdown evidence.
  --acr-name NAME          Azure Container Registry resource name.
  -h, --help               Show this help.

Supported services:
  grc-ai-portal
  grc-api-gateway
  grc-auth-service
  grc-mgmt-service
  grc-knowledge-engine
  grc-parser-engine

Examples:
  ./publish-to-acr.sh grc-api-gateway
  ./publish-to-acr.sh --build grc-knowledge-engine
  ./publish-to-acr.sh --all
EOF
}

log() {
  printf '[publish-to-acr] %s\n' "$*"
}

die() {
  printf '[publish-to-acr] ERROR: %s\n' "$*" >&2
  exit 1
}

require_command() {
  command -v "$1" >/dev/null 2>&1 || die "required command not found: $1"
}

service_local_image() {
  case "$1" in
    grc-ai-portal) echo "grc-ai-portal:1.0.0" ;;
    grc-api-gateway) echo "grc-api-gateway:1.0.0" ;;
    grc-auth-service) echo "grc-auth-service:1.0.0" ;;
    grc-mgmt-service) echo "grc-mgmt-service:1.0.0" ;;
    grc-knowledge-engine) echo "grc-knowledge-engine:1.0.0" ;;
    grc-parser-engine) echo "grc-parser-engine:0.1.0" ;;
    *) die "unsupported service: $1" ;;
  esac
}

service_acr_repository() {
  case "$1" in
    grc-ai-portal) echo "grc/ai-portal" ;;
    grc-api-gateway) echo "grc/api-gateway" ;;
    grc-auth-service) echo "grc/auth-service" ;;
    grc-mgmt-service) echo "grc/mgmt-service" ;;
    grc-knowledge-engine) echo "grc/knowledge-engine" ;;
    grc-parser-engine) echo "grc/parser-engine" ;;
    *) die "unsupported service: $1" ;;
  esac
}

is_supported_service() {
  local candidate="$1"
  local service
  for service in "${ALL_SERVICES[@]}"; do
    [[ "$candidate" == "$service" ]] && return 0
  done
  return 1
}

cleanup() {
  if [[ "$LOCK_ACQUIRED" == true && -n "$LOCK_DIR" && -d "$LOCK_DIR" ]]; then
    rmdir "$LOCK_DIR" 2>/dev/null || true
  fi
}

trap cleanup EXIT

while [[ $# -gt 0 ]]; do
  case "$1" in
    --all)
      PUBLISH_ALL=true
      shift
      ;;
    --build)
      RUN_BUILD=true
      shift
      ;;
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    --workspace-root)
      [[ $# -ge 2 ]] || die "--workspace-root requires a path"
      WORKSPACE_ROOT="$2"
      shift 2
      ;;
    --output-dir)
      [[ $# -ge 2 ]] || die "--output-dir requires a path"
      OUTPUT_DIR="$2"
      shift 2
      ;;
    --acr-name)
      [[ $# -ge 2 ]] || die "--acr-name requires a name"
      ACR_NAME="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    -*)
      die "unknown option: $1"
      ;;
    *)
      SELECTED_SERVICES+=("$1")
      shift
      ;;
  esac
done

if [[ "$PUBLISH_ALL" == true ]]; then
  [[ ${#SELECTED_SERVICES[@]} -eq 0 ]] || die "--all cannot be combined with service names"
  SELECTED_SERVICES=("${ALL_SERVICES[@]}")
fi

[[ ${#SELECTED_SERVICES[@]} -gt 0 ]] || {
  usage >&2
  die "select at least one service or use --all"
}

for service in "${SELECTED_SERVICES[@]}"; do
  is_supported_service "$service" || die "unsupported service: $service"
done

require_command git
require_command docker
require_command az
require_command awk

[[ -d "$WORKSPACE_ROOT/repositories" ]] ||
  die "repository root not found: $WORKSPACE_ROOT/repositories"
[[ -d "$WORKSPACE_ROOT/scripts" ]] ||
  die "pipeline root not found: $WORKSPACE_ROOT/scripts"

OUTPUT_DIR="${OUTPUT_DIR:-$WORKSPACE_ROOT/release-evidence}"
mkdir -p "$OUTPUT_DIR"
chmod 700 "$OUTPUT_DIR" 2>/dev/null || true

LOCK_DIR="$WORKSPACE_ROOT/.publish-to-acr.lock"
mkdir "$LOCK_DIR" 2>/dev/null ||
  die "another publish is active, or stale lock exists: $LOCK_DIR"
LOCK_ACQUIRED=true

current_cloud="$(az cloud show --query name -o tsv)"
[[ "$current_cloud" == "$REQUIRED_AZURE_CLOUD" ]] ||
  die "Azure cloud must be $REQUIRED_AZURE_CLOUD, got: $current_cloud"

subscription="$(az account show --query name -o tsv)"
[[ -n "$subscription" ]] || die "Azure CLI is not authenticated"

login_server="$(az acr show --name "$ACR_NAME" --query loginServer -o tsv)"
[[ -n "$login_server" ]] || die "cannot resolve ACR login server: $ACR_NAME"

if [[ "$DRY_RUN" == false ]]; then
  log "Logging in to $ACR_NAME on $REQUIRED_AZURE_CLOUD"
  az acr login --name "$ACR_NAME" >/dev/null
fi

release_time="$(date -u +'%Y%m%dT%H%M%SZ')"
tsv_file="$OUTPUT_DIR/release-$release_time.tsv"
md_file="$OUTPUT_DIR/release-$release_time.md"

printf 'service\tbranch\tgit_sha\tlocal_image\tlocal_image_id\tprovenance\tacr_repository\tacr_tag\tacr_digest\tstatus\tpublished_at_utc\n' \
  > "$tsv_file"

for service in "${SELECTED_SERVICES[@]}"; do
  repo_path="$WORKSPACE_ROOT/repositories/$service"
  pipeline="$WORKSPACE_ROOT/scripts/$service/run-pipeline.sh"
  [[ -d "$repo_path/.git" ]] || die "$service repository is missing: $repo_path"

  dirty="$(git -C "$repo_path" status --porcelain)"
  [[ -z "$dirty" ]] || die "$service worktree is not clean"

  branch="$(git -C "$repo_path" branch --show-current)"
  git_sha="$(git -C "$repo_path" rev-parse HEAD)"
  [[ "$git_sha" =~ ^[0-9a-f]{40}$ ]] || die "$service returned invalid Git SHA: $git_sha"
  short_sha="${git_sha:0:12}"

  if [[ "$RUN_BUILD" == true ]]; then
    [[ -x "$pipeline" ]] || die "$service pipeline is missing or not executable: $pipeline"
    log "Running existing pipeline for $service at $git_sha"
    (
      cd "$(dirname "$pipeline")"
      ./run-pipeline.sh
    )
    dirty="$(git -C "$repo_path" status --porcelain)"
    [[ -z "$dirty" ]] || die "$service pipeline left tracked changes in the repository"
  fi

  local_image="$(service_local_image "$service")"
  acr_repository="$(service_acr_repository "$service")"
  local_image_id="$(docker image inspect "$local_image" --format '{{.Id}}')"
  [[ "$local_image_id" =~ ^sha256:[0-9a-f]{64}$ ]] ||
    die "$service local image returned invalid image ID: $local_image_id"

  platform="$(docker image inspect "$local_image" --format '{{.Os}}/{{.Architecture}}')"
  [[ "$platform" == "linux/amd64" ]] ||
    die "$service image platform must be linux/amd64, got: $platform"

  running_container="$(
    docker ps --format '{{.ID}} {{.Image}}' |
      awk -v expected="$local_image" '$2 == expected { print $1; exit }'
  )"
  [[ -n "$running_container" ]] ||
    die "$service has no running container using $local_image"

  running_image_id="$(docker inspect "$running_container" --format '{{.Image}}')"
  [[ "$running_image_id" == "$local_image_id" ]] ||
    die "$service running container image does not match local tag"

  revision_label="$(
    docker image inspect "$local_image" \
      --format '{{ index .Config.Labels "org.opencontainers.image.revision" }}' \
      2>/dev/null || true
  )"
  if [[ -n "$revision_label" && "$revision_label" != "<no value>" ]]; then
    if [[ ! "$revision_label" =~ ^[0-9a-f]{40}$ || "$revision_label" != "$git_sha" ]]; then
      die "$service image revision label does not match Git HEAD"
    fi
    provenance="oci-revision-verified"
    acr_tag="git-$short_sha"
  else
    provenance="runtime-image-id-only"
    image_short="${local_image_id#sha256:}"
    acr_tag="image-${image_short:0:12}"
    log "WARNING: $service image has no OCI revision label; using image-ID tag instead of Git attribution"
  fi
  target_image="$login_server/$acr_repository:$acr_tag"

  set +e
  lookup_output="$(
    az acr repository show \
      --name "$ACR_NAME" \
      --image "$acr_repository:$acr_tag" \
      --query digest \
      -o tsv 2>&1
  )"
  lookup_status=$?
  set -e

  if [[ $lookup_status -eq 0 ]]; then
    die "$service immutable ACR tag already exists: $target_image@$lookup_output"
  fi

  lookup_error="${lookup_output,,}"
  if [[ "$lookup_error" != *"manifest unknown"* && "$lookup_error" != *"not found"* ]]; then
    die "$service failed to check ACR tag availability: ${lookup_output%%$'\n'*}"
  fi

  if [[ "$DRY_RUN" == true ]]; then
    status="dry-run"
    acr_digest="<not-pushed>"
    log "DRY RUN: would push $local_image as $target_image"
  else
    log "Publishing $service from $local_image_id as $target_image"
    docker tag "$local_image" "$target_image"
    docker push "$target_image"
    acr_digest="$(
      az acr repository show \
        --name "$ACR_NAME" \
        --image "$acr_repository:$acr_tag" \
        --query digest \
        -o tsv
    )"
    [[ "$acr_digest" =~ ^sha256:[0-9a-f]{64}$ ]] ||
      die "$service ACR returned invalid digest: $acr_digest"
    az acr repository update \
      --name "$ACR_NAME" \
      --image "$acr_repository:$acr_tag" \
      --write-enabled false \
      --delete-enabled false \
      >/dev/null
    status="pushed"
  fi

  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
    "$service" \
    "$branch" \
    "$git_sha" \
    "$local_image" \
    "$local_image_id" \
    "$provenance" \
    "$acr_repository" \
    "$acr_tag" \
    "$acr_digest" \
    "$status" \
    "$release_time" \
    >> "$tsv_file"
done

{
  echo "# EC2 to ACR Release $release_time"
  echo
  echo "- Azure cloud: \`$current_cloud\`"
  echo "- Subscription: \`$subscription\`"
  echo "- ACR: \`$login_server\`"
  echo "- AKS updated: **No**"
  echo
  echo "| Service | Branch | Git SHA | Source image ID | Provenance | ACR image | Digest | Status |"
  echo "|---|---|---|---|---|---|---|---|"
  tail -n +2 "$tsv_file" |
    while IFS=$'\t' read -r service branch sha local_image image_id provenance repository tag digest status published; do
      echo "| \`$service\` | \`$branch\` | \`$sha\` | \`$image_id\` | $provenance | \`$login_server/$repository:$tag\` | \`$digest\` | $status |"
    done
} > "$md_file"

chmod 600 "$tsv_file" "$md_file" 2>/dev/null || true

log "Release evidence:"
log "  $tsv_file"
log "  $md_file"
log "No AKS resources were changed."
