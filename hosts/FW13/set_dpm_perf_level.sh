#!/usr/bin/env bash

# Default level
DRM_PERF_LEVEL=low

# Evaluate argument passed by udev
if [ $1 -eq 1 ] ; then
  DRM_PERF_LEVEL=high
else
  DRM_PERF_LEVEL=low
fi

# Set drm performance level
echo $DRM_PERF_LEVEL > /sys/class/drm/card0/device/power_dpm_force_performance_level
