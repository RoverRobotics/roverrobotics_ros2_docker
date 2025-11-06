FROM arm64v8/ros:jazzy-ros-base-noble

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    systemd systemd-sysv dbus udev \
    sudo bash-completion \
    nano git net-tools \
    build-essential cmake \
    python3-pip python3-colcon-common-extensions python3-rosdep python3-vcstool \
    gstreamer1.0-tools gstreamer1.0-plugins-base gstreamer1.0-plugins-good gstreamer1.0-plugins-bad \
    v4l-utils \
    iproute2 can-utils \
    ros-${ROS_DISTRO}-slam-toolbox \
    ros-${ROS_DISTRO}-navigation2 \
    ros-${ROS_DISTRO}-nav2-bringup \
    ros-${ROS_DISTRO}-robot-localization \
    ros-${ROS_DISTRO}-robot-state-publisher \
    ros-${ROS_DISTRO}-joint-state-publisher \
    ros-${ROS_DISTRO}-xacro \
    ros-${ROS_DISTRO}-joy-linux \
    python3-serial python3-smbus \
 && rm -rf /var/lib/apt/lists/*

RUN rosdep init || true

ENV ROS_DOMAIN_ID=42

RUN echo 'source /opt/ros/jazzy/setup.bash' >> /etc/bash.bashrc && \
    echo 'export ROS_DOMAIN_ID=${ROS_DOMAIN_ID}' >> /etc/bash.bashrc &&\
    echo 'source /home/ubuntu/rover_workspace/install/setup.bash' >> /etc/bash.bashrc

RUN printf '%s\n' '#!/usr/bin/env bash' \
    'set -eo pipefail' \
    'set +u' \
    'source /opt/ros/jazzy/setup.bash' \
    'source /home/ubuntu/rover_workspace/install/setup.bash' \
    'set -u' \
    'exec ros2 launch roverrobotics_driver max_teleop.launch.py' \
    'PID=\$!' \
    'wait "\$PID"' \
    > /usr/sbin/roverrobotics && chmod +x /usr/sbin/roverrobotics && chown ubuntu:ubuntu /usr/sbin/roverrobotics

RUN printf '%s\n' \
    '[Service]' \
    'Type=simple' \
    'User=ubuntu' \
    'ExecStart=/usr/sbin/roverrobotics' \
    '' \
    '[Install]' \
    'WantedBy=multi-user.target' \
    > /etc/systemd/system/roverrobotics.service

RUN printf '%s\n' '#!/usr/bin/env bash' \
    'set -euo pipefail' \
    'ip link set can2 type can bitrate 500000' \
    'ip link set up can2' \
    > /usr/sbin/enablecan && chmod +x /usr/sbin/enablecan && chown ubuntu:ubuntu /usr/sbin/enablecan

RUN printf '%s\n' \
    'Description=Bring up CAN2' \
    'After=network.target' \
    '[Service]' \
    'Type=oneshot' \
    'User=ubuntu' \
    'CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_RAW' \
    'AmbientCapabilities=CAP_NET_ADMIN CAP_NET_RAW' \
    'NoNewPrivileges=no' \
    'ExecStart=/usr/sbin/enablecan' \
    'RemainAfterExit=yes' \
    '' \
    '[Install]' \
    'WantedBy=multi-user.target' \
    > /etc/systemd/system/can.service

RUN ln -s /etc/systemd/system/roverrobotics.service \
    /etc/systemd/system/multi-user.target.wants/roverrobotics.service

RUN ln -s /etc/systemd/system/can.service \
    /etc/systemd/system/multi-user.target.wants/can.service

RUN ln -s /dev/null /etc/systemd/system/getty@tty1.service && \
    ln -s /dev/null /etc/systemd/system/console-getty.service

STOPSIGNAL SIGRTMIN+3
CMD ["/lib/systemd/systemd"]
