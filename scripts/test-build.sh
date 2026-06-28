#!/bin/bash

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

if [ -z "${1:-}" ] || [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
  echo "Usage: $0 CUDA_VERSION [LLAMA_TAG]"
  echo ""
  echo "Build llama.cpp with CUDA in a Docker container."
  echo ""
  echo "  CUDA_VERSION  CUDA version to build against"
  echo "                Supported: 12.9.2, 13.3.0"
  echo "  LLAMA_TAG     llama.cpp git tag to build (default: latest)"
  echo "                Example: b9784, b9500, latest"
  echo ""
  echo "Examples:"
  echo "  $0 12.9.2          # build CUDA 12.9 with latest llama.cpp"
  echo "  $0 13.3.0          # build CUDA 13.3 with latest llama.cpp"
  echo "  $0 12.9.2 b9500    # build CUDA 12.9 with a specific tag"
  exit 1
fi
CUDA_VERSION="$1"
LLAMA_TAG="${2:-latest}"

echo -e "${GREEN}llama.cpp CUDA Build Test${NC}"
echo "================================"
echo "CUDA Version: $CUDA_VERSION"
echo "llama.cpp Tag: $LLAMA_TAG"
echo ""

case $CUDA_VERSION in
    12.9.2)
        CUDA_TAG="12.9.2-cudnn-devel-ubuntu24.04"
        ARCHITECTURES="60;61;62;70;72"
        ;;
    13.3.0)
        CUDA_TAG="13.3.0-cudnn-devel-ubuntu24.04"
        ARCHITECTURES="75;80;86;89;90;100;103;110;120;121"
        ;;
    *)
        echo -e "${RED}Error: Unsupported CUDA version $CUDA_VERSION${NC}"
        echo "Supported versions: 12.9.2, 13.3.0"
        exit 1
        ;;
esac

CUDA_MAJOR="${CUDA_VERSION%%.*}"

if [ "$LLAMA_TAG" = "latest" ]; then
    echo -e "${YELLOW}Fetching latest llama.cpp release...${NC}"
    LLAMA_TAG=$(curl -s --fail https://api.github.com/repos/ggml-org/llama.cpp/releases/latest | jq -r '.tag_name')
    RELEASE_HASH=$(curl -s --fail https://api.github.com/repos/ggml-org/llama.cpp/releases/latest | jq -r '.target_commitish')
    echo "Latest release: $LLAMA_TAG (${RELEASE_HASH:0:8})"
else
    RELEASE_HASH=$(curl -s --fail "https://api.github.com/repos/ggml-org/llama.cpp/git/refs/tags/$LLAMA_TAG" | jq -r '.object.sha')
fi

echo ""
echo -e "${YELLOW}Building with:${NC}"
echo "  Docker Image: nvidia/cuda:$CUDA_TAG"
echo "  Architectures: $ARCHITECTURES"
echo ""

mkdir -p binaries archives

echo -e "${GREEN}Starting Docker build...${NC}"
docker run --rm -v "$PWD":/workspace \
    nvidia/cuda:$CUDA_TAG \
    bash -c "
        set -e
        echo '=> Installing dependencies...'
        apt-get update -qq
        apt-get install -y --no-install-recommends git cmake ninja-build build-essential libssl-dev ca-certificates gcc-14 g++-14
        apt-get clean
        rm -rf /var/lib/apt/lists/*

        echo '=> Cloning llama.cpp...'
        cd /workspace
        if [ -d llama.cpp ] && [ -n \"\$(ls -A llama.cpp 2>/dev/null)\" ]; then rm -rf llama.cpp; fi
        git clone --depth 1 --branch $LLAMA_TAG https://github.com/ggml-org/llama.cpp.git || \
          (git clone https://github.com/ggml-org/llama.cpp.git && cd llama.cpp && git checkout $RELEASE_HASH)
        cd llama.cpp

        echo '=> Configuring build with Ninja...'
        export LIBRARY_PATH=\"/usr/local/cuda/lib64/stubs\${LIBRARY_PATH:+:\$LIBRARY_PATH}\"
        ln -sf /usr/local/cuda/lib64/stubs/libcuda.so /usr/local/cuda/lib64/stubs/libcuda.so.1

        export CC=/usr/bin/gcc-14 CXX=/usr/bin/g++-14

        cmake -B build -S . \
            -G Ninja \
            -DGGML_CUDA=ON \
            -DCMAKE_CUDA_ARCHITECTURES='$ARCHITECTURES' \
            -DCMAKE_BUILD_TYPE=Release \
            -DGGML_NATIVE=OFF \
            -DGGML_BACKEND_DL=ON \
            -DGGML_CPU_ALL_VARIANTS=ON \
            -DLLAMA_BUILD_TESTS=OFF \
            -DLLAMA_BUILD_EXAMPLES=OFF \
            -DCMAKE_INSTALL_RPATH='\$ORIGIN:\$ORIGIN/../llama-cpp-cuda${CUDA_MAJOR}-runtime:\$ORIGIN/../lib/llama-cpp-cuda${CUDA_MAJOR}-runtime' \
            -DCMAKE_BUILD_WITH_INSTALL_RPATH=ON \
            -DCMAKE_EXE_LINKER_FLAGS='-Wl,-rpath-link,/usr/local/cuda/lib64/stubs' \
            -DCMAKE_SHARED_LINKER_FLAGS='-Wl,-rpath-link,/usr/local/cuda/lib64/stubs' \
            -DCMAKE_CUDA_FLAGS=-Wno-deprecated-gpu-targets

        echo '=> Building with Ninja (parallel: all cores)...'
        cmake --build build --config Release -j\$(nproc)

        echo '=> Copying binaries...'
        cd /workspace
        mkdir -p binaries/llama-cpp-cuda${CUDA_MAJOR}

        cp -r llama.cpp/build/bin/* binaries/llama-cpp-cuda${CUDA_MAJOR}/

        if [ -d llama.cpp/build/lib ]; then
          find llama.cpp/build/lib -name '*.so*' -exec cp {} binaries/llama-cpp-cuda${CUDA_MAJOR}/ \; 2>/dev/null || true
        fi

        find binaries/llama-cpp-cuda${CUDA_MAJOR}/ -type f -executable ! -name '*.so*' -exec strip {} \; 2>/dev/null || true

        cd /workspace
        echo '=> Creating version info...'
        cat > binaries/llama-cpp-cuda${CUDA_MAJOR}/VERSION.txt << EOFBUILD
llama.cpp version: $LLAMA_TAG
CUDA version: $CUDA_VERSION
CUDA major: $CUDA_MAJOR
Architectures: $ARCHITECTURES
Build date: \$(date -u +%Y-%m-%d)
Build hash: $RELEASE_HASH
EOFBUILD

        echo '=> Build complete!'
        ls -lh binaries/llama-cpp-cuda${CUDA_MAJOR}/
    "
echo ""
echo -e "${GREEN}Creating tarball...${NC}"
tar -czf "archives/llama-cpp-${LLAMA_TAG}-cuda${CUDA_MAJOR}.tar.gz" -C binaries "llama-cpp-cuda${CUDA_MAJOR}"

echo ""
echo -e "${GREEN}✓ Build successful!${NC}"
echo ""
echo "Binaries location: binaries/llama-cpp-cuda${CUDA_MAJOR}/"
echo "Archives location: archives/"

echo ""
echo "Built binaries:"
ls -lh "binaries/llama-cpp-cuda${CUDA_MAJOR}/"


echo ""
echo -e "${GREEN}Test build complete!${NC}"
