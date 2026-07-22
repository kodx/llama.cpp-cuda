# llama.cpp-cuda

Build scripts repo (no application code). Builds [llama.cpp](https://github.com/ggml-org/llama.cpp) with CUDA in Docker, publishes binaries as GitHub releases.

## CI workflows

| Workflow | Trigger | Purpose |
|----------|---------|---------|
| `build.yml` | Daily 00:00 UTC, manual | Build llama.cpp for CUDA 12.9 + 13.3, amd64 + arm64. Creates release with 4 tarballs. |
| `runtime.yml` | Manual only | Publish CUDA runtime (`libcudart`, `libcublas`, `libcublasLt`, `libnccl`) as standalone `llama-cpp-cuda*-runtime` release via NVIDIA CUDA Redist + NCCL redist. |
| `lint.yml` | Push/PR to main | actionlint + shellcheck on workflows and `scripts/*.sh` |

## Pre-commit hook (`.githooks/pre-commit`)

Enable with: `git config core.hooksPath .githooks`

Runs `actionlint` on changed `.yml` and `shellcheck --shell=bash` on changed `.sh`. Hook exits 0 if no matching files changed.

## Commands

```bash
# Local test builds (requires CUDA Docker image, ~30 min, outputs to binaries/ + archives/)
./scripts/test-build.sh 12.9.2
./scripts/test-build.sh 13.3.0

# Local test CUDA runtime packaging (downloads ~1.4GB, outputs to binaries/ + archives/)
./scripts/test-runtime.sh 12.9.2
./scripts/test-runtime.sh 13.3.0

# Debug: check which llama.cpp releases are already built
./scripts/check-releases.sh

# Lint all files locally
actionlint .github/workflows/*.yml
shellcheck --shell=bash scripts/*.sh
```

## Repo quirks & conventions

- **Commit style**: `<prefix>: <short description>` with optional body paragraph (e.g. `ci:`, `feat:`, `fix:`, `docs:`). All text in English.
- **No commits or pushes without explicit approval.** Always show the commit message first and wait for confirmation (e.g. "apply", "commit", "yes"). Never push unless the user explicitly asks to push.
- **CUDA Redist manifests**: ARM arch key changed in CUDA 13.x from `linux-aarch64` to `linux-sbsa`. Always use jq fallback:
  ```bash
  REL=$(jq -r --arg pkg "$pkg" --arg arch "$ARCH" '.[$pkg][$arch].relative_path // empty')
  [ -z "$REL" ] && REL=$(jq -r --arg pkg "$pkg" --arg arch "linux-sbsa" '.[$pkg][$arch].relative_path // empty')
  ```
- **jq + hyphens**: Always use `--arg` + bracket notation (`.[$key]`) instead of dot notation (`.key`) when keys contain hyphens like `linux-x86_64`.
- **`run-name:`** in `runtime.yml` displays CUDA version in Actions UI.
- **RUNPATH** is `$ORIGIN:$ORIGIN/../llama-cpp-cuda$SHORT-runtime`. CUDA runtime tarballs are extracted alongside or as sibling to `llama-cpp-cuda$SHORT/` directory.
- **`.gitignore`** intentionally broad: `binaries/`, `artifacts/`, `*.tar.gz`.
- **`ubuntu-slim`** runner is a valid custom runner.
- **Cleanup** in `build.yml` excludes `llama-cpp-cuda*-runtime` releases from deletion.
- **Smoke test** checks only 3 binaries: `llama-cli`, `llama-server`, `llama-bench`.
- **NCCL source**: downloaded from `https://developer.download.nvidia.com/compute/redist/nccl/` (separate from CUDA Redist). File pattern: `nccl_<ver>-1+cuda<short>_<arch>.txz` where arch is `x86_64`/`aarch64`. Format `.txz` = tar.xz (`tar -xJf`).
- **NCCL version**: `2.30.7` supports both CUDA 12.9 and 13.3. Different packages per CUDA version (`+cuda12.9` / `+cuda13.3`) but same NCCL version. ARM arch is always `aarch64` (no `linux-sbsa` distinction).
