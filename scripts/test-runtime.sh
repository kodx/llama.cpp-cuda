#!/usr/bin/env bash
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

if [ -z "${1:-}" ] || [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
  echo "Usage: $0 CUDA_VERSION"
  echo ""
  echo "Download and package CUDA runtime libraries from NVIDIA CUDA Redist + NCCL."
  echo ""
  echo "  CUDA_VERSION  CUDA version to package"
  echo "                Supported: 12.9.2, 13.3.0"
  echo ""
  echo "Examples:"
  echo "  $0 12.9.2          # package CUDA 12.9 runtime"
  echo "  $0 13.3.0          # package CUDA 13.3 runtime"
  exit 1
fi
CUDA_VERSION="$1"

echo -e "${GREEN}CUDA Runtime Packaging Test${NC}"
echo "================================"
echo "CUDA Version: $CUDA_VERSION"
echo ""

case $CUDA_VERSION in
    12.9.2)
        ;;
    13.3.0)
        ;;
    *)
        echo -e "${RED}Error: Unsupported CUDA version $CUDA_VERSION${NC}"
        echo "Supported versions: 12.9.2, 13.3.0"
        exit 1
        ;;
esac

CUDA_SHORT="${CUDA_VERSION%.*}"
ARCH_NAME="amd64"
LINUX_ARCH="linux-x86_64"

mkdir -p binaries archives downloads
cd downloads

MANIFEST="redistrib_${CUDA_VERSION}.json"
wget "https://developer.download.nvidia.com/compute/cuda/redist/$MANIFEST"

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
  find "$tmpdir" -name '*.so*' ! -path '*/stubs/*' -exec cp -a {} "runtime-${ARCH_NAME}/" \;
  rm -rf "$tmpdir"
done

# Download NCCL matching CUDA version
NCCL_VERSION="2.30.7"
NCCL_URL="https://developer.download.nvidia.com/compute/redist/nccl/v${NCCL_VERSION}/nccl_${NCCL_VERSION}-1+cuda${CUDA_SHORT}_x86_64.txz"
echo "Downloading $NCCL_URL ..."
wget "$NCCL_URL"
tmpdir=$(mktemp -d)
tar -xJf "$(basename "$NCCL_URL")" -C "$tmpdir"
find "$tmpdir" -name '*.so*' -exec cp -a {} "runtime-${ARCH_NAME}/" \;
rm -rf "$tmpdir"

mkdir -p "cuda-runtime-${CUDA_SHORT}"
cp -a ./runtime-"${ARCH_NAME}"/*.so* "cuda-runtime-${CUDA_SHORT}/"
cd "cuda-runtime-${CUDA_SHORT}"
for f in *.so.*; do
  base="${f%.so.*}.so"
  [ ! -e "$base" ] && ln -s "$f" "$base"
done
chmod 755 ./*.so*
echo "CUDA_VERSION=${CUDA_VERSION}" > VERSION.txt
cd ..
tar -czf "../archives/cuda-runtime-${CUDA_SHORT}-${ARCH_NAME}.tar.gz" "cuda-runtime-${CUDA_SHORT}"
cp -a "cuda-runtime-${CUDA_SHORT}" ../binaries/
rm -rf "cuda-runtime-${CUDA_SHORT}" "runtime-${ARCH_NAME}"

cd ..
rm -rf downloads

echo ""
echo -e "${GREEN}✓ CUDA Runtime packaging complete!${NC}"
echo "Binaries location: binaries/cuda-runtime-${CUDA_SHORT}/"
echo "Archives location: archives/"
ls -lh archives/
