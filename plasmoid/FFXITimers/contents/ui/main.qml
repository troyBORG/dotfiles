import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import QtMultimedia
import org.kde.plasma.plasmoid
import org.kde.plasma.components 3.0 as PlasmaComponents3
import org.kde.kirigami as Kirigami
import "../code/ffxi.js" as FFXI

PlasmoidItem {
    id: root

    property var timerData: FFXI.snapshot(Date.now())
    property color accent: "#65b985"
    property int selectedView: 0
    property bool mhauraAlertArmed: false
    property int mhauraAlertsRemaining: 0
    property bool nashmauAlertArmed: false
    property int nashmauAlertsRemaining: 0

    // KDE desktop containments use plain width/height for initial widget size.
    // Layout.preferredWidth/Height only size panel widgets and popups.
    width: Kirigami.Units.gridUnit * 24
    height: Kirigami.Units.gridUnit * 29
    Layout.minimumWidth: Kirigami.Units.gridUnit * 18
    Layout.minimumHeight: Kirigami.Units.gridUnit * 22

    preferredRepresentation: fullRepresentation
    switchWidth: Kirigami.Units.gridUnit * 13
    switchHeight: Kirigami.Units.gridUnit * 10

    function refresh() {
        var nextData = FFXI.snapshot(Date.now())
        if (timerData) {
            processFerryTransition(
                "mhaura",
                timerData.boats.mhauraWhitegateState,
                nextData.boats.mhauraWhitegateState
            )
            processFerryTransition(
                "nashmau",
                timerData.boats.nashmauWhitegateState,
                nextData.boats.nashmauWhitegateState
            )
        }
        timerData = nextData
    }

    function processFerryTransition(route, previous, current) {
        var remaining = route === "mhaura" ? mhauraAlertsRemaining : nashmauAlertsRemaining
        var result = FFXI.advanceFerryAlert(previous.state, current.state, remaining)
        if (!result.triggered) return

        shipAlert.play()
        if (route === "mhaura") {
            mhauraAlertsRemaining = result.remaining
            mhauraAlertArmed = result.armed
        } else {
            nashmauAlertsRemaining = result.remaining
            nashmauAlertArmed = result.armed
        }
    }

    function toggleFerryAlert(route, state) {
        if (route === "mhaura") {
            mhauraAlertArmed = !mhauraAlertArmed
            mhauraAlertsRemaining = mhauraAlertArmed ? (state === "boarding" ? 1 : 2) : 0
        } else {
            nashmauAlertArmed = !nashmauAlertArmed
            nashmauAlertsRemaining = nashmauAlertArmed ? (state === "boarding" ? 1 : 2) : 0
        }
    }

    onSelectedViewChanged: contentFlick.contentY = 0

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
        for (var i = 0; i < timerData.guilds.length; i++) {
            var guild = timerData.guilds[i]
            var state = guild.isHoliday ? "HOLIDAY" : (guild.isOpen ? "OPEN" : "CLOSED")
            var countdown = guild.label + " " + FFXI.formatDuration(guild.countdownMs, true)
            lines.push(padRight(guild.name, 14) + padRight(state, 10) + countdown)
        }
        return lines.join("\n")
    }

    function airshipLines() {
        var lines = []
        for (var i = 0; i < timerData.airships.length; i++) {
            var ship = timerData.airships[i]
            lines.push(padRight(ship.name, 22) + "Departs " + FFXI.formatDuration(ship.departureMs, true))
        }
        return lines.join("\n")
    }

    function boatLines() {
        var lines = []
        lines.push(padRight("Selbina ↔ Mhaura", 23).replace(/ /g, "&nbsp;") + FFXI.formatDuration(timerData.boats.ferryDepartureMs, true))
        lines.push("")
        lines.push("MANACLIPPER / CLAMMING")
        for (var i = 0; i < Math.min(4, timerData.boats.manaclipper.length); i++) {
            var boat = timerData.boats.manaclipper[i]
            lines.push(padRight(boat.name, 22).replace(/ /g, "&nbsp;") + boat.departure + "&nbsp;&nbsp;in&nbsp;" + FFXI.formatDuration(boat.departureMs, true))
        }
        return lines.join("<br>")
    }

    function ferryLine(name, route) {
        var status = route.state === "boarding" ? "BOARDING · departs " : "IN TRANSIT · arrives "
        var color = route.state === "boarding" ? "#65b985" : "#58a6d6"
        return "<font color=\"" + color + "\">" + padRight(name, 23).replace(/ /g, "&nbsp;") + status + FFXI.formatDuration(route.countdownMs, true) + "</font>"
    }

    function activeLines() {
        if (selectedView === 1) return airshipLines()
        if (selectedView === 2) return boatLines()
        return guildLines()
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    SoundEffect {
        id: shipAlert
        source: Qt.resolvedUrl("../assets/ship-alert.wav")
        volume: 0.85
    }

    compactRepresentation: MouseArea {
        id: compact
        implicitWidth: Kirigami.Units.gridUnit * 7
        implicitHeight: Kirigami.Units.gridUnit * 3
        onClicked: root.expanded = !root.expanded

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Kirigami.Units.smallSpacing
            spacing: 0

            PlasmaComponents3.Label {
                Layout.fillWidth: true
                text: root.timerData.vana.clock
                color: root.timerData.vana.dayColor
                font.family: "monospace"
                font.pixelSize: Math.max(12, compact.height * 0.32)
                font.weight: Font.DemiBold
                horizontalAlignment: Text.AlignHCenter
            }

            PlasmaComponents3.Label {
                Layout.fillWidth: true
                text: root.timerData.vana.dayName + "  •  " + root.timerData.moon.percent + "% moon"
                opacity: 0.78
                font.pixelSize: Math.max(9, compact.height * 0.17)
                elide: Text.ElideRight
                horizontalAlignment: Text.AlignHCenter
            }
        }
    }

    fullRepresentation: Item {
        implicitWidth: Kirigami.Units.gridUnit * 23
        implicitHeight: Kirigami.Units.gridUnit * 29
        Layout.minimumWidth: Kirigami.Units.gridUnit * 18
        Layout.minimumHeight: Kirigami.Units.gridUnit * 19

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Kirigami.Units.largeSpacing
            spacing: Kirigami.Units.smallSpacing

            RowLayout {
                Layout.fillWidth: true

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    PlasmaComponents3.Label {
                        text: "VANA'DIEL"
                        opacity: 0.62
                        font.pixelSize: Math.max(9, Kirigami.Units.gridUnit * 0.65)
                        font.capitalization: Font.AllUppercase
                        font.letterSpacing: 1.2
                    }

                    PlasmaComponents3.Label {
                        text: root.timerData.vana.clock
                        color: root.timerData.vana.dayColor
                        font.family: "monospace"
                        font.pixelSize: Kirigami.Units.gridUnit * 2.25
                        font.weight: Font.DemiBold
                    }

                    PlasmaComponents3.Label {
                        text: root.timerData.vana.dayName + "  " + root.timerData.vana.calendar
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
                color: Kirigami.Theme.textColor
                opacity: 0.14
            }

            GridLayout {
                Layout.fillWidth: true
                columns: width > Kirigami.Units.gridUnit * 20 ? 2 : 1
                columnSpacing: Kirigami.Units.largeSpacing
                rowSpacing: Kirigami.Units.smallSpacing

                InfoBlock {
                    Layout.fillWidth: true
                    title: root.timerData.moon.name + "  " + root.timerData.moon.percent + "%"
                    subtitle: "Next: " + root.timerData.moon.nextName + " in " + FFXI.formatDuration(root.timerData.moon.nextMs, false)
                    detail: root.timerData.moon.optimalName + " in " + FFXI.formatDuration(root.timerData.moon.optimalMs, false)
                    iconName: "weather-clear-night"
                }

                InfoBlock {
                    Layout.fillWidth: true
                    title: "Conquest tally"
                    subtitle: FFXI.formatDuration(root.timerData.conquest.leftMs, true)
                    detail: root.localDate(root.timerData.conquest.at)
                    iconName: "flag"
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing

                PlasmaComponents3.Button {
                    Layout.fillWidth: true
                    text: "Guilds"
                    checkable: true
                    checked: root.selectedView === 0
                    onClicked: root.selectedView = 0
                }
                PlasmaComponents3.Button {
                    Layout.fillWidth: true
                    text: "Airships"
                    checkable: true
                    checked: root.selectedView === 1
                    onClicked: root.selectedView = 1
                }
                PlasmaComponents3.Button {
                    Layout.fillWidth: true
                    text: "Boats"
                    checkable: true
                    checked: root.selectedView === 2
                    onClicked: root.selectedView = 2
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                visible: root.selectedView === 2
                spacing: 0

                PlasmaComponents3.Label {
                    text: "FERRIES"
                    font.family: "monospace"
                    font.pixelSize: Math.max(9, Kirigami.Units.gridUnit * 0.65)
                }

                FerryAlertRow {
                    Layout.fillWidth: true
                    routeName: "Mhaura ↔ Whitegate"
                    routeState: root.timerData.boats.mhauraWhitegateState
                    armed: root.mhauraAlertArmed
                    alertsRemaining: root.mhauraAlertsRemaining
                    onToggled: root.toggleFerryAlert("mhaura", routeState.state)
                }

                FerryAlertRow {
                    Layout.fillWidth: true
                    routeName: "Nashmau ↔ Whitegate"
                    routeState: root.timerData.boats.nashmauWhitegateState
                    armed: root.nashmauAlertArmed
                    alertsRemaining: root.nashmauAlertsRemaining
                    onToggled: root.toggleFerryAlert("nashmau", routeState.state)
                }
            }

            Flickable {
                id: contentFlick
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                contentWidth: width
                contentHeight: timerLabel.implicitHeight
                boundsBehavior: Flickable.StopAtBounds
                flickableDirection: Flickable.VerticalFlick
                QQC2.ScrollBar.vertical: QQC2.ScrollBar {
                    policy: QQC2.ScrollBar.AlwaysOff
                }

                PlasmaComponents3.Label {
                    id: timerLabel
                    width: contentFlick.width
                    height: implicitHeight
                    text: root.timerData ? root.activeLines() : ""
                    textFormat: root.selectedView === 2 ? Text.StyledText : Text.PlainText
                    font.family: "monospace"
                    font.pixelSize: Math.max(9, Kirigami.Units.gridUnit * 0.65)
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
                font.pixelSize: Math.max(9, Kirigami.Units.gridUnit * 0.65)
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

        spacing: Kirigami.Units.smallSpacing

        Kirigami.Icon {
            Layout.preferredWidth: Kirigami.Units.iconSizes.medium
            Layout.preferredHeight: Kirigami.Units.iconSizes.medium
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
                font.pixelSize: Math.max(9, Kirigami.Units.gridUnit * 0.65)
                elide: Text.ElideRight
            }
        }
    }

    component FerryAlertRow: RowLayout {
        id: ferryRow
        required property string routeName
        required property var routeState
        required property bool armed
        required property int alertsRemaining
        signal toggled()

        spacing: Kirigami.Units.smallSpacing

        PlasmaComponents3.Label {
            Layout.fillWidth: true
            text: root.ferryLine(ferryRow.routeName, ferryRow.routeState)
            textFormat: Text.StyledText
            font.family: "monospace"
            font.pixelSize: Math.max(9, Kirigami.Units.gridUnit * 0.65)
            elide: Text.ElideRight
        }

        PlasmaComponents3.ToolButton {
            checkable: true
            checked: ferryRow.armed
            icon.name: ferryRow.armed ? "notifications" : "notifications-disabled"
            text: ferryRow.armed ? "Cancel ship alert" : "Arm ship alert"
            onClicked: ferryRow.toggled()
            QQC2.ToolTip.visible: hovered
            QQC2.ToolTip.text: ferryRow.armed
                ? "Armed for " + ferryRow.alertsRemaining + " arrival" + (ferryRow.alertsRemaining === 1 ? "" : "s")
                : (ferryRow.routeState.state === "boarding"
                    ? "Alert when this trip reaches its destination"
                    : "Alert when boarding starts, then again at the destination")
        }
    }
}
