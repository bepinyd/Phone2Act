# 📱 Phone2Act – ROS2 WebSocket Communication App

**Phone2Act** is a Flutter-based Android application that connects directly to your **ROS 2** system using a WebSocket interface.
It allows users to send custom ROS 2 messages and publish real-time phone sensor data to ROS 2 topics.

---

## 🚀 Features

* One-click **Connect** button to link with ROS 2 over WebSocket
* Send **custom messages** (`std_msgs/String` or any message type)
* Publish **phone sensor data** (accelerometer, gyroscope, GPS, etc.)
* Automatically publishes data to `/phone2act/<sensor_name>` topics
* Compatible with any ROS 2 distribution using `rosbridge_websocket`

---

## ⚙️ Requirements

* ROS 2 installed (e.g., Humble, Iron, or Jazzy)
* `rosbridge_suite` installed and running
* Your Android device and ROS 2 PC are on the same local network

---

## 🛠️ ROS 2 Setup

### 1. Install `rosbridge_suite`

```bash
sudo apt install ros-${ROS_DISTRO}-rosbridge-suite
```

### 2. Start the WebSocket Server

```bash
ros2 launch rosbridge_server rosbridge_websocket_launch.xml
```

This starts a WebSocket server at `ws://<your-computer-ip>:9090`

---

## 📱 App Installation

1. Download the latest APK from [Releases](https://drive.google.com/file/d/1yDXaTvdu8CEoIoj39ggsrJ-cXL1p5EVV/view?usp=sharing)
2. Transfer to your Android device
3. Allow installation from unknown sources and install

---

## 🧭 Using the App

1. Open **Phone2Act** on your phone
2. Tap **Connect** and enter your ROS 2 WebSocket URL (e.g. `ws://192.168.1.10:9090`)
3. Send custom messages or enable sensor streaming

---

## 📡 Topics Published

| Topic                     | Data Source         | Message Type            |
| ------------------------- | ------------------- | ----------------------- |
| `/phone2act/string_msg`   | Custom message      | `std_msgs/String`       |
| `/phone2act/accelerometer`| Phone accelerometer | `geometry_msgs/Vector3` |
| `/phone2act/gyroscope`    | Phone gyroscope     | `geometry_msgs/Vector3` |
| `/phone2act/gps`          | Phone GPS           | `sensor_msgs/NavSatFix` |

---

## 🧠 Tech Stack

* Flutter (Frontend + Native Sensors)
* `rosbridge_server` for ROS 2 ↔ WebSocket communication
* ROS 2 Humble / Iron / Jazzy

---

## 💡 Example Usage

```bash
ros2 topic echo /phone2act/string_msg
ros2 topic echo /phone2act/accelerometer
```

---

## 🪪 License

MIT License © 2025 Bipin Yadav

---

## 📫 Contact

Email: [kupkode@gmail.com](mailto:kupkode@gmail.com)
GitHub: [https://github.com/bepinyd/Phone2Act](https://github.com/bepinyd/Phone2Act)
