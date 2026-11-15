#!/bin/sh
# marble: the WCN6855 (ath11k_pci) comes up with an all-zero permanent MAC.
# NetworkManager then fails every activation ("set-hw-addr: failed to reset
# MAC address to 00:00:00:00:00:00"). Give the interface a stable, locally
# administered address derived from the SoC serial number before the network
# manager starts.
for i in $(seq 40); do
	for dev in /sys/class/net/*; do
		[ "$(basename "$(readlink -f "$dev/device/driver" 2>/dev/null)")" = ath11k_pci ] || continue
		iface=${dev##*/}
		h=$( (cat /sys/devices/soc0/serial_number; echo wlan) | sha256sum | cut -c1-10)
		addr=$(printf '02:%s:%s:%s:%s:%s' $(echo "$h" | sed 's/../& /g'))
		ip link set dev "$iface" down
		ip link set dev "$iface" address "$addr"
		exit 0
	done
	sleep 0.5
done
exit 0
