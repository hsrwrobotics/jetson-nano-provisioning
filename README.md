# Robotics Lab — Jetson Nano TurtleBot 1 Provisioning

Provisions **five Jetson Nano 2GB** boards (each mounted on a TurtleBot 1) into identical, headless Ubuntu 20.04 servers that run Docker. Each board runs two host-network containers:

| Container   | Image              | Role                                            |
|-------------|--------------------|-------------------------------------------------|
| `kobuki`    | `tsecretino/kobuki` | ROS 2 Humble Kobuki base                        |
| `rosbridge` | `tsecretino/kobuki`   | WebSocket bridge over ROS 2 (`rosbridge_suite`)             |

ROS 2 runs **inside Docker** (a jammy container), so the host stays a clean Ubuntu 20.04 (focal) machine.

## Host image

Flash the [Qengineering Jetson Nano Ubuntu 20 image](https://github.com/Qengineering/Jetson-Nano-Ubuntu-20-image) (Ubuntu 20.04, JetPack 4.6.1) to the SD card. Default login: user `jetson`, password `jetson`. This gives the 20.04 (focal) userspace the playbook expects.

## Prerequisites

1. Install the project's pinned Ansible with [uv](https://docs.astral.sh/uv/):
   ```bash
   uv sync
   ```
2. SSH access to each Jetson (or rely on the password in the inventory).
3. (Only to rebuild the ROS image) a Docker Hub account with `DOCKERHUB_USERNAME` / `DOCKERHUB_TOKEN` set as GitHub repo secrets.

## 1. Configure the inventory

Edit `inventory.ini` — set each board's IP and credentials:

```ini
[jetson]
10.111.14.161 ansible_user=jetson ansible_password=jetson
10.111.14.162 ansible_user=jetson ansible_password=jetson
10.111.14.163 ansible_user=jetson ansible_password=jetson
10.111.14.164 ansible_user=jetson ansible_password=jetson
10.111.14.165 ansible_user=jetson ansible_password=jetson

[jetson:vars]
ansible_python_interpreter=/usr/bin/python3
ansible_password=jetson
ansible_become_pass=jetson
```

## 2. Create the environment file

The `kobuki` container reads `/opt/compose/.env` (for `NAMESPACE`), which the playbook copies from `deploy/.env`. That file is **not committed**. Create it locally:

```bash
cp deploy/.env.example deploy/.env
```

## 3. Test connectivity

```bash
uv run ansible jetson -m ping
```

## 4. Run the playbook

```bash
# Everything (provision + deploy)
uv run ansible-playbook playbook.yaml

# Just headless + Docker install
uv run ansible-playbook playbook.yaml --tags provision

# Just deploy the compose stack
uv run ansible-playbook playbook.yaml --tags deploy
```

The playbook does two things:

- **provision** — removes the GUI (headless), refreshes + upgrades apt, installs the Docker Engine + Compose plugin (focal / arm64), and adds `jetson` to the `docker` group.
- **deploy** — writes `/opt/compose/docker-compose.yml` and `/opt/compose/.env`, then runs `docker compose up -d`.

## 5. Verify

On a board:

```bash
docker ps          # expect kobuki, rosbridge all running
```

## Files

- `playbook.yaml` — the Ansible automation (provision + deploy).
- `inventory.ini` — board IPs + credentials.
- `ansible.cfg` — Ansible defaults (inventory path, Python interpreter).
- `deploy/docker-compose.yml` — the two-container stack.
- `deploy/.env.example` — template for `deploy/.env` (copy it; never commit the real one).
- `kobuki/` — multi-stage Dockerfile for the ROS 2 Humble Kobuki image.
- `.github/workflows/kobuki-docker-publish.yml` — builds + publishes `tsecretino/kobuki` to Docker Hub on push to `main`.

## Rebuilding / publishing the ROS image

Pushing to `main` (touching `kobuki/`) triggers CI, which builds `linux/arm64` and pushes `tsecretino/kobuki:latest` to Docker Hub. Set `DOCKERHUB_USERNAME` and `DOCKERHUB_TOKEN` as repo secrets. To build locally:

```bash
docker buildx build --platform linux/arm64 -f kobuki/Dockerfile -t tsecretino/kobuki:latest .
```
