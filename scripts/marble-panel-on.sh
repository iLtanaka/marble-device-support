#!/bin/sh
# marble: the msm DRM driver lights the panel only after a disable/enable
# cycle (pmOS does it in the initramfs, KWin once more). Without the pauses
# the panel stays dark.
fb=/sys/class/graphics/fb0/blank
for i in $(seq 30); do [ -w $fb ] && break; sleep 1; done
[ -w $fb ] || exit 0
echo 1 > $fb; sleep 1; echo 0 > $fb; sleep 1
