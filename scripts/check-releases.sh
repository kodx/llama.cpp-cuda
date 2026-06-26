#!/bin/bash

set -euo pipefail

REPO="${REPO:-kodx/llama.cpp-cuda}"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}llama.cpp-cuda Release Checker${NC}"
echo "================================"
echo ""

UPSTREAM_API="https://api.github.com/repos/ggml-org/llama.cpp/releases/latest"

echo "Checking llama.cpp repository..."
UPSTREAM_JSON=$(curl -s --fail "$UPSTREAM_API")
UPSTREAM_RELEASE=$(echo "$UPSTREAM_JSON" | jq -r '.tag_name')
UPSTREAM_DATE=$(echo "$UPSTREAM_JSON" | jq -r '.published_at')

echo -e "Latest upstream release: ${GREEN}$UPSTREAM_RELEASE${NC}"
echo "Published: $UPSTREAM_DATE"
echo ""

OUR_API="https://api.github.com/repos/$REPO/releases/latest"

echo "Checking $REPO repository..."
OUR_JSON=$(curl -s --fail "$OUR_API" 2>/dev/null || echo "")
OUR_RELEASE=$(echo "$OUR_JSON" | jq -r '.tag_name // "none"' 2>/dev/null || echo "none")

if [ "$OUR_RELEASE" = "none" ] || [ -z "$OUR_RELEASE" ]; then
    echo -e "${RED}No releases found in $REPO${NC}"
    echo -e "${YELLOW}A new build should be triggered!${NC}"
    exit 0
fi

OUR_DATE=$(echo "$OUR_JSON" | jq -r '.published_at')

echo -e "Latest CUDA build: ${GREEN}$OUR_RELEASE${NC}"
echo "Published: $OUR_DATE"
echo ""

if [ "$UPSTREAM_RELEASE" = "$OUR_RELEASE" ]; then
    echo -e "${GREEN}✓ Up to date!${NC}"
    echo "The latest llama.cpp release has been built with CUDA support."
else
    echo -e "${YELLOW}⚠ Update available!${NC}"
    echo "llama.cpp has released $UPSTREAM_RELEASE but we only have $OUR_RELEASE"
    echo ""
    echo "A new build should be triggered automatically within 24 hours."
    echo "Or manually trigger: https://github.com/$REPO/actions"
fi

echo ""
echo "Links:"
echo "  Upstream: https://github.com/ggml-org/llama.cpp/releases/tag/$UPSTREAM_RELEASE"
if [ "$OUR_RELEASE" != "none" ]; then
    echo "  Our build: https://github.com/$REPO/releases/tag/$OUR_RELEASE"
fi
