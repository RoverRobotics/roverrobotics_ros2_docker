#!/usr/bin/env bash
set -euo pipefail
TAG="${1:-rover-jazzy:latest}"
docker pull arm64v8/ros:jazzy-ros-base-noble
docker build -t "$TAG" -f Dockerfile .
echo "✅ Built image: $TAG"

