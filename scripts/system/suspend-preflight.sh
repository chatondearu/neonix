#!/usr/bin/env bash
# Read-only checks before trying RAM suspend (does not suspend).
set -euo pipefail

echo "== logind sleep capability =="
busctl call org.freedesktop.login1 /org/freedesktop/login1 \
  org.freedesktop.login1.Manager CanSuspend 2>/dev/null | tr -d '"' || true
busctl call org.freedesktop.login1 /org/freedesktop/login1 \
  org.freedesktop.login1.Manager CanHibernate 2>/dev/null | tr -d '"' || true

echo
echo "== kernel sleep =="
cat /sys/power/mem_sleep 2>/dev/null || true
grep -o 'nohibernate' /proc/cmdline >/dev/null && echo "nohibernate: yes (hibernation disabled)" || echo "nohibernate: no"

echo
echo "== suspend stats (this boot) =="
cat /sys/kernel/debug/suspend_stats 2>/dev/null | head -5 || echo "(no suspend_stats)"

echo
echo "== sleep inhibitors =="
systemd-inhibit --list
