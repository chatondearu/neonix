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

    Process {
        id: statusProc
        command: ["dictation-ptt", "status"]
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                const state = text.trim()
                root.dictationState = state || "idle"
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
        Quickshell.execDetached(["dictation-ptt", "toggle"])
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
