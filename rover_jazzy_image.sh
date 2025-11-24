#!/usr/bin/env bash
set -euo pipefail
TAG="${1:-rover-jazzy:latest}"
docker pull ros:jazzy-ros-base-noble
docker build -t "$TAG" -f Dockerfile .
echo "✅ Built image: $TAG"

