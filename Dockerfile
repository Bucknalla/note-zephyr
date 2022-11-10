# Container for Developing Zephyr Applications

# Build development environment
# $ docker build --file Dockerfile.zephyr --tag west .

# Launch `west` CLI
# (be sure to place the binary in your local ~/Downloads folder)
# $ docker run --device /dev/bus/usb --rm --tty \
#   --volume ~/Downloads/:/host-volume/ west

# Global Argument(s)
ARG DEBIAN_FRONTEND="noninteractive"
ARG UID=1000
ARG USER="blues"

# Base Image
FROM ubuntu:22.04

# Import Global Argument(s)
ARG DEBIAN_FRONTEND
ARG UID
ARG USER

# Local Argument(s)

# Create Non-Root User
RUN ["dash", "-c", "\
    addgroup \
     --gid ${UID} \
     \"${USER}\" \
 && adduser \
     --disabled-password \
     --gecos \"\" \
     --ingroup \"${USER}\" \
     --uid ${UID} \
     \"${USER}\" \
 && usermod \
     --append \
     --groups \"dialout,plugdev\" \
     \"${USER}\" \
"]

# Establish Environment
# https://docs.zephyrproject.org/latest/develop/getting_started/index.html#install-dependencies
RUN ["dash", "-c", "\
    apt-get update --quiet \
 && apt-get install --assume-yes --no-install-recommends --quiet \
     ccache \
     cmake \
     device-tree-compiler \
     dfu-util \
     file \
     g++-multilib \
     gcc \
     gcc-multilib \
     git \
     gperf \
     libmagic1 \
     libsdl2-dev \
     make \
     nano \
     ninja-build \
     python3-dev \
     python3-pip \
     python3-setuptools \
     python3-tk \
     python3-wheel \
     tree \
     wget \
     xz-utils \
 && apt-get clean \
 && apt-get purge \
 && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
"]

# Update User and Path
USER ${USER}
ENV PATH="/home/${USER}/.local/bin:${PATH}"

# Install Zephyr and Tools
RUN ["dash", "-c", "\
    pip3 install --user -U west \
 && west init ~/zephyrproject \
 && cd ~/zephyrproject \
 && west update \
 && west zephyr-export \
 && pip3 install --user -r ~/zephyrproject/zephyr/scripts/requirements.txt \
"]

# Update User and Working Directory
USER root
WORKDIR /usr/local/

# Install Zephyr SDK and Tools
RUN ["dash", "-c", "\
    wget https://github.com/zephyrproject-rtos/sdk-ng/releases/download/v0.15.1/zephyr-sdk-0.15.1_linux-x86_64.tar.gz \
 && wget -O - https://github.com/zephyrproject-rtos/sdk-ng/releases/download/v0.15.1/sha256.sum | shasum --check --ignore-missing \
 && tar xvf zephyr-sdk-0.15.1_linux-x86_64.tar.gz \
 && cd zephyr-sdk-0.15.1 \
 && printf \"y\\nY\\n\" | ./setup.sh \
"]

# Update User and Path (gdb and openocd)
ENV PATH="/usr/local/zephyr-sdk-0.15.1/arm-zephyr-eabi/bin:${PATH}"
ENV PATH="/usr/local/zephyr-sdk-0.15.1/sysroots/x86_64-pokysdk-linux/usr/bin:${PATH}"
ENV ZEPHYR_BASE="/home/${USER}/zephyrproject/zephyr"
WORKDIR /host-volume

ENTRYPOINT ["west"]