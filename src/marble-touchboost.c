// SPDX-License-Identifier: MIT
/*
 * marble-touchboost: raise the CPU frequency floor while the touchscreen is in use
 *
 * Each touch passes through several short stages (touch IRQ thread, libinput,
 * client UI thread, render thread, compositor, DRM commit). None of them runs
 * long enough for schedutil to ramp, so at the idle floor (~0.5 GHz on the
 * A510s) each stage is 2-4x slower and the UI trails the finger, even though
 * frames still arrive every 8.3 ms. Android solves this with an input boost;
 * this does the same: boost on the first touch event, restore the original
 * floors HOLD_MS after the last one.
 */
#include <errno.h>
#include <fcntl.h>
#include <linux/input.h>
#include <poll.h>
#include <signal.h>
#include <stdio.h>
#include <string.h>
#include <time.h>
#include <unistd.h>

#define TOUCH_DEV "/dev/input/by-path/platform-990000.spi-cs-0-event"
#define HOLD_MS   1000	/* covers kinetic scrolling after the finger lifts */

static const struct {
	const char *path;
	const char *boost;
} policies[] = {
	{ "/sys/devices/system/cpu/cpufreq/policy0/scaling_min_freq", "1804800" },
	{ "/sys/devices/system/cpu/cpufreq/policy4/scaling_min_freq", "2112000" },
	{ "/sys/devices/system/cpu/cpufreq/policy7/scaling_min_freq", "1651200" },
};
#define NPOL (sizeof(policies) / sizeof(policies[0]))

static char saved[NPOL][32];
static volatile sig_atomic_t stop;

static void on_signal(int sig) { (void)sig; stop = 1; }

static long long now_ms(void)
{
	struct timespec ts;

	clock_gettime(CLOCK_MONOTONIC, &ts);
	return ts.tv_sec * 1000LL + ts.tv_nsec / 1000000;
}

static int sysfs_write(const char *path, const char *val)
{
	int fd = open(path, O_WRONLY);
	int ret;

	if (fd < 0)
		return -1;
	ret = write(fd, val, strlen(val)) < 0 ? -1 : 0;
	close(fd);
	return ret;
}

static void sysfs_read(const char *path, char *buf, size_t len)
{
	int fd = open(path, O_RDONLY);
	ssize_t n = fd < 0 ? -1 : read(fd, buf, len - 1);

	if (fd >= 0)
		close(fd);
	buf[n > 0 ? n : 0] = '\0';
	buf[strcspn(buf, "\n")] = '\0';
}

static void set_boost(int on)
{
	for (size_t i = 0; i < NPOL; i++)
		if (on || saved[i][0])
			sysfs_write(policies[i].path, on ? policies[i].boost : saved[i]);
}

int main(void)
{
	struct input_event ev[64];
	long long last = 0;
	int boosted = 0;
	int fd;

	for (size_t i = 0; i < NPOL; i++)
		sysfs_read(policies[i].path, saved[i], sizeof(saved[i]));

	signal(SIGTERM, on_signal);
	signal(SIGINT, on_signal);

	fd = open(TOUCH_DEV, O_RDONLY | O_NONBLOCK);
	if (fd < 0) {
		fprintf(stderr, "marble-touchboost: %s: %s\n", TOUCH_DEV, strerror(errno));
		return 1;
	}

	while (!stop) {
		struct pollfd pfd = { .fd = fd, .events = POLLIN };
		int timeout = boosted ? (int)(last + HOLD_MS - now_ms()) : -1;
		int r;

		if (boosted && timeout <= 0) {
			set_boost(0);
			boosted = 0;
			continue;
		}

		r = poll(&pfd, 1, timeout);
		if (r < 0 && errno == EINTR)
			continue;
		if (r < 0 || (pfd.revents & (POLLERR | POLLHUP)))
			break;
		if (r == 0)
			continue;

		while (read(fd, ev, sizeof(ev)) > 0)
			;
		last = now_ms();
		if (!boosted) {
			set_boost(1);
			boosted = 1;
		}
	}

	if (boosted)
		set_boost(0);
	close(fd);
	return 0;
}
