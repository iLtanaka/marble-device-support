#!/bin/sh
# marble: the WCN6855 Bluetooth controller has no public address and stays
# unconfigured ("Index list with 0 items" in btmgmt), so bluetoothd shows no
# adapter. Set a stable address derived from the SoC serial number. The mgmt
# index only appears once the QCA firmware download finishes, so retry.
h=$(cat /sys/devices/soc0/serial_number | sha256sum | cut -c1-10)
addr=$(printf '02:%s:%s:%s:%s:%s' $(echo "$h" | sed 's/../& /g'))
for i in $(seq 60); do
	btmgmt --index 0 public-addr "$addr" 2>&1 | grep -q complete && exit 0
	sleep 0.5
done
echo "marble-bt-addr: could not set the Bluetooth address" >&2
exit 1
