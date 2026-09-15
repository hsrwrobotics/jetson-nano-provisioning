#!/bin/bash
set -e

# start udev if available (needed for device symlinks)
if [ -x /lib/systemd/systemd-udevd ]; then
    /lib/systemd/systemd-udevd --daemon 2>/dev/null || true
fi

# setup ros2 environment
source "/opt/ros/$ROS_DISTRO/setup.bash"
source "$WORKSPACE_ROOT/install/setup.bash"


exec "$@"
