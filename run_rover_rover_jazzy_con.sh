set -euo pipefail

IMAGE="${1:-rover-jazzy:latest}"
NAME="${CONTAINER_NAME:-rover-jazzy-con}"
ROS_DOMAIN_ID="${ROS_DOMAIN_ID:-42}"
CONTAINER_USER="${CONTAINER_USER:-ubuntu}"

HOST_HOME="${HOME}"
CONTAINER_HOME="/home/ubuntu"

RUNTIME_ARGS=()
if docker info 2>/dev/null | grep -qi 'Runtimes:.*nvidia'; then
  RUNTIME_ARGS=( --runtime nvidia )
fi

exec docker run --rm -it \
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
  -e ROS_DOMAIN_ID="$ROS_DOMAIN_ID" \
  "${RUNTIME_ARGS[@]}" \
  "$IMAGE" \
  /lib/systemd/systemd

