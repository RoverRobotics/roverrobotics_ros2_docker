#!/usr/bin/env bash
###############################################################################
# Script Name : Rover Jazzy Docker Host Install Script                        #
# Description : Host-side setup for Rover Robotics Jazzy Docker setup         #
#               - udev rules                                                  #
#               - rover_workspace/src (roverrobotics_ros2, IMU, LiDAR, GPS)   #
#               - rover_jazzy_docker.service                                  #
#               - patch Dockerfile roverrobotics.service based on robot type  #
#               - optionally run rover_jazzy_image.sh                         #
###############################################################################

set -euo pipefail

###############################################################################
#                              CONFIG                                         #
###############################################################################

ROVER_REPO=https://github.com/RoverRobotics/roverrobotics_ros2.git
IMU_REPO=https://github.com/flynneva/bno055.git
RPLIDAR_REPO=https://github.com/Slamtec/rplidar_ros.git
UBLOX_REPO=https://github.com/KumarRobotics/ublox.git

WORKSPACE_NAME=rover_workspace
CURRENT_DIR=${PWD}
BASEDIR=$CURRENT_DIR
WORKSPACE_DIR="$HOME/$WORKSPACE_NAME"
ROVER_ROS2_DIR="$WORKSPACE_DIR/src/roverrobotics_ros2"

# Default Dockerfile and image build script paths
DEFAULT_DOCKERFILE="./Dockerfile"
DEFAULT_IMAGE_SCRIPT="./rover_jazzy_image.sh"

# Service user/group = current user running this script (NOT root)
SERVICE_USER="${USER}"

###############################################################################
#                          HELPER FUNCTIONS                                   #
###############################################################################
RED="\e[31m"
GREEN="\e[32m"
BOLD="\e[1m"
ITALICBLUE="\e[3;94m"
BOLDBLUE="\e[1;94m"
ENDCOLOR="\e[0m"

print_red()   { echo -e "${RED}${1}${ENDCOLOR}"; }
print_green() { echo -e "${GREEN}${1}${ENDCOLOR}"; }
print_bold()  { echo -e "${BOLD}${1}${ENDCOLOR}"; }
print_italic(){ echo -e "${ITALICBLUE}${1}${ENDCOLOR}"; }
print_boldblue(){ echo -e "${BOLDBLUE}${1}${ENDCOLOR}"; }

ask_yes_no() {
    # Usage: ask_yes_no "Question text" default_yes_or_no result_var_name
    local question="$1"
    local default="$2"   # "yes" or "no"
    local __resultvar="$3"
    local answer

    while true; do
        if [ "$default" = "no" ]; then
            read -p "$question [y/N]: " yn
            yn=${yn:-n}
        else
            read -p "$question [Y/n]: " yn
            yn=${yn:-y}
        fi
        case "$yn" in
            [Yy]* ) answer="yes"; break ;;
            [Nn]* ) answer="no";  break ;;
            * ) echo "Please answer yes or no." ;;
        esac
    done

    if [ "$answer" = "yes" ]; then
        eval "$__resultvar=true"
    else
        eval "$__resultvar=false"
    fi
}

select_robot_type() {
    local choice
    while true; do
        echo "Select Rover Type:"
        echo " 1) Mini 2WD"
        echo " 2) Mini (4WD)"
        echo " 3) Miti 65"
        echo " 4) Miti"
        echo " 5) Zero"
        echo " 6) Pro"
        echo " 7) Max"
        echo " 8) Mega"
        read -p "Enter choice [1-8]: " choice

        case "$choice" in
            1) device_type="mini_2wd"; break ;;
            2) device_type="mini";     break ;;
            3) device_type="miti_65";  break ;;
            4) device_type="miti";     break ;;
            5) device_type="zero";     break ;;
            6) device_type="pro";      break ;;
            7) device_type="max";      break ;;
            8) device_type="mega";     break ;;
            *) echo "Invalid choice." ;;
        esac
    done
}

###############################################################################
#                          START OF SCRIPT                                    #
###############################################################################

clear
print_bold "============================================================="
print_bold "          Rover Jazzy Docker Host Install Script            "
print_bold "============================================================="
echo ""
print_italic "This script will help you set up components for"
print_italic "  - udev rules"
print_italic "  - roverrobotics_ros2, IMU, LiDAR, GPS, RealSense, PS4 controller"
print_italic "  - rover_jazzy_image.sh"
print_italic "  - rover_jazzy_docker.service"
print_italic "  - Dockerfile roverrobotics.service, can.service launch"
echo ""

###############################################################################
#                          ROBOT TYPE & PLATFORM                              #
###############################################################################

device_type=""
select_robot_type
echo ""
print_green "Selected robot type: ${device_type}"
echo ""

# Jetson vs non-Jetson and AGX subtype (used for CAN interface and PS4 config)
is_jetson_device=false
is_jetson_agx=false

ask_yes_no "Is this system a Jetson device" yes is_jetson_device
if [ "$is_jetson_device" = true ]; then
    ask_yes_no "Is this Jetson AGX model?" yes is_jetson_agx
fi

echo ""
print_italic "Jetson device : ${is_jetson_device}"
print_italic "Jetson AGX    : ${is_jetson_agx}"
echo ""

###############################################################################
#                WORKSPACE / LIDAR / IMU / REALSENSE / GPS                    #
###############################################################################

existing_workspace=false
if [ -d "$WORKSPACE_DIR" ]; then
    existing_workspace=true
    print_italic "Detected existing workspace at $WORKSPACE_DIR"
fi

use_workspace=false
if [ "$existing_workspace" = true ]; then
    ask_yes_no "You already have '$WORKSPACE_NAME'. Use it for Rover Robotics Github / IMU / LiDAR / GPS sources?" yes use_workspace
else
    ask_yes_no "No '$WORKSPACE_NAME' found. Create it at '$WORKSPACE_DIR' and use it for sources?" yes use_workspace
fi

install_rover_repo=false
install_imu=false
install_lidar=false
install_realsense=false
install_gps=false

if [ "$use_workspace" = true ]; then
    mkdir -p "$WORKSPACE_DIR/src"

    # Ask SEPARATELY for each:
    ask_yes_no "Do you want to install/update the Rover Robotics Github?" yes install_rover_repo
    ask_yes_no "Do you want to install/update the packages for RPLIDAR S2 (LiDAR)?" no install_lidar
    ask_yes_no "Do you want to install/update the packages for BNO055 (IMU)?" no install_imu
    ask_yes_no "Do you want to install/update the packages for ZED-F9P (GPS)?" no install_gps
    ask_yes_no "Do you want to install/update the packages for INTEL REALSENSE (CAMERA)?" yes install_realsense

    echo ""
    print_italic "Cloning selections:"
    print_italic "  roverrobotics_ros2 (GitHub): $install_rover_repo"
    print_italic "  RPLIDAR S2 (LiDAR)        : $install_lidar"
    print_italic "  BNO055 (IMU)              : $install_imu"
    print_italic "  ZED-F9P (GPS)             : $install_gps"
    print_italic "  INTEL REALSENSE (CAMERA)  : $install_realsense"
    echo ""

    # roverrobotics_ros2
    if [ "$install_rover_repo" = true ]; then
        print_boldblue "Setting up roverrobotics_ros2 in $WORKSPACE_DIR/src ..."
        cd "$WORKSPACE_DIR/src"
        if [ -d "roverrobotics_ros2" ]; then
            print_italic "Removing existing roverrobotics_ros2 directory before cloning..."
            rm -rf roverrobotics_ros2
        fi
        git clone -b jazzy "$ROVER_REPO"
        print_green "Done cloning roverrobotics_ros2."

        # PS4 controller config: reference logic
        # Repo default: ps4_controller_config.yaml (generic)
        # Jetson needs: ps4_controller_config_jp6.yaml contents
        if [ "$is_jetson_device" = true ]; then
            print_italic "Jetson platform detected -> using ps4_controller_config_jp6.yaml for PS4."

            cfg_dir="$WORKSPACE_DIR/src/roverrobotics_ros2/roverrobotics_driver/config"
            if [ -d "$cfg_dir" ]; then
                cd "$cfg_dir"

                if [ -f "ps4_controller_config_jp6.yaml" ]; then
                    # Idempotent: always copy jp6 variant over the default name
                    cp ps4_controller_config_jp6.yaml ps4_controller_config.yaml
                    echo "Copied ps4_controller_config_jp6.yaml to ps4_controller_config.yaml (Jetson PS4 config)."
                else
                    echo "ps4_controller_config_jp6.yaml not found; leaving existing ps4_controller_config.yaml."
                fi

                cd "$BASEDIR"
            else
                print_red "Config directory not found for PS4 controller: $cfg_dir"
            fi
        else
            print_italic "Non-Jetson platform: using default ps4_controller_config.yaml from repo (no changes)."
        fi
    fi

    # LiDAR
    if [ "$install_lidar" = true ]; then
        print_boldblue "Cloning RPLIDAR S2 (LiDAR) repo into $WORKSPACE_DIR/src ..."
        cd "$WORKSPACE_DIR/src"
        if [ -d "rplidar_ros" ]; then
            print_italic "Removing existing RPLIDAR S2 (LiDAR) directory before cloning..."
            rm -rf rplidar_ros
        fi
        git clone -b ros2 "$RPLIDAR_REPO"
        print_green "Done cloning RPLIDAR S2 (LiDAR) repo."
    fi

    # IMU
    if [ "$install_imu" = true ]; then
        print_boldblue "Cloning BNO055 (IMU) repo into $WORKSPACE_DIR/src ..."
        cd "$WORKSPACE_DIR/src"
        if [ -d "bno055" ]; then
            print_italic "Removing existing BNO055 (IMU) directory before cloning..."
            rm -rf bno055
        fi
        git clone "$IMU_REPO"
        print_green "Done cloning BNO055 (IMU) repo."
    fi

    # GPS (ZED-F9P)
    if [ "$install_gps" = true ]; then
        print_boldblue "Cloning ZED-F9P (GPS) repo into $WORKSPACE_DIR/src ..."
        cd "$WORKSPACE_DIR/src"
        if [ -d "ublox" ]; then
            print_italic "Removing existing ZED-F9P (GPS) directory before cloning..."
            rm -rf ublox
        fi
        git clone -b ros2 "$UBLOX_REPO"
        print_green "Done cloning ZED-F9P (GPS) repo."
    fi

    cd "$BASEDIR"
else
    print_italic "Skipping rover_workspace setup / cloning."
fi

###############################################################################
#                         UDEV RULES (HOST)                                   #
###############################################################################

install_udev=false
ask_yes_no "Install Rover Robotics udev rules on this host (recommended)?" yes install_udev

if [ "$install_udev" = true ]; then
    RULE_SRC="$BASEDIR/udev/55-roverrobotics.rules"
    RULE_DST="/etc/udev/rules.d/55-roverrobotics.rules"

    if [ ! -f "$RULE_SRC" ]; then
        print_red "udev rules file not found at: $RULE_SRC"
        print_red "Make sure you have udev/55-roverrobotics.rules next to this script."
    else
        print_boldblue "Copying udev rules to $RULE_DST ..."
        sudo cp "$RULE_SRC" "$RULE_DST"
        print_green "Copied udev rules."

        print_italic "Reloading and triggering udev ..."
        sudo udevadm control --reload-rules
        sudo udevadm trigger
        print_green "udev reload/trigger complete (you may still need a reboot in some cases)."
    fi
else
    print_italic "Skipping udev rules installation."
fi

###############################################################################
#     PATCH DOCKERFILE: roverrobotics.service & can.service & RealSense       #
###############################################################################

DOCKERFILE_PATH="$DEFAULT_DOCKERFILE"
dockerfile_patched=false

if [ ! -f "$DOCKERFILE_PATH" ]; then
    print_red "Dockerfile not found at: $DOCKERFILE_PATH"
    print_red "Skipping Dockerfile modification."
else
    dockerfile_patched=true
    print_boldblue "Patching Dockerfile at $DOCKERFILE_PATH ..."

    # 1) Replace any *_teleop.launch.py with <device_type>_teleop.launch.py
    #    (e.g., mini_teleop.launch.py, max_teleop.launch.py, mega_teleop.launch.py, etc.)
    sed -i "s/[A-Za-z0-9_]*_teleop\.launch\.py/${device_type}_teleop.launch.py/g" "$DOCKERFILE_PATH"
    print_green "Updated launch file in Dockerfile to: ${device_type}_teleop.launch.py"

    # 2) CAN interface:
    #    - Jetson AGX -> keep can2
    #    - All others (non-AGX Jetson and non-Jetson) -> can0
    if [ "$is_jetson_device" = true ] && [ "$is_jetson_agx" = true ]; then
        print_italic "Jetson AGX selected -> keeping CAN interface as can2 in Dockerfile."
    else
        print_boldblue "Non-AGX platform -> changing CAN interface can2 -> can0 in Dockerfile ..."
        sed -i 's/can2/can0/g' "$DOCKERFILE_PATH"
        sed -i 's/CAN2/CAN0/g' "$DOCKERFILE_PATH"
        print_green "Updated CAN interface to can0 in Dockerfile."
    fi

    # 3) RealSense librealsense block: comment/uncomment based on install_realsense
    if [ "$install_realsense" = true ]; then
        print_boldblue "Enabling Intel RealSense librealsense install block in Dockerfile ..."

        # Uncomment any line containing libuvc_installation.sh that is commented
        sed -i 's/^[[:space:]]*#[[:space:]]*\(.*libuvc_installation.sh.*\)$/\1/' "$DOCKERFILE_PATH"

        print_green "Intel RealSense RUN block is enabled."
    else
        print_boldblue "Disabling Intel RealSense librealsense install"

        # Comment only lines containing libuvc_installation.sh that are NOT already commented
        sed -i '/libuvc_installation.sh/ { /^[[:space:]]*#/! s/^[[:space:]]*\(.*\)$/# \1/ }' "$DOCKERFILE_PATH"

        print_green "Intel RealSense RUN block is disabled."
    fi

    print_italic "Remember: you must rebuild the Docker image for these changes to take effect."
fi

###############################################################################
#                  OPTIONAL: BUILD THE DOCKER IMAGE                           #
###############################################################################

build_image=false
ask_yes_no "Do you want to build the Jazzy Docker image now (run rover_jazzy_image.sh)?" no build_image

IMAGE_SCRIPT_PATH="$DEFAULT_IMAGE_SCRIPT"

if [ "$build_image" = true ]; then
    if [ ! -f "$IMAGE_SCRIPT_PATH" ]; then
        print_red "Image build script not found at: $IMAGE_SCRIPT_PATH"
        print_red "Cannot build image automatically."
    else
        print_boldblue "Making ${IMAGE_SCRIPT_PATH} executable and running it..."
        chmod +x "$IMAGE_SCRIPT_PATH"
        "$IMAGE_SCRIPT_PATH"
        print_green "rover_jazzy_image.sh execution finished."
    fi
else
    print_italic "Skipping image build step. You can run rover_jazzy_image.sh manually later."
fi

###############################################################################
#                   ROVER JAZZY DOCKER SERVICE (HOST)                        #
###############################################################################

auto_service=false
service_created=false
ask_yes_no "Do you want an automatic service to start the Rover Jazzy Docker container at boot(needed if you want to drive the robot)?" yes auto_service

if [ "$auto_service" = true ]; then
    print_bold "Creating rover_jazzy_docker.service"

    sudo tee /etc/systemd/system/rover_jazzy_docker.service >/dev/null << EOF_SERVICE
[Unit]
Description=Run Rover Robotics Jazzy Container at boot
Requires=docker.service
After=docker.service network-online.target
Wants=network-online.target

[Service]
Type=simple
User=${SERVICE_USER}
Group=${SERVICE_USER}
WorkingDirectory=/home/${SERVICE_USER}
Environment="ROS_DOMAIN_ID=42"
Environment="ROS_AUTOMATIC_DISCOVERY_RANGE=SUBNET"
Environment="DISPLAY=localhost:10.0"
Environment="XAUTHORITY=/home/${SERVICE_USER}/.Xauthority"
ExecStart=/bin/bash ${BASEDIR}/run_rover_rover_jazzy_con.sh
ExecStop=/usr/bin/docker stop rover-jazzy-con
TimeoutStopSec=30
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF_SERVICE

    print_green "Created rover_jazzy_docker.service (User=${SERVICE_USER})."

    sudo systemctl daemon-reload
    sudo systemctl enable rover_jazzy_docker.service
    sudo systemctl restart rover_jazzy_docker.service || print_red "Warning: could not start rover_jazzy_docker.service (Docker or script may not be ready yet)."
    echo ""

    service_created=true
else
    print_italic "Skipping automatic systemd service for Rover Jazzy Docker container."
fi

###############################################################################
#                               SUMMARY                                       #
###############################################################################

echo ""
print_bold "===================== SUMMARY ====================="
print_boldblue "Host user                    : ${SERVICE_USER}"
print_boldblue "Jetson device                : ${is_jetson_device}"
print_boldblue "Jetson AGX                   : ${is_jetson_agx}"
print_boldblue "Robot type                   : ${device_type}"
print_boldblue "Workspace used               : ${use_workspace} (path: $WORKSPACE_DIR)"
print_boldblue "Rover Robotics Github        : ${install_rover_repo}"
print_boldblue "RPLIDAR S2 (LiDAR)           : ${install_lidar}"
print_boldblue "BNO055 (IMU)                 : ${install_imu}"
print_boldblue "ZED-F9P (GPS)                : ${install_gps}"
print_boldblue "Intel RealSense (CAMERA)     : ${install_realsense}"
print_boldblue "udev rules installed         : ${install_udev}"
print_boldblue "Dockerfile patched           : ${dockerfile_patched}"
print_boldblue "Image built now              : ${build_image}"
print_boldblue "rover_jazzy_docker.service   : ${service_created}"
print_bold "==================================================="
echo ""
print_green "Host-side installation steps completed."
