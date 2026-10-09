PREFIX ?= /usr
DESTDIR ?=

CC ?= gcc
CFLAGS ?= -O2 -Wall -Wextra
LDFLAGS ?=

BIN = marble-touchboost

.PHONY: all clean install

all: $(BIN)

$(BIN): src/marble-touchboost.c
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ $<

clean:
	rm -f $(BIN)

install: all
	# Binary and helper scripts
	install -d $(DESTDIR)$(PREFIX)/libexec
	install -m 755 $(BIN) $(DESTDIR)$(PREFIX)/libexec/
	install -m 755 scripts/marble-hardware-tuning.sh $(DESTDIR)$(PREFIX)/libexec/
	install -m 755 scripts/marble-panel-on.sh $(DESTDIR)$(PREFIX)/libexec/
	install -m 755 scripts/marble-compositor-boost.sh $(DESTDIR)$(PREFIX)/libexec/

	# ALSA UCM2 profiles
	install -d $(DESTDIR)$(PREFIX)/share/alsa/ucm2/conf.d/sm8450
	install -m 644 alsa/ucm2/conf.d/sm8450/SM8475-Xiaomi-Marble.conf $(DESTDIR)$(PREFIX)/share/alsa/ucm2/conf.d/sm8450/
	install -d $(DESTDIR)$(PREFIX)/share/alsa/ucm2/Qualcomm/sm8450/xiaomi-marble
	install -m 644 alsa/ucm2/Qualcomm/sm8450/xiaomi-marble/HiFi.conf $(DESTDIR)$(PREFIX)/share/alsa/ucm2/Qualcomm/sm8450/xiaomi-marble/

	# udev rules
	install -d $(DESTDIR)$(PREFIX)/lib/udev/rules.d
	install -m 644 udev/60-marble-storage.rules $(DESTDIR)$(PREFIX)/lib/udev/rules.d/
	install -m 644 udev/61-marble-gpu.rules $(DESTDIR)$(PREFIX)/lib/udev/rules.d/
	install -m 644 udev/81-libssc-xiaomi-marble.rules $(DESTDIR)$(PREFIX)/lib/udev/rules.d/

	# systemd units
	install -d $(DESTDIR)$(PREFIX)/lib/systemd/system
	install -m 644 systemd/marble-hardware-tuning.service $(DESTDIR)$(PREFIX)/lib/systemd/system/
	install -m 644 systemd/marble-touchboost.service $(DESTDIR)$(PREFIX)/lib/systemd/system/
	install -m 644 systemd/marble-panel-on.service $(DESTDIR)$(PREFIX)/lib/systemd/system/
	install -m 644 systemd/marble-compositor-boost.service $(DESTDIR)$(PREFIX)/lib/systemd/system/

	# systemd drop-ins
	install -d $(DESTDIR)$(PREFIX)/lib/systemd/system/hexagonrpcd-sdsp.service.d
	install -m 644 systemd/drop-ins/hexagonrpcd-sdsp.service.d/60-marble-registry.conf $(DESTDIR)$(PREFIX)/lib/systemd/system/hexagonrpcd-sdsp.service.d/
	install -d $(DESTDIR)$(PREFIX)/lib/systemd/system/iio-sensor-proxy.service.d
	install -m 644 systemd/drop-ins/iio-sensor-proxy.service.d/60-marble-sensors.conf $(DESTDIR)$(PREFIX)/lib/systemd/system/iio-sensor-proxy.service.d/

	# sysctl and environment
	install -d $(DESTDIR)$(PREFIX)/lib/sysctl.d
	install -m 644 sysctl/99-marble-vm.conf $(DESTDIR)$(PREFIX)/lib/sysctl.d/
	install -d $(DESTDIR)$(PREFIX)/lib/environment.d
	install -m 644 environment/90-xiaomi-marble.conf $(DESTDIR)$(PREFIX)/lib/environment.d/
