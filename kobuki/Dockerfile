FROM ros:humble-ros-base-jammy AS builder

ENV WORKSPACE_ROOT=/kobuki
ENV ROS_DISTRO=humble

# Install build deps + ROS packages, clean apt in same layer
RUN apt-get update && apt-get install -y --no-install-recommends \
    ros-dev-tools \
    ros-humble-angles \
    ros-humble-diagnostics \
    ros-humble-joint-state-publisher \
    ros-humble-ros-testing \
    ros-humble-action-msgs \
    ros-humble-rmw-cyclonedds-cpp \
    ros-humble-openni2-camera \
    ros-humble-depth-image-proc \
    udev && \
    rm -rf /var/lib/apt/lists/*

# Clone sources at build time (not committed to repo)
WORKDIR ${WORKSPACE_ROOT}/src
RUN git clone --recurse-submodules https://github.com/AIResearchLab/kobuki.git && \
    git clone --recurse-submodules https://github.com/AIResearchLab/kobuki_dependencies.git

# Install rosdep dependencies
RUN rm -f /etc/ros/rosdep/sources.list.d/20-default.list && \
    rosdep init && rosdep update && \
    apt-get update && \
    rosdep install --from-paths ${WORKSPACE_ROOT}/src -y --ignore-src

# Build
WORKDIR ${WORKSPACE_ROOT}
RUN . /opt/ros/humble/setup.sh && colcon build

# Final stage - copy only install output, not entire FS
FROM ros:humble-ros-base-jammy

ENV WORKSPACE_ROOT=/kobuki
ENV ROS_DISTRO=humble
ENV RMW_IMPLEMENTATION=rmw_cyclonedds_cpp

COPY --from=builder ${WORKSPACE_ROOT}/install ${WORKSPACE_ROOT}/install

# Install runtime deps (previously inherited via COPY --from=base / /)
RUN apt-get update && apt-get install -y --no-install-recommends \
    ros-humble-angles \
    ros-humble-diagnostics \
    ros-humble-joint-state-publisher \
    ros-humble-action-msgs \
    ros-humble-rmw-cyclonedds-cpp \
    ros-humble-openni2-camera \
    ros-humble-depth-image-proc \
    ros-humble-joy \
    ros-humble-teleop-twist-joy \
    ros-humble-xacro \
    ros-humble-diagnostic-updater \
    ros-humble-tf2-geometry-msgs \
    ros-humble-actionlib-msgs \
    ros-humble-rosbridge-server \
    udev && \
    rm -rf /var/lib/apt/lists/*

COPY kobuki/60-kobuki.rules /etc/udev/rules.d/60-kobuki.rules

RUN printf 'source /opt/ros/%s/setup.bash\nsource %s/install/setup.bash\n' \
    "$ROS_DISTRO" "$WORKSPACE_ROOT" >> /root/.bashrc

COPY --chmod=755 kobuki/entrypoint.sh /workspace_entrypoint.sh

ENTRYPOINT ["/workspace_entrypoint.sh"]
WORKDIR ${WORKSPACE_ROOT}