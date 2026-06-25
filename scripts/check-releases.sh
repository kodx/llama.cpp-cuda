#!/bin/bash

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}llama.cpp-cuda Release Checker${NC}"
echo "================================"
echo ""

# Get latest upstream release
echo "Checking llama.cpp repository..."
UPSTREAM_RELEASE=$(curl -s https://api.github.com/repos/ggml-org/llama.cpp/releases/latest | jq -r '.tag_name')
UPSTREAM_DATE=$(curl -s https://api.github.com/repos/ggml-org/llama.cpp/releases/latest | jq -r '.published_at')

echo -e "Latest upstream release: ${GREEN}$UPSTREAM_RELEASE${NC}"
echo "Published: $UPSTREAM_DATE"
echo ""

# Get latest release from this repo
echo "Checking kodx/llama.cpp-cuda repository..."
OUR_RELEASE=$(curl -s https://api.github.com/repos/kodx/llama.cpp-cuda/releases/latest | jq -r '.tag_name // "none"' 2>/dev/null || echo "none")

if [ "$OUR_RELEASE" = "none" ] || [ -z "$OUR_RELEASE" ]; then
    echo -e "${RED}No releases found in kodx/llama.cpp-cuda${NC}"
    echo -e "${YELLOW}A new build should be triggered!${NC}"
    exit 0
fi

OUR_DATE=$(curl -s https://api.github.com/repos/kodx/llama.cpp-cuda/releases/latest | jq -r '.published_at')

echo -e "Latest CUDA build: ${GREEN}$OUR_RELEASE${NC}"
echo "Published: $OUR_DATE"
echo ""

# Compare versions
if [ "$UPSTREAM_RELEASE" = "$OUR_RELEASE" ]; then
    echo -e "${GREEN}✓ Up to date!${NC}"
    echo "The latest llama.cpp release has been built with CUDA support."
else
    echo -e "${YELLOW}⚠ Update available!${NC}"
    echo "llama.cpp has released $UPSTREAM_RELEASE but we only have $OUR_RELEASE"
    echo ""
    echo "A new build should be triggered automatically within 24 hours."
    echo "Or manually trigger: https://github.com/kodx/llama.cpp-cuda/actions"
fi

echo ""
echo "Links:"
echo "  Upstream: https://github.com/ggml-org/llama.cpp/releases/tag/$UPSTREAM_RELEASE"
if [ "$OUR_RELEASE" != "none" ]; then
    echo "  Our build: https://github.com/kodx/llama.cpp-cuda/releases/tag/$OUR_RELEASE"
fi
