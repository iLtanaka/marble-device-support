# marble-device-support

Distribution-agnostic hardware support layer for the **Xiaomi Poco F5 / Redmi Note 12 Turbo** (`xiaomi-marble`, Qualcomm Snapdragon 7+ Gen 2 / SM7475).

Provides userland configuration, ALSA UCM2 audio profiles, udev rules, performance tuning services, and hardware initialization scripts for running mainline Linux distributions (postmarketOS, ALT Mobile, Void Linux, Arch Linux, Debian, etc.).

---

## Contents

* **ALSA UCM2**: Stereo AW88263S speakers (HiFi profile with earpiece call routing) and WCD9385 microphone capture.
* **udev rules**:
  * `60-marble-storage.rules`: UFS storage scheduler tuning.
  * `61-marble-gpu.rules`: Adreno 725 runtime autosuspend delay and devfreq floor.
  * `81-libssc-xiaomi-marble.rules`: accelerometer mount matrix for the SSC sensors.
  * `90-iio-sensor-proxy-ssc-accel-proximity.rules`: asks `iio-sensor-proxy` for the accelerometer and the proximity sensor (upstream only enables light and compass).
* **udev hwdb**:
  * `61-marble-touchscreen.hwdb`: real touchscreen resolution (155 units/mm). The driver reports 10 units/mm, so libinput believes the screen is 1079 x 2399 mm. Run `systemd-hwdb update` after installing.
* **Services & Daemons**:
  * `marble-touchboost`: Low-overhead C daemon monitoring `/dev/input` to boost CPU frequency floor during active touch interaction, ensuring stable 120 Hz compositor response.
  * `marble-compositor-boost`: Applies `uclamp.min` (512) to wayland compositors (`phoc`, `kwin_wayland`, `gnome-shell`).
  * `marble-hardware-tuning`: Initial boot-time sysfs knobs (interconnect, GPU devfreq).
  * `marble-panel-on`: Framebuffer refresh cycling for direct boots without initramfs.
  * `marble-wifi-mac`: The WCN6855 reports an all-zero permanent MAC and NetworkManager cannot activate any Wi-Fi connection; sets a stable, locally administered address derived from the SoC serial before the network manager starts.
  * `marble-bt-addr`: The Bluetooth controller has no public address and stays unconfigured (no adapter in bluetoothd); sets a stable address derived from the SoC serial.
* **Drop-in configurations**:
  * `hexagonrpcd-sdsp.service.d/60-marble-registry.conf`: Redirects sensor registry path to `/usr/share/qcom`.
  * `iio-sensor-proxy.service.d/60-marble-sensors.conf`: Binds sensor proxy to SSC sensor devices.
  * `ModemManager.service.d/60-marble-wait-qrtr.conf`: Starts ModemManager only after the modem has published its QMI services on QRTR (otherwise "No modems were found" until it is restarted).
* **Plasma override** (`$(SYSCONFDIR)/systemd/user/plasma-powerdevil.service`): starts powerdevil before plasmashell. Plasma Mobile queries the brightness once at shell start-up; with the upstream ordering powerdevil is not running yet and the quick settings brightness slider stays hidden.
* **System Environment**:
  * `90-xiaomi-marble.conf`: GTK4 / Wayland rendering optimizations.
  * `99-marble-vm.conf`: Virtual memory dirty page thresholds for zram.

---

## Building and Installation

### Build

```bash
make
```

### Installation

```bash
sudo make install PREFIX=/usr
```

### Enabling Services (systemd)

```bash
sudo systemctl enable marble-panel-on.service
sudo systemctl enable marble-hardware-tuning.service
sudo systemctl enable marble-touchboost.service
sudo systemctl enable marble-compositor-boost.service
sudo systemctl enable marble-wifi-mac.service
sudo systemctl enable marble-bt-addr.service
sudo systemd-hwdb update
```

`marble-panel-on.service` is required on any system that boots without an
initramfs: the msm DRM driver lights the panel only after a disable/enable
cycle, so without it the screen stays black even though the system is up.
It has to run before the display manager, which the unit orders itself.

---

## License

GPL-2.0-or-later / MIT (see individual file headers).
