import QtQuick
import Quickshell
import qs.Common
import qs.Widgets
import qs.Modules.Plugins

PluginSettings {
    id: root
    pluginId: "dictationPtt"

    property bool persistReady: false

    Component.onCompleted: {
        const mode = root.loadValue("mode", "toggle");
        if (!mode || String(mode).trim().length === 0)
            root.saveValue("mode", "toggle");
        const key = root.loadValue("keyboard_key", "Pause");
        // Migrate away from Moonlander special-layer ScrollLock default.
        if (!key || String(key).trim().length === 0 || key === "ScrollLock" || key === "Scroll_Lock")
            root.saveValue("keyboard_key", "Pause");
        Qt.callLater(() => {
            root.persistReady = true;
            root.persistCliConfig();
        });
    }

    onSettingChanged: {
        if (!persistReady)
            return;
        persistTimer.restart();
    }

    Timer {
        id: persistTimer
        interval: 250
        repeat: false
        onTriggered: root.persistCliConfig()
    }

    function asBoolString(value, fallback) {
        if (value === undefined || value === null || value === "")
            return fallback ? "true" : "false";
        if (typeof value === "boolean")
            return value ? "true" : "false";
        const s = String(value).toLowerCase();
        if (s === "true" || s === "1" || s === "yes" || s === "on")
            return "true";
        if (s === "false" || s === "0" || s === "no" || s === "off")
            return "false";
        return fallback ? "true" : "false";
    }

    function asIntString(value, fallback) {
        const n = parseInt(value, 10);
        if (isNaN(n) || n < 0)
            return String(fallback);
        return String(n);
    }

    function persistCliConfig() {
        const mode = String(root.loadValue("mode", "toggle") || "toggle");
        const keyboardKey = String(root.loadValue("keyboard_key", "Pause") || "Pause");
        const silenceEnabled = root.asBoolString(root.loadValue("silence_enabled", true), true);
        const silenceMs = root.asIntString(root.loadValue("silence_ms", "2500"), 2500);
        const maxEnabled = root.asBoolString(root.loadValue("max_duration_enabled", true), true);
        const maxSec = root.asIntString(root.loadValue("max_sec", "180"), 180);
        const keyboardDaemon = root.asBoolString(root.loadValue("keyboard_daemon", true), true);

        Quickshell.execDetached([
            "bash", "-c",
            'set -euo pipefail
             mode="$1"; key="$2"; se="$3"; sms="$4"; me="$5"; msec="$6"; kd="$7"
             for d in \
               "$(dirname "$(readlink -f "$(command -v dictation-ptt)")")/../lib/dictation-ptt" \
               "$HOME/etc/nixos/scripts/ai/dictation-ptt"; do
               if [[ -f "$d/write-cli-config.sh" ]]; then
                 exec bash "$d/write-cli-config.sh" "$mode" "$key" "$se" "$sms" "$me" "$msec" "$kd"
               fi
             done
             true',
            "_", mode, keyboardKey, silenceEnabled, silenceMs, maxEnabled, maxSec, keyboardDaemon
        ]);
    }

    function runRecovery(cmd) {
        Quickshell.execDetached(["dictation-ptt", cmd]);
    }

    function restartBackends() {
        // System units; may require privileges — best-effort, ignore failures.
        Quickshell.execDetached([
            "bash", "-c",
            "systemctl restart parakeet-asr whisper-cpp-asr 2>/dev/null || true; systemctl --user restart parakeet-asr whisper-cpp-asr 2>/dev/null || true"
        ]);
    }

    StyledText {
        width: parent.width
        text: "Dictation PTT"
        font.pixelSize: Theme.fontSizeLarge
        font.weight: Font.Bold
        color: Theme.surfaceText
    }

    StyledText {
        width: parent.width
        text: "Hold/toggle for Stream Deck + keyboard daemon (evdev). Settings write config, sync Deck fragment, and restart dictation-ptt-keys."
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.surfaceVariantText
        wrapMode: Text.WordWrap
    }

    Rectangle {
        width: parent.width
        height: 1
        color: Theme.outline
        opacity: 0.3
    }

    SelectionSetting {
        settingKey: "mode"
        label: "Trigger mode"
        description: "toggle = each press flips listening (default). hold = press/release start/stop (Stream Deck + keyboard via dictation-ptt-keys). Changing mode rewrites the Deck key and relaunches StreamController."
        options: [
            {
                label: "Toggle",
                value: "toggle"
            },
            {
                label: "Hold",
                value: "hold"
            }
        ]
        defaultValue: "toggle"
    }

    StringSetting {
        settingKey: "keyboard_key"
        label: "Keyboard key"
        description: "Linux key name for evdev PTT (default Pause). Avoid ScrollLock on Moonlander special layers. Examples: Pause, F13, Insert."
        placeholder: "Pause"
        defaultValue: "Pause"
    }

    ToggleSetting {
        settingKey: "keyboard_daemon"
        label: "Keyboard daemon (evdev PTT)"
        description: value ? "dictation-ptt-keys listens for real press/release — keep ON for keyboard PTT." : "OFF disables keyboard PTT (niri fallback only)."
        defaultValue: true
    }

    Rectangle {
        width: parent.width
        height: 1
        color: Theme.outline
        opacity: 0.3
    }

    ToggleSetting {
        settingKey: "silence_enabled"
        label: "Silence auto-stop"
        description: value ? "Stop listening after quiet period." : "Silence watcher disabled."
        defaultValue: true
    }

    StringSetting {
        settingKey: "silence_ms"
        label: "Silence timeout (ms)"
        description: "Quiet period before auto-stop while listening."
        placeholder: "2500"
        defaultValue: "2500"
    }

    ToggleSetting {
        settingKey: "max_duration_enabled"
        label: "Max duration"
        description: value ? "Hard cap on listening length." : "No max listening duration."
        defaultValue: true
    }

    StringSetting {
        settingKey: "max_sec"
        label: "Max duration (seconds)"
        description: "Forced stop after this many seconds of listening."
        placeholder: "180"
        defaultValue: "180"
    }

    Rectangle {
        width: parent.width
        height: 1
        color: Theme.outline
        opacity: 0.3
    }

    StyledText {
        width: parent.width
        text: "Recovery"
        font.pixelSize: Theme.fontSizeMedium
        font.weight: Font.Medium
        color: Theme.surfaceText
    }

    StyledText {
        width: parent.width
        text: "Use when dictation is stuck (listening/transcribing) or WAV cache is large."
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.surfaceVariantText
        wrapMode: Text.WordWrap
    }

    Flow {
        width: parent.width
        spacing: Theme.spacingS

        DankButton {
            text: "Force stop"
            iconName: "stop_circle"
            onClicked: root.runRecovery("force-stop")
        }

        DankButton {
            text: "Cancel"
            iconName: "cancel"
            onClicked: root.runRecovery("cancel")
        }

        DankButton {
            text: "Clean"
            iconName: "delete"
            onClicked: root.runRecovery("clean")
        }

        DankButton {
            text: "Reset"
            iconName: "restart_alt"
            onClicked: root.runRecovery("reset")
        }

        DankButton {
            text: "Restart backends"
            iconName: "dns"
            onClicked: root.restartBackends()
        }
    }

    DankButton {
        text: "Write config now"
        iconName: "save"
        onClicked: root.persistCliConfig()
    }
}
