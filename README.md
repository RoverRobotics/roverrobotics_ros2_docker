# 🚀 Docker Setup for Rover Robotics ROS 2 Jazzy

This guide explains how to set up a Docker-based ROS 2 Jazzy environment for Rover Robotics.
including LiDAR, IMU, Intel RealSense, and PS4 controller support.

---

## ✅ STEP 1 – Install Docker

1. Install Docker Engine for Ubuntu:  
   https://docs.docker.com/engine/install/ubuntu/

   > Recommended: **Install using the APT repository**.

2. Complete the Docker post-install steps (non-root usage, etc.):  
   https://docs.docker.com/engine/install/linux-postinstall/

---

## 📦 STEP 2 – Clone the Repository

```
git clone https://github.com/RoverRobotics/roverrobotics_ros2_docker.git
```

---

## 🔧 STEP 3 – Run the Setup Script

```
cd ~/roverrobotics_ros2_docker
chmod +x setup.sh
./setup.sh
```

The setup script will:

📥 Install:

- Rover Robotics ROS 2 Jazzy GitHub repo

- RP LiDAR S2 packages

- BNO055 IMU packages

- Intel RealSense packages

- PS4 controller support

🐳 Build the Docker image

⚙️ Configure the automatic startup service for the Rover Jazzy Docker container
(so the robot is ready to drive after boot)

📝 Note

The Rover Robotics ROS 2 Jazzy repo, RP LiDAR S2 repo, and BNO055 IMU repo will be installed in
~/rover_workspace on the host, and this workspace will be mounted into the Docker container.

Intel RealSense files and packages will be installed inside the Docker image based on the user’s choice.



### Docker setup for ROVER ROBOTICS ROS2 Jazzy:

---

## STEP - 1 Install Docker

link: https://docs.docker.com/engine/install/ubuntu/

Follow the steps given in this (recommended method: Install using the apt repository)

After the installation, do the steps given in the link: https://docs.docker.com/engine/install/linux-postinstall

---

## STEP - 2 Clone the Repository

```
git clone https://github.com/RoverRobotics/roverrobotics_ros2_docker.git
```
---

## STEP - 3 Setup

```
cd ~/roverrobotics_ros2_docker
chmod +x setup.sh
./setup.sh
```
Follow the prompts in the install scripts.

This script will help in the: 

- Installation of Rover Robotics GitHub, packages for RP S2 Lidar, BNO055 IMU, Intel RealSense, and PS4 controller 
- Builds the Docker image 
- Set up the automatic startup service for the Rover Jazzy Docker container. (helpful for driving the robot after boot)

Note: The Rover Robotics ROS2 Jazzy Github repo, RP lidar S2 repo, and BNO055 IMU repo will be installed in rover_workspace 
inside the host system and will be attached to the Docker. 
The files and Packages for Intel RealSense will be installed in the image directly based on the user's request 

---

## STEP - 4 Building the packages

Enter into container
```
cd /home/ubuntu/rover_workspace
colcon build
source ~/.bashrc
```
For the first time, the packages will not be built. Therefore, the packages have to be built for using the rover robotics ros2

Then restart the services
```
sudo systemctl restart roverrobotics.service
sudo systemctl restart can.service
```
---

## For Manual setup

To build the rover jazzy image
```
chmod +x rover_jazzy_image.sh 
./rover_jazzy_image.sh
```

To create the rover jazzy container
```
chmod +x run_rover_rover_jazzy_con.sh
./run_rover_rover_jazzy_con.sh
```
---

## Useful Tips 

If you are SSHing into the host system that runs Docker and want the display of Docker:
Add this in the SSH configuration after hostname and user

```
ForwardX11 yes
ForwardX11Trusted yes
Compression yes
```

And run everything as user ubuntu instead of user root

```
su - ubuntu
```

If you are SSHing from a new system to the host for Docker or directly using the host system for Docker

```
xhost +
```



