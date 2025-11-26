# 🚀 Docker Setup for Rover Robotics ROS 2 Jazzy

This guide explains how to set up a Docker-based ROS 2 Jazzy environment for Rover Robotics.
including LiDAR, IMU, Intel RealSense, and PS4 controller support.

---

## ✅ STEP 1 – Install Docker

1. Install Docker Engine for Ubuntu on the host system:  
   https://docs.docker.com/engine/install/ubuntu/

   > Recommended: **Install using the APT repository**.

2. Complete the Docker Linux post-install steps (non-root usage, etc.):  
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

Follow the prompts in the setup script. It will:

📥 Install:

- Rover Robotics ROS 2 Jazzy GitHub repo

- RP LiDAR S2 packages

- BNO055 IMU packages

- Intel RealSense packages
  
- ZED F9P GPS packages 

- PS4 controller support

🐳 Build the Docker image

⚙️ Configure the automatic startup service for the Rover Jazzy Docker container
(so the robot is ready to drive after boot)

📝 Note

- The Rover Robotics ROS 2 Jazzy repo, RP LiDAR S2 repo, BNO055 IMU repo, and ZEDF9P GPS repo will be installed in
~/rover_workspace on the host, and this workspace will be mounted into the Docker container.

- Intel RealSense files and packages will be installed inside the Docker image based on the user’s choice.

---

## 🧱 STEP 4 – Build ROS 2 Packages Inside the Container

After the container is created and running, enter the container and run:
```
cd /home/ubuntu/rover_workspace
colcon build
source ~/.bashrc
```

ℹ️ The packages are not pre-built on the first setup, so colcon build is required before using
the Rover Robotics ROS 2 stack.

Then, on the host, restart the services:
```
sudo systemctl restart roverrobotics.service
sudo systemctl restart can.service
```

---

### ✅ You’re now ready to use the Rover Robotics ROS 2 Jazzy stack inside Docker.
### 💡 Check Useful Tips

---

## 🛠️ Manual Setup (Alternative)

If you want to manually build the image and create the container instead of using setup.sh:

1️⃣ Build the Rover Jazzy Docker Image
```
chmod +x rover_jazzy_image.sh
./rover_jazzy_image.sh
```
2️⃣ Create the Rover Jazzy Container
```
chmod +x run_rover_rover_jazzy_con.sh
./run_rover_rover_jazzy_con.sh
```

---

## 💡 Useful Tips (SSH, X11, User)
## 🔁 SSH to Host

- If you SSH into the host (which runs Docker) and want GUIs from inside the container:

Add this to your local SSH config (~/.ssh/config):
```
Host <your-host-alias>
    HostName <your-host-ip>
    User <your-username>
    ForwardX11 yes
    ForwardX11Trusted yes
    Compression yes
```
- 🖥️ Allow X11 Clients

On the host (when using a local or newly SSH’d client):
```
xhost +
xhost +local: 
```
- 👤 Use ubuntu User instead of root Inside the Container

Inside the container:
```
su - ubuntu
```
Even if you don’t need GUI / display, it’s strongly recommended to run all sensor launch files and ROS 2 nodes as the Ubuntu user rather than root

--- 

## 🎛️ By Default the display of Docker container is through ssh system
- But If you want GUIs to render directly on the host’s physical screen instead, you need to match the host’s DISPLAY
```
sudo nano /etc/systemd/system/rover_jazzy_docker.service 
Environment="DISPLAY=:1"
```
- Make sure DISPLAY matches the host value:
```
echo $DISPALY
```
- Restart the startup service
```
sudo systemctl daemon-reload
sudo systemctl restart rover_jazzy_docker.service
```