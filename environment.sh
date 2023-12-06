#!/usr/bin/env bash

# TODO: Define env variables
DISK="/dev/vda"
USER_NAME="luka"

ROOT_PASSWORD=""
USER_PASSWORD=""
HOSTNAME=""

GPU_PACKAGES=()
# GPU_PACKAGES=("nvidia nvidia-utils" "nvidia-settings")
# GPU_PACKAGES=("xf86-video-amdgpu")

# system information
PROCESSOR_TYPE="Intel"
if [ "$(lscpu | grep 'AMD')" ];
then
    PROCESSOR_TYPE="AMD"
fi
