import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components 3.0 as PlasmaComponents3
import org.kde.kirigami as Kirigami
import "../code/ffxi.js" as FFXI

PlasmoidItem {
    id: root

    property var data: FFXI.snapshot(Date.now())
    property color accent: "#65b985"

    // KDE desktop containments use plain width/height for initial widget size.
    // Layout.preferredWidth/Height only size panel widgets and popups.
    width: PlasmaCore.Units.gridUnit * 24
    height: PlasmaCore.Units.gridUnit * 29
    Layout.minimumWidth: PlasmaCore.Units.gridUnit * 18
    Layout.minimumHeight: PlasmaCore.Units.gridUnit * 22

    preferredRepresentation: fullRepresentation
    switchWidth: PlasmaCore.Units.gridUnit * 13
    switchHeight: PlasmaCore.Units.gridUnit * 10

    function refresh() {
        data = FFXI.snapshot(Date.now())
    }

    function localDate(date) {
        return Qt.formatDateTime(date, "ddd MMM d, h:mm AP")
    }

    function padRight(value, width) {
        var output = "" + value
        while (output.length < width) output += " "
        return output
    }

    function guildLines() {
        var lines = []
        for (var i = 0; i < data.guilds.length; i++) {
            var guild = data.guilds[i]
            var state = guild.isHoliday ? "HOLIDAY" : (guild.isOpen ? "OPEN" : "CLOSED")
            var countdown = guild.label + " " + FFXI.formatDuration(guild.countdownMs, true)
            lines.push(padRight(guild.name, 14) + padRight(state, 10) + countdown)
        }
        return lines.join("\n")
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    compactRepresentation: MouseArea {
        id: compact
        implicitWidth: PlasmaCore.Units.gridUnit * 7
        implicitHeight: PlasmaCore.Units.gridUnit * 3
        onClicked: root.expanded = !root.expanded

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: PlasmaCore.Units.smallSpacing
            spacing: 0

            PlasmaComponents3.Label {
                Layout.fillWidth: true
                text: root.data.vana.clock
                color: root.data.vana.dayColor
                font.family: "monospace"
                font.pixelSize: Math.max(12, compact.height * 0.32)
                font.weight: Font.DemiBold
                horizontalAlignment: Text.AlignHCenter
            }

            PlasmaComponents3.Label {
                Layout.fillWidth: true
                text: root.data.vana.dayName + "  •  " + root.data.moon.percent + "% moon"
                opacity: 0.78
                font.pixelSize: Math.max(9, compact.height * 0.17)
                elide: Text.ElideRight
                horizontalAlignment: Text.AlignHCenter
            }
        }
    }

    fullRepresentation: Item {
        implicitWidth: PlasmaCore.Units.gridUnit * 23
        implicitHeight: PlasmaCore.Units.gridUnit * 29
        Layout.minimumWidth: PlasmaCore.Units.gridUnit * 18
        Layout.minimumHeight: PlasmaCore.Units.gridUnit * 19

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: PlasmaCore.Units.largeSpacing
            spacing: PlasmaCore.Units.smallSpacing

            RowLayout {
                Layout.fillWidth: true

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    PlasmaComponents3.Label {
                        text: "VANA'DIEL"
                        opacity: 0.62
                        font.pixelSize: PlasmaCore.Theme.smallestFont.pixelSize
                        font.capitalization: Font.AllUppercase
                        font.letterSpacing: 1.2
                    }

                    PlasmaComponents3.Label {
                        text: root.data.vana.clock
                        color: root.data.vana.dayColor
                        font.family: "monospace"
                        font.pixelSize: PlasmaCore.Units.gridUnit * 2.25
                        font.weight: Font.DemiBold
                    }

                    PlasmaComponents3.Label {
                        text: root.data.vana.dayName + "  " + root.data.vana.calendar
                        opacity: 0.82
                    }
                }

                PlasmaComponents3.ToolButton {
                    icon.name: "internet-web-browser"
                    display: QQC2.AbstractButton.IconOnly
                    text: "Open Pyogenes FFXI Timer"
                    onClicked: Qt.openUrlExternally("https://www.pyogenes.com/ffxi/timer/v2.html")
                    QQC2.ToolTip.visible: hovered
                    QQC2.ToolTip.text: text
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: PlasmaCore.Theme.textColor
                opacity: 0.14
            }

            GridLayout {
                Layout.fillWidth: true
                columns: width > PlasmaCore.Units.gridUnit * 20 ? 2 : 1
                columnSpacing: PlasmaCore.Units.largeSpacing
                rowSpacing: PlasmaCore.Units.smallSpacing

                InfoBlock {
                    Layout.fillWidth: true
                    title: root.data.moon.name + "  " + root.data.moon.percent + "%"
                    subtitle: "Next " + root.data.moon.nextName + " in " + FFXI.formatDuration(root.data.moon.nextMs, true)
                    detail: "Next " + root.data.moon.optimalName + " in " + FFXI.formatDuration(root.data.moon.optimalMs, false)
                    iconName: root.data.moon.phase === 4 ? "weather-clear-night" : "weather-few-clouds-night"
                }

                InfoBlock {
                    Layout.fillWidth: true
                    title: "Conquest tally"
                    subtitle: FFXI.formatDuration(root.data.conquest.leftMs, true)
                    detail: root.localDate(root.data.conquest.at) + "  •  " + root.data.conquest.vanaDays + " Vana'diel days"
                    iconName: "flag"
                }
            }

            PlasmaComponents3.Label {
                Layout.topMargin: PlasmaCore.Units.smallSpacing
                text: "CRAFTING GUILDS"
                opacity: 0.62
                font.pixelSize: PlasmaCore.Theme.smallestFont.pixelSize
                font.capitalization: Font.AllUppercase
                font.letterSpacing: 1.2
            }

            Item {
                id: guildArea
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true

                PlasmaComponents3.Label {
                    anchors.fill: parent
                    text: root.data ? root.guildLines() : ""
                    textFormat: Text.PlainText
                    font.family: "monospace"
                    font.pixelSize: PlasmaCore.Theme.smallestFont.pixelSize
                    lineHeight: 1.3
                    lineHeightMode: Text.ProportionalHeight
                    verticalAlignment: Text.AlignTop
                    wrapMode: Text.NoWrap
                }
            }

            PlasmaComponents3.Label {
                Layout.fillWidth: true
                text: "Calculations credited to Pyogenes • updates every second"
                opacity: 0.45
                font.pixelSize: PlasmaCore.Theme.smallestFont.pixelSize
                horizontalAlignment: Text.AlignRight
            }
        }
    }

    component InfoBlock: RowLayout {
        id: block
        property string title
        property string subtitle
        property string detail
        property string iconName

        spacing: PlasmaCore.Units.smallSpacing

        Kirigami.Icon {
            Layout.preferredWidth: PlasmaCore.Units.iconSizes.medium
            Layout.preferredHeight: PlasmaCore.Units.iconSizes.medium
            source: block.iconName
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            PlasmaComponents3.Label {
                Layout.fillWidth: true
                text: block.title
                font.weight: Font.DemiBold
                elide: Text.ElideRight
            }
            PlasmaComponents3.Label {
                Layout.fillWidth: true
                text: block.subtitle
                font.family: "monospace"
                opacity: 0.84
                elide: Text.ElideRight
            }
            PlasmaComponents3.Label {
                Layout.fillWidth: true
                text: block.detail
                opacity: 0.55
                font.pixelSize: PlasmaCore.Theme.smallestFont.pixelSize
                elide: Text.ElideRight
            }
        }
    }
}
