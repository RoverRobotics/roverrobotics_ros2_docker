# set -euo pipefail

# IMAGE="${1:-rover-jazzy:latest}"
# NAME="${CONTAINER_NAME:-rover-jazzy-con}"
# ROS_DOMAIN_ID="${ROS_DOMAIN_ID:-42}"
# CONTAINER_USER="${CONTAINER_USER:-ubuntu}"

# HOST_HOME="${HOME}"
# CONTAINER_HOME="/home/ubuntu"

# RUNTIME_ARGS=()
# if docker info 2>/dev/null | grep -qi 'Runtimes:.*nvidia'; then
#   RUNTIME_ARGS=( --runtime nvidia )
# fi

# exec docker run --rm -it \
#   --name "$NAME" \
#   --privileged \
#   --cgroupns=host \
#   --network=host \
#   --ipc=host \
#   -v /sys/fs/cgroup:/sys/fs/cgroup:rw \
#   -v /dev:/dev \
#   -v /run/udev:/run/udev:ro \
#   -v /etc/udev:/etc/udev:ro \
#   -v "${HOST_HOME}:${CONTAINER_HOME}" \
#   -e ROS_DOMAIN_ID="$ROS_DOMAIN_ID" \
#   "${RUNTIME_ARGS[@]}" \
#   "$IMAGE" \
#   /lib/systemd/systemd


#!/bin/bash

# --- Config ---
IMAGE="${1:-rover-jazzy:latest}"
NAME="${CONTAINER_NAME:-rover-jazzy-con}"

# This will get overridden by systemd Environment=ROS_DOMAIN_ID=48
ROS_DOMAIN_ID="${ROS_DOMAIN_ID:-42}"

# We hardcode host home so it works even if service runs as root
# HOST_HOME="/home/rover"
HOST_HOME="${HOST_HOME:-$HOME}"
CONTAINER_HOME="/home/ubuntu"

RUNTIME_ARGS=()

# Try to enable nvidia runtime if available, but NEVER fail if this check fails
if docker info >/dev/null 2>&1; then
  if docker info 2>/dev/null | grep -qi 'Runtimes:.*nvidia'; then
    RUNTIME_ARGS+=( --runtime nvidia )
  fi
fi

# For systemd: NO -it (TTY), just attach normally
exec /usr/bin/docker run --rm \
  --name "$NAME" \
  --privileged \
  --cgroupns=host \
  --network=host \
  --ipc=host \
  -v /sys/fs/cgroup:/sys/fs/cgroup:rw \
  -v /dev:/dev \
  -v /run/udev:/run/udev:ro \
  -v /etc/udev:/etc/udev:ro \
  -v "${HOST_HOME}:${CONTAINER_HOME}" \
  -e DISPLAY=$DISPLAY \
  -e QT_X11_NO_MITSHM=1 \
  -v /tmp/.X11-unix:/tmp/.X11-unix \
  -v "$HOME/.Xauthority:/home/ubuntu/.Xauthority:ro" \
  -e ROS_DOMAIN_ID="$ROS_DOMAIN_ID" \
  "${RUNTIME_ARGS[@]}" \
  "$IMAGE" \
  /lib/systemd/systemd

