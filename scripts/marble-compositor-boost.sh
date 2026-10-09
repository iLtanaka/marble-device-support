#!/bin/sh
# marble-compositor-boost: give the compositor a CPU frequency floor
# (per-task uclamp.min), the distro-neutral version of marble-kwin-boost.sh.
# schedutil leaves the little cores at ~0.5 GHz between touch events, so the
# compositor misses the 8.3 ms frame budget at 120 Hz (felt as input lag).
# The clamp only costs power while the compositor runs; apps are not clamped.
# Process names: /etc/marble/compositors (one line, space separated).
UCLAMP_MIN=512
names="phoc phosh kwin_wayland kwin_wayland_wrapper gnome-shell sway"
[ -r /etc/marble/compositors ] && names=$(cat /etc/marble/compositors)
while :; do
	for p in $(pidof $names); do
		uclampset -p "$p" 2>/dev/null | grep -q "min: $UCLAMP_MIN " ||
			uclampset -m "$UCLAMP_MIN" -a -p "$p" 2>/dev/null
	done
	sleep 5
done
