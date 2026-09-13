#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PUBLISH_SCRIPT="$SCRIPT_DIR/../publish-to-acr.sh"
TMP_ROOT="$(mktemp -d)"
trap 'rm -rf "$TMP_ROOT"' EXIT

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

assert_contains() {
  local file="$1"
  local expected="$2"
  grep -Fq "$expected" "$file" || fail "$file does not contain: $expected"
}

create_mocks() {
  local bin_dir="$1"
  mkdir -p "$bin_dir"

  cat > "$bin_dir/git" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
case "$*" in
  *"status --porcelain"*)
    [[ "${MOCK_GIT_DIRTY:-0}" == "1" ]] && echo " M changed.txt"
    :
    ;;
  *"rev-parse HEAD"*)
    echo "1234567890abcdef1234567890abcdef12345678"
    ;;
  *"branch --show-current"*)
    echo "feature/release260911"
    ;;
  *)
    echo "unexpected git invocation: $*" >&2
    exit 2
    ;;
esac
EOF

  cat > "$bin_dir/docker" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
echo "docker $*" >> "$MOCK_STATE_DIR/docker.log"
if [[ "$1 $2" == "image inspect" ]]; then
  if [[ "$*" == *".Config.Labels"* ]]; then
    if [[ "${MOCK_REVISION_LABEL:-0}" == "1" ]]; then
      echo "1234567890abcdef1234567890abcdef12345678"
    else
      echo "<no value>"
    fi
  elif [[ "$*" == *".Os"* ]]; then
    echo "linux/amd64"
  else
    echo "sha256:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"
  fi
elif [[ "$1" == "ps" ]]; then
  echo "container-1 grc-ai-portal:1.0.0"
elif [[ "$1" == "inspect" ]]; then
  echo "sha256:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"
elif [[ "$1" == "push" ]]; then
  touch "$MOCK_STATE_DIR/pushed"
elif [[ "$1" == "tag" ]]; then
  :
else
  echo "unexpected docker invocation: $*" >&2
  exit 2
fi
EOF

  cat > "$bin_dir/az" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
echo "az $*" >> "$MOCK_STATE_DIR/az.log"
if [[ "$1 $2" == "cloud show" ]]; then
  echo "AzureChinaCloud"
elif [[ "$1 $2" == "account show" ]]; then
  echo "test-subscription"
elif [[ "$1 $2" == "acr show" ]]; then
  echo "example.azurecr.cn"
elif [[ "$1 $2" == "acr login" ]]; then
  :
elif [[ "$1 $2 $3" == "acr repository show" ]]; then
  if [[ "${MOCK_ACR_ERROR:-0}" == "1" ]]; then
    echo "ERROR: unauthorized" >&2
    exit 1
  elif [[ "${MOCK_TAG_CONFLICT:-0}" == "1" || -f "$MOCK_STATE_DIR/pushed" ]]; then
    echo "sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
  else
    echo "ERROR: manifest unknown: requested tag is not found" >&2
    exit 3
  fi
elif [[ "$1 $2 $3" == "acr repository update" ]]; then
  :
else
  echo "unexpected az invocation: $*" >&2
  exit 2
fi
EOF

  chmod +x "$bin_dir/git" "$bin_dir/docker" "$bin_dir/az"
}

test_publishes_commit_tag_and_manifest() {
  local case_dir="$TMP_ROOT/success"
  local workspace="$case_dir/workspace"
  local output="$case_dir/output"
  local mocks="$case_dir/bin"
  mkdir -p "$workspace/repositories/grc-ai-portal/.git" "$workspace/scripts" "$output"
  create_mocks "$mocks"

  PATH="$mocks:$PATH" MOCK_STATE_DIR="$case_dir" MOCK_REVISION_LABEL=1 \
    bash "$PUBLISH_SCRIPT" \
      --workspace-root "$workspace" \
      --output-dir "$output" \
      --acr-name "testacr" \
      grc-ai-portal

  local manifest
  manifest="$(find "$output" -name 'release-*.tsv' -type f | head -n 1)"
  [[ -n "$manifest" ]] || fail "release manifest was not created"
  assert_contains "$manifest" $'grc-ai-portal\tfeature/release260911\t1234567890abcdef1234567890abcdef12345678'
  assert_contains "$manifest" $'oci-revision-verified\tgrc/ai-portal\tgit-1234567890ab\tsha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa\tpushed'
  assert_contains "$case_dir/docker.log" "docker tag grc-ai-portal:1.0.0 example.azurecr.cn/grc/ai-portal:git-1234567890ab"
  assert_contains "$case_dir/docker.log" "docker push example.azurecr.cn/grc/ai-portal:git-1234567890ab"
}

test_rejects_dirty_repository() {
  local case_dir="$TMP_ROOT/dirty"
  local workspace="$case_dir/workspace"
  local output="$case_dir/output"
  local mocks="$case_dir/bin"
  mkdir -p "$workspace/repositories/grc-ai-portal/.git" "$workspace/scripts" "$output"
  create_mocks "$mocks"

  if PATH="$mocks:$PATH" MOCK_STATE_DIR="$case_dir" MOCK_GIT_DIRTY=1 \
    bash "$PUBLISH_SCRIPT" \
      --workspace-root "$workspace" \
      --output-dir "$output" \
      --acr-name "testacr" \
      grc-ai-portal; then
    fail "dirty repository should be rejected"
  fi

  [[ ! -f "$case_dir/pushed" ]] || fail "dirty repository was pushed"
}

test_rejects_existing_immutable_tag_without_push() {
  local case_dir="$TMP_ROOT/existing"
  local workspace="$case_dir/workspace"
  local output="$case_dir/output"
  local mocks="$case_dir/bin"
  mkdir -p "$workspace/repositories/grc-ai-portal/.git" "$workspace/scripts" "$output"
  create_mocks "$mocks"

  if PATH="$mocks:$PATH" MOCK_STATE_DIR="$case_dir" MOCK_TAG_CONFLICT=1 MOCK_REVISION_LABEL=1 \
    bash "$PUBLISH_SCRIPT" \
      --workspace-root "$workspace" \
      --output-dir "$output" \
      --acr-name "testacr" \
      grc-ai-portal; then
    fail "existing immutable tag should be rejected"
  fi
  [[ ! -f "$case_dir/pushed" ]] || fail "existing immutable tag was overwritten"
}

test_unlabeled_image_uses_image_id_tag() {
  local case_dir="$TMP_ROOT/unlabeled"
  local workspace="$case_dir/workspace"
  local output="$case_dir/output"
  local mocks="$case_dir/bin"
  mkdir -p "$workspace/repositories/grc-ai-portal/.git" "$workspace/scripts" "$output"
  create_mocks "$mocks"

  PATH="$mocks:$PATH" MOCK_STATE_DIR="$case_dir" \
    bash "$PUBLISH_SCRIPT" \
      --workspace-root "$workspace" \
      --output-dir "$output" \
      --acr-name "testacr" \
      grc-ai-portal

  local manifest
  manifest="$(find "$output" -name 'release-*.tsv' -type f | head -n 1)"
  assert_contains "$manifest" $'runtime-image-id-only\tgrc/ai-portal\timage-bbbbbbbbbbbb'
  assert_contains "$case_dir/docker.log" \
    "docker push example.azurecr.cn/grc/ai-portal:image-bbbbbbbbbbbb"
}

test_rejects_acr_lookup_errors() {
  local case_dir="$TMP_ROOT/acr-error"
  local workspace="$case_dir/workspace"
  local output="$case_dir/output"
  local mocks="$case_dir/bin"
  mkdir -p "$workspace/repositories/grc-ai-portal/.git" "$workspace/scripts" "$output"
  create_mocks "$mocks"

  if PATH="$mocks:$PATH" MOCK_STATE_DIR="$case_dir" MOCK_ACR_ERROR=1 MOCK_REVISION_LABEL=1 \
    bash "$PUBLISH_SCRIPT" \
      --workspace-root "$workspace" \
      --output-dir "$output" \
      --acr-name "testacr" \
      grc-ai-portal; then
    fail "ACR lookup errors should stop publication"
  fi

  [[ ! -f "$case_dir/pushed" ]] || fail "image was pushed after an ACR lookup error"
}

test_lock_contention_preserves_owner_lock() {
  local case_dir="$TMP_ROOT/lock"
  local workspace="$case_dir/workspace"
  local output="$case_dir/output"
  local mocks="$case_dir/bin"
  mkdir -p "$workspace/repositories/grc-ai-portal/.git" \
    "$workspace/scripts" \
    "$workspace/.publish-to-acr.lock" \
    "$output"
  create_mocks "$mocks"

  if PATH="$mocks:$PATH" MOCK_STATE_DIR="$case_dir" \
    bash "$PUBLISH_SCRIPT" \
      --workspace-root "$workspace" \
      --output-dir "$output" \
      --acr-name "testacr" \
      grc-ai-portal; then
    fail "lock contention should be rejected"
  fi

  [[ -d "$workspace/.publish-to-acr.lock" ]] ||
    fail "contending process removed the owner lock"
}

test_publishes_commit_tag_and_manifest
test_rejects_dirty_repository
test_rejects_existing_immutable_tag_without_push
test_unlabeled_image_uses_image_id_tag
test_rejects_acr_lookup_errors
test_lock_contention_preserves_owner_lock

echo "publish-to-acr tests passed"
