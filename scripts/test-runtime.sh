#!/usr/bin/env bash
set -euo pipefail

CUDA_VERSION="${1:-12.9.2}"
CUDA_SHORT="${CUDA_VERSION%.*}"
MANIFEST="redistrib_${CUDA_VERSION}.json"

wget "https://developer.download.nvidia.com/compute/cuda/redist/$MANIFEST"

for arch_pair in "amd64:linux-x86_64" "arm64:linux-aarch64"; do
  ARCH_NAME="${arch_pair%%:*}"
  LINUX_ARCH="${arch_pair##*:}"

  mkdir -p "runtime-${ARCH_NAME}"

  for pkg in cuda_cudart libcublas; do
    REL=$(jq -r --arg pkg "$pkg" --arg arch "${LINUX_ARCH}" \
      '.[$pkg][$arch].relative_path // empty' "$MANIFEST")
    if [ -z "$REL" ]; then
      REL=$(jq -r --arg pkg "$pkg" --arg arch "linux-sbsa" \
        '.[$pkg][$arch].relative_path // empty' "$MANIFEST")
    fi
    echo "Downloading $REL ..."
    wget "https://developer.download.nvidia.com/compute/cuda/redist/$REL"

    tmpdir=$(mktemp -d)
    tar -xJf "$(basename "$REL")" -C "$tmpdir"
    find "$tmpdir" -name '*.so*' -exec cp -L {} "runtime-${ARCH_NAME}/" \;
    rm -rf "$tmpdir"
  done

  mkdir -p "cuda-runtime-${CUDA_SHORT}"
  cp ./runtime-"${ARCH_NAME}"/*.so* "cuda-runtime-${CUDA_SHORT}/"
  tar -czf "cuda-runtime-${CUDA_SHORT}-${ARCH_NAME}.tar.gz" "cuda-runtime-${CUDA_SHORT}"
  rm -rf "cuda-runtime-${CUDA_SHORT}" "runtime-${ARCH_NAME}"
done

ls -lh cuda-runtime-*.tar.gz
echo "All tarballs created successfully."
