import QtQuick
import Quickshell
import Quickshell.Io
import qs.Common
import qs.Widgets
import qs.Modules.Plugins

PluginComponent {
    id: root
    layerNamespacePlugin: "dictation-ptt"

    property string dictationState: "idle"
    property bool clickBusy: false

    Timer {
        interval: 400
        running: true
        repeat: true
        onTriggered: {
            if (!statusProc.running) {
                statusProc.running = true
            }
        }
    }

    // Clear optimistic busy flag if status caught up or timed out
    Timer {
        id: clickBusyClear
        interval: 1500
        repeat: false
        onTriggered: root.clickBusy = false
    }

    Process {
        id: statusProc
        command: ["dictation-ptt", "status", "--json"]
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                const raw = text.trim()
                if (!raw) {
                    root.dictationState = "idle"
                    return
                }
                try {
                    const obj = JSON.parse(raw)
                    root.dictationState = (obj && obj.state) ? obj.state : "idle"
                } catch (e) {
                    root.dictationState = raw.split(/\s+/)[0] || "idle"
                }
                if (root.dictationState === "listening" || root.dictationState === "idle")
                    root.clickBusy = false
            }
        }
    }

    Component.onCompleted: {
        statusProc.running = true
    }

    function stateIcon() {
        if (root.dictationState === "listening") {
            return "fiber_manual_record"
        }
        if (root.dictationState === "transcribing") {
            return "hourglass_top"
        }
        return "mic"
    }

    function stateColor() {
        if (root.dictationState === "listening") {
            return Theme.error
        }
        if (root.dictationState === "transcribing") {
            return Theme.warning
        }
        return Theme.surfaceText
    }

    pillClickAction: () => {
        if (root.dictationState === "transcribing" || root.clickBusy)
            return
        root.clickBusy = true
        clickBusyClear.restart()
        // Optimistic UI feedback
        if (root.dictationState === "idle")
            root.dictationState = "listening"
        else if (root.dictationState === "listening")
            root.dictationState = "transcribing"
        Quickshell.execDetached(["dictation-ptt", "toggle"])
        statusProc.running = true
    }

    horizontalBarPill: Component {
        Row {
            spacing: Theme.spacingXS

            DankIcon {
                name: root.stateIcon()
                size: Theme.iconSize - 6
                color: root.stateColor()
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }

    verticalBarPill: Component {
        Column {
            spacing: Theme.spacingXS

            DankIcon {
                name: root.stateIcon()
                size: Theme.iconSize - 6
                color: root.stateColor()
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }
    }
}
