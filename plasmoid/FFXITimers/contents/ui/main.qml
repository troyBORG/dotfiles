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

    preferredRepresentation: fullRepresentation
    switchWidth: PlasmaCore.Units.gridUnit * 13
    switchHeight: PlasmaCore.Units.gridUnit * 10

    function refresh() {
        data = FFXI.snapshot(Date.now())
    }

    function localDate(date) {
        return Qt.formatDateTime(date, "ddd MMM d, h:mm AP")
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

                GuildRow { rowNumber: 0; guild: root.data.guilds[0] }
                GuildRow { rowNumber: 1; guild: root.data.guilds[1] }
                GuildRow { rowNumber: 2; guild: root.data.guilds[2] }
                GuildRow { rowNumber: 3; guild: root.data.guilds[3] }
                GuildRow { rowNumber: 4; guild: root.data.guilds[4] }
                GuildRow { rowNumber: 5; guild: root.data.guilds[5] }
                GuildRow { rowNumber: 6; guild: root.data.guilds[6] }
                GuildRow { rowNumber: 7; guild: root.data.guilds[7] }
                GuildRow { rowNumber: 8; guild: root.data.guilds[8] }
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

    component GuildRow: Rectangle {
        id: guildRow
        required property var guild
        required property int rowNumber
        readonly property real rowHeight: PlasmaCore.Units.gridUnit * 1.7

        x: 0
        y: rowNumber * rowHeight
        width: parent ? parent.width : 0
        height: rowHeight
        radius: PlasmaCore.Units.smallSpacing
        color: guild.isOpen ? Qt.rgba(0.18, 0.55, 0.34, 0.13) : "transparent"

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: PlasmaCore.Units.smallSpacing
            anchors.rightMargin: PlasmaCore.Units.smallSpacing
            spacing: PlasmaCore.Units.smallSpacing

            Rectangle {
                Layout.preferredWidth: 7
                Layout.preferredHeight: 7
                radius: 4
                color: guildRow.guild.isOpen ? root.accent : PlasmaCore.Theme.disabledTextColor
            }

            PlasmaComponents3.Label {
                Layout.fillWidth: true
                text: guildRow.guild.name
                font.weight: guildRow.guild.isOpen ? Font.DemiBold : Font.Normal
                elide: Text.ElideRight
            }

            PlasmaComponents3.Label {
                text: guildRow.guild.isHoliday ? "Holiday" : (guildRow.guild.isOpen ? "Open" : "Closed")
                color: guildRow.guild.isOpen ? root.accent : PlasmaCore.Theme.textColor
                opacity: guildRow.guild.isOpen ? 1.0 : 0.58
                font.pixelSize: PlasmaCore.Theme.smallestFont.pixelSize
            }

            PlasmaComponents3.Label {
                Layout.preferredWidth: PlasmaCore.Units.gridUnit * 6.3
                text: guildRow.guild.label + " " + FFXI.formatDuration(guildRow.guild.countdownMs, true)
                horizontalAlignment: Text.AlignRight
                font.family: "monospace"
                font.pixelSize: PlasmaCore.Theme.smallestFont.pixelSize
                opacity: 0.78
            }
        }

        QQC2.ToolTip.visible: hover.hovered
        QQC2.ToolTip.text: guild.hours + " • Holiday: " + guild.holiday

        HoverHandler { id: hover }
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
