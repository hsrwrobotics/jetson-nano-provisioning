# Project Context

This repository provisions five Jetson Nano 2GB kits for the robotics lab. Each board is mounted on a TurtleBot 2 and runs headless (no GUI). The host OS is Ubuntu 20.04 (focal), flashed from the Qengineering Jetson Nano Ubuntu 20 image (JetPack 4.6.1).

An Ansible playbook keeps all five boards in the same state: it removes the GUI, installs Docker, and deploys a `docker-compose` stack of three host-network containers:

- `kobuki` — ROS 2 Humble Kobuki base (runs in a jammy container)
- `rosbridge` — WebSocket bridge over ROS 2 (rosbridge_suite)

ROS 2 runs **inside Docker**, so the host stays a clean Ubuntu 20.04 server. The Kobuki image is built and published to Docker Hub by GitHub Actions on push to `main`.
