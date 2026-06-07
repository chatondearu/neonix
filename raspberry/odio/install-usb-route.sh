#!/usr/bin/env bash
# Configure USB line-in → Merus AMP via PulseAudio on odio (phase 2).
# Run on the Pi as user odio, or via deploy-usb-route.sh from the dev machine.
set -euo pipefail

USB_ALSA_ID="${USB_ALSA_ID:-CODEC}"
MERUS_ALSA_CARD="${MERUS_ALSA_CARD:-sndrpimerusamp}"
LOOPBACK_LATENCY_MS="${LOOPBACK_LATENCY_MS:-50}"
USB_SOURCE_PATTERN="${USB_SOURCE_PATTERN:-}"
MERUS_SINK_PATTERN="${MERUS_SINK_PATTERN:-}"
MERUS_PA_SINK_NAME="${MERUS_PA_SINK_NAME:-merus_amp}"

MODPROBE_FILE="/etc/modprobe.d/snd-usb-audio-odio.conf"
APPLY_SCRIPT="${HOME}/.local/bin/usb-route-apply.sh"
SYSTEMD_UNIT="${HOME}/.config/systemd/user/usb-route.service"

usage() {
  cat <<'EOF'
Usage: install-usb-route.sh [--install | --remove | --status | --test-alsaloop]

PulseAudio route: USB codec (Behringer UCA202/UCA222) → Merus I2S amp.
Coexists with odio AirPlay / Spotify (unlike alsaloop on hw:).

Commands:
  --install         modprobe index + loopback + user systemd (default)
  --remove          stop loopback and remove persistence
  --status          show ALSA cards, PulseAudio devices, active loopback
  --test-alsaloop   one-shot ALSA loop (stops PulseAudio — diagnostic only)

Environment:
  USB_ALSA_ID=CODEC              Expected ALSA card id for USB codec
  MERUS_ALSA_CARD=sndrpimerusamp Merus card name
  LOOPBACK_LATENCY_MS=50         PulseAudio loopback latency
  USB_SOURCE_PATTERN=            Override PulseAudio source grep pattern
  MERUS_SINK_PATTERN=            Override PulseAudio sink grep pattern

Examples:
  install-usb-route.sh --status
  install-usb-route.sh --install
  LOOPBACK_LATENCY_MS=80 install-usb-route.sh --install
EOF
}

require_command() {
  if ! command -v "$1" >/dev/null; then
    echo "Missing command: $1" >&2
    exit 1
  fi
}

pa_ready() {
  pactl info >/dev/null 2>&1
}

find_usb_source() {
  local pattern="${USB_SOURCE_PATTERN:-${USB_ALSA_ID}}"
  # Field $2 is the source name; full line also has driver/state columns.
  pactl list short sources | awk -v pat="$pattern" '
    $2 ~ /^alsa_input\./ && $2 !~ /\.monitor$/ && $2 ~ pat { print $2; exit }
  '
}

find_merus_sink() {
  if [ -n "${MERUS_SINK_PATTERN:-}" ]; then
    pactl list short sinks | awk -v pat="$MERUS_SINK_PATTERN" '
      $2 ~ pat { print $2; exit }
    '
    return
  fi
  pactl list short sinks | awk -v name="'"${MERUS_PA_SINK_NAME}"'" -v card="'"${MERUS_ALSA_CARD}"'" '
    $2 == name || $2 ~ card || $2 ~ /[Mm]erus/ { print $2; exit }
  '
}

merus_sink_module_index() {
  pactl list short modules | awk -v name="$MERUS_PA_SINK_NAME" '
    $0 ~ ("sink_name=" name) { print $1; exit }
  '
}

ensure_merus_sink() {
  local sink
  sink="$(find_merus_sink || true)"
  if [ -n "$sink" ]; then
    printf '%s' "$sink"
    return 0
  fi

  if ! aplay -l 2>/dev/null | grep -qF "$MERUS_ALSA_CARD"; then
    return 1
  fi

  echo "Merus visible in ALSA but not PulseAudio — loading module-alsa-sink..." >&2
  pactl load-module module-alsa-sink \
    "device=hw:${MERUS_ALSA_CARD},0" \
    "sink_name=${MERUS_PA_SINK_NAME}" \
    "sink_properties=device.description=Merus_AMP"

  find_merus_sink || printf '%s' "$MERUS_PA_SINK_NAME"
}

loopback_module_index() {
  pactl list short modules | awk '/module-loopback/ { print $1; exit }'
}

install_modprobe() {
  local content="options snd-usb-audio index=1"
  if [ -f "$MODPROBE_FILE" ] && grep -qF "$content" "$MODPROBE_FILE" 2>/dev/null; then
    echo "modprobe: already configured ($MODPROBE_FILE)"
    return 0
  fi
  echo "Installing $MODPROBE_FILE (Merus card 0, USB card 1)..."
  echo "$content" | sudo tee "$MODPROBE_FILE" >/dev/null
  echo "  Reboot or replug USB codec if card order is wrong."
}

write_apply_script() {
  mkdir -p "$(dirname "$APPLY_SCRIPT")"
  cat >"$APPLY_SCRIPT" <<EOF
#!/usr/bin/env bash
set -euo pipefail
USB_ALSA_ID="${USB_ALSA_ID}"
MERUS_ALSA_CARD="${MERUS_ALSA_CARD}"
LOOPBACK_LATENCY_MS="${LOOPBACK_LATENCY_MS}"
USB_SOURCE_PATTERN="${USB_SOURCE_PATTERN}"
MERUS_SINK_PATTERN="${MERUS_SINK_PATTERN}"
MERUS_PA_SINK_NAME="${MERUS_PA_SINK_NAME}"

find_usb_source() {
  local pattern="\${USB_SOURCE_PATTERN:-\${USB_ALSA_ID}}"
  pactl list short sources | awk -v pat="\$pattern" '
    \$2 ~ /^alsa_input\\./ && \$2 !~ /\\.monitor\$/ && \$2 ~ pat { print \$2; exit }
  '
}

find_merus_sink() {
  if [ -n "\${MERUS_SINK_PATTERN:-}" ]; then
    pactl list short sinks | awk -v pat="\$MERUS_SINK_PATTERN" '
      \$2 ~ pat { print \$2; exit }
    '
    return
  fi
  pactl list short sinks | awk -v name="\${MERUS_PA_SINK_NAME}" -v card="\${MERUS_ALSA_CARD}" '
    \$2 == name || \$2 ~ card || \$2 ~ /[Mm]erus/ { print \$2; exit }
  '
}

merus_sink_module_index() {
  pactl list short modules | awk -v name="\${MERUS_PA_SINK_NAME}" '
    \$0 ~ ("sink_name=" name) { print \$1; exit }
  '
}

ensure_merus_sink() {
  local sink
  sink="\$(find_merus_sink || true)"
  if [ -n "\$sink" ]; then
    printf '%s' "\$sink"
    return 0
  fi
  if ! aplay -l 2>/dev/null | grep -qF "\${MERUS_ALSA_CARD}"; then
    return 1
  fi
  pactl load-module module-alsa-sink \\
    "device=hw:\${MERUS_ALSA_CARD},0" \\
    "sink_name=\${MERUS_PA_SINK_NAME}" \\
    "sink_properties=device.description=Merus_AMP"
  find_merus_sink || printf '%s' "\${MERUS_PA_SINK_NAME}"
}

loopback_module_index() {
  pactl list short modules | awk '/module-loopback/ { print \$1; exit }'
}

if ! pactl info >/dev/null 2>&1; then
  echo "PulseAudio not ready" >&2
  exit 1
fi

existing="\$(loopback_module_index || true)"
if [ -n "\$existing" ]; then
  exit 0
fi

source="\$(find_usb_source || true)"
sink="\$(ensure_merus_sink || true)"

if [ -z "\$source" ] || [ -z "\$sink" ]; then
  echo "USB source or Merus sink not found (source=\${source:-?} sink=\${sink:-?})" >&2
  exit 1
fi

pactl load-module module-loopback "source=\$source" "sink=\$sink" "latency_msec=\$LOOPBACK_LATENCY_MS"
EOF
  chmod +x "$APPLY_SCRIPT"
}

install_systemd_user() {
  write_apply_script
  mkdir -p "$(dirname "$SYSTEMD_UNIT")"
  cat >"$SYSTEMD_UNIT" <<EOF
[Unit]
Description=USB line-in to Merus AMP (PulseAudio loopback)
After=pulseaudio.service pulseaudio.socket
Wants=pulseaudio.service pulseaudio.socket

[Service]
Type=oneshot
ExecStart=${APPLY_SCRIPT}
RemainAfterExit=yes

[Install]
WantedBy=default.target
EOF
  systemctl --user daemon-reload
  systemctl --user enable --now usb-route.service
  echo "systemd user: usb-route.service enabled"
}

remove_loopback() {
  local idx
  idx="$(loopback_module_index || true)"
  if [ -n "$idx" ]; then
    pactl unload-module "$idx"
    echo "Unloaded PulseAudio module-loopback (#$idx)"
  else
    echo "No module-loopback loaded"
  fi
}

cmd_install() {
  require_command pactl
  require_command arecord

  install_modprobe

  if ! pa_ready; then
    echo "PulseAudio not running — start odio or: systemctl --user start pulseaudio" >&2
    exit 1
  fi

  remove_loopback

  local source sink
  source="$(find_usb_source || true)"
  sink="$(ensure_merus_sink || true)"

  if [ -z "$source" ]; then
    echo "USB source not found. Check:" >&2
    echo "  arecord -l   (expect card named ${USB_ALSA_ID})" >&2
    echo "  pactl list short sources" >&2
    exit 1
  fi

  if [ -z "$sink" ]; then
    echo "Merus sink not found. Check:" >&2
    echo "  aplay -l   (expect ${MERUS_ALSA_CARD})" >&2
    echo "  pactl list short sinks" >&2
    exit 1
  fi

  echo "Loading module-loopback..."
  echo "  source: $source"
  echo "  sink:   $sink"
  echo "  latency: ${LOOPBACK_LATENCY_MS} ms"

  pactl load-module module-loopback \
    "source=${source}" \
    "sink=${sink}" \
    "latency_msec=${LOOPBACK_LATENCY_MS}"

  install_systemd_user

  cat <<EOF

OK. USB → Merus route active.

  Play line-in on the UCA202 — sound should come from Merus speakers.
  Status: install-usb-route.sh --status
  Remove: install-usb-route.sh --remove

If card order is wrong after first install, reboot once (modprobe index=1).
EOF
}

cmd_remove() {
  remove_loopback
  local merus_mod
  merus_mod="$(merus_sink_module_index || true)"
  if [ -n "$merus_mod" ]; then
    pactl unload-module "$merus_mod"
    echo "Unloaded Merus PulseAudio sink module (#$merus_mod)"
  fi
  if systemctl --user is-enabled usb-route.service >/dev/null 2>&1; then
    systemctl --user disable --now usb-route.service
    echo "Disabled usb-route.service"
  fi
  rm -f "$SYSTEMD_UNIT" "$APPLY_SCRIPT"
  systemctl --user daemon-reload 2>/dev/null || true
  echo "Removed USB route persistence."
}

cmd_status() {
  echo "=== ALSA capture (arecord -l) ==="
  arecord -l 2>/dev/null || echo "(arecord unavailable)"
  echo ""
  echo "=== ALSA playback (aplay -l) ==="
  aplay -l 2>/dev/null || echo "(aplay unavailable)"
  echo ""
  if pa_ready; then
    echo "=== PulseAudio sources ==="
    pactl list short sources
    echo ""
    echo "=== PulseAudio sinks ==="
    pactl list short sinks
    echo ""
    echo "=== module-loopback ==="
    pactl list short modules | grep loopback || echo "(none)"
    echo ""
    local source sink merus_mod
    source="$(find_usb_source || true)"
    sink="$(find_merus_sink || true)"
    merus_mod="$(merus_sink_module_index || true)"
    echo "Detected USB source: ${source:-<not found>}"
    if [ -n "$sink" ]; then
      echo "Detected Merus sink: $sink"
    else
      echo "Detected Merus sink: <not in PulseAudio — run --install to load module-alsa-sink>"
    fi
    if [ -n "$merus_mod" ]; then
      echo "Merus PA module: #$merus_mod (sink_name=${MERUS_PA_SINK_NAME})"
    fi
  else
    echo "PulseAudio: not running"
  fi
  echo ""
  if [ -f "$MODPROBE_FILE" ]; then
    echo "modprobe: $MODPROBE_FILE"
    cat "$MODPROBE_FILE"
  else
    echo "modprobe: not installed"
  fi
  if systemctl --user is-active usb-route.service >/dev/null 2>&1; then
    echo "systemd: usb-route.service active"
  elif systemctl --user is-enabled usb-route.service >/dev/null 2>&1; then
    echo "systemd: usb-route.service enabled (inactive)"
  else
    echo "systemd: usb-route.service not installed"
  fi
}

cmd_test_alsaloop() {
  require_command alsaloop
  echo "Diagnostic only — stops PulseAudio and monopolizes Merus hw:"
  systemctl --user stop pulseaudio.service pulseaudio.socket 2>/dev/null || true
  sleep 1
  echo "Running: alsaloop -C plughw:${USB_ALSA_ID},0 -P hw:${MERUS_ALSA_CARD},0 -t 50000"
  echo "Ctrl+C to stop, then: systemctl --user start pulseaudio"
  exec alsaloop -C "plughw:${USB_ALSA_ID},0" -P "hw:${MERUS_ALSA_CARD},0" -t 50000
}

ACTION="install"
for arg in "$@"; do
  case "$arg" in
    -h | --help)
      usage
      exit 0
      ;;
    --install)
      ACTION="install"
      ;;
    --remove)
      ACTION="remove"
      ;;
    --status)
      ACTION="status"
      ;;
    --test-alsaloop)
      ACTION="test-alsaloop"
      ;;
    *)
      echo "Unknown option: $arg" >&2
      usage >&2
      exit 1
      ;;
  esac
done

case "$ACTION" in
  install) cmd_install ;;
  remove) cmd_remove ;;
  status) cmd_status ;;
  test-alsaloop) cmd_test_alsaloop ;;
esac
