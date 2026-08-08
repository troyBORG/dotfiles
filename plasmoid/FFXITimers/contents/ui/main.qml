import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.plasma.plasmoid
import org.kde.plasma.components 3.0 as PlasmaComponents3
import org.kde.kirigami as Kirigami
import org.kde.notification
import "../code/ffxi.js" as FFXI

PlasmoidItem {
    id: root

    property var timerData: FFXI.snapshot(Date.now())
    property color accent: "#65b985"
    property int selectedView: 0
    property var alertStages: ({})

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
        if (timerData) processTransportTransitions(timerData, nextData)
        timerData = nextData
    }

    function allRoutes(data) {
        return data.airships.concat(data.boats)
    }

    function routeById(routes, id) {
        for (var i = 0; i < routes.length; i++) {
            if (routes[i].id === id) return routes[i]
        }
        return null
    }

    function copyAlertStages() {
        var copy = {}
        for (var key in alertStages) copy[key] = alertStages[key]
        return copy
    }

    function processTransportTransitions(previousData, currentData) {
        var previousRoutes = allRoutes(previousData)
        var currentRoutes = allRoutes(currentData)
        var nextStages = copyAlertStages()
        var changed = false

        for (var id in alertStages) {
            var previous = routeById(previousRoutes, id)
            var current = routeById(currentRoutes, id)
            if (!previous || !current) continue

            var stage = alertStages[id]
            var result = FFXI.advanceTransportAlert(previous.state, current.state, stage)
            if (!result.triggered) continue

            sendTransportNotification(current, stage)
            changed = true
            if (result.stage) nextStages[id] = result.stage
            else delete nextStages[id]
        }

        if (changed) alertStages = nextStages
    }

    function toggleTransportAlert(route) {
        var nextStages = copyAlertStages()
        if (nextStages[route.id]) delete nextStages[route.id]
        else nextStages[route.id] = route.state === "boarding" ? "arrival" : "boarding"
        alertStages = nextStages
    }

    function transportRoutes() {
        return selectedView === 1 ? timerData.airships : timerData.boats
    }

    function transportLine(route) {
        var status
        var color
        if (route.state === "boarding") {
            status = "BOARDING "
            color = "#65b985"
        } else if (route.state === "transit") {
            status = "IN TRANSIT "
            color = "#58a6d6"
        } else {
            status = "BOARDS "
            color = "#dedede"
        }
        return "<font color=\"" + color + "\">" + status + FFXI.formatDuration(route.countdownMs, true) + "</font>"
    }

    function alertTooltip(route) {
        var stage = alertStages[route.id]
        if (stage === "boarding") return "Armed for boarding, then destination arrival"
        if (stage === "arrival") return "Armed for destination arrival"
        return route.state === "boarding"
            ? "Alert at destination arrival"
            : "Alert when boarding starts, then again at the destination"
    }

    function sendTransportNotification(route, stage) {
        transportNotification.title = stage === "boarding" ? "Transport boarding" : "Destination reached"
        transportNotification.text = stage === "boarding"
            ? route.name + " is boarding now."
            : route.name + " has arrived."
        transportNotification.sendEvent()
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

    function activeLines() {
        return guildLines()
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    Notification {
        id: transportNotification
        componentName: "plasma_workspace"
        eventId: "notification"
        flags: Notification.CloseOnTimeout
        urgency: Notification.NormalUrgency
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

            Flickable {
                id: contentFlick
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                contentWidth: width
                contentHeight: root.selectedView === 0 ? timerLabel.implicitHeight : routeColumn.implicitHeight
                boundsBehavior: Flickable.StopAtBounds
                flickableDirection: Flickable.VerticalFlick
                QQC2.ScrollBar.vertical: QQC2.ScrollBar {
                    policy: QQC2.ScrollBar.AlwaysOff
                }

                PlasmaComponents3.Label {
                    id: timerLabel
                    visible: root.selectedView === 0
                    width: contentFlick.width
                    height: visible ? implicitHeight : 0
                    text: root.timerData ? root.activeLines() : ""
                    textFormat: Text.PlainText
                    font.family: "monospace"
                    font.pixelSize: Math.max(9, Kirigami.Units.gridUnit * 0.65)
                    lineHeight: 1.3
                    lineHeightMode: Text.ProportionalHeight
                    verticalAlignment: Text.AlignTop
                    wrapMode: Text.NoWrap
                }

                Column {
                    id: routeColumn
                    visible: root.selectedView !== 0
                    width: contentFlick.width
                    spacing: 0

                    Repeater {
                        model: root.transportRoutes()

                        delegate: TransportAlertRow {
                            required property int index
                            required property var modelData
                            width: routeColumn.width
                            route: modelData
                            showHeader: index === 0 || modelData.group !== root.transportRoutes()[index - 1].group
                        }
                    }
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

    component TransportAlertRow: Column {
        id: transportRow
        required property var route
        required property bool showHeader

        spacing: 0

        PlasmaComponents3.Label {
            visible: transportRow.showHeader
            height: visible ? implicitHeight : 0
            text: transportRow.route.group
            font.family: "monospace"
            font.weight: Font.DemiBold
            font.pixelSize: Math.max(9, Kirigami.Units.gridUnit * 0.65)
            opacity: 0.65
        }

        RowLayout {
            width: transportRow.width
            spacing: Kirigami.Units.smallSpacing

            PlasmaComponents3.Label {
                Layout.fillWidth: true
                text: transportRow.route.name
                font.family: "monospace"
                font.pixelSize: Math.max(9, Kirigami.Units.gridUnit * 0.65)
                elide: Text.ElideRight
            }

            PlasmaComponents3.Label {
                text: root.transportLine(transportRow.route)
                textFormat: Text.StyledText
                font.family: "monospace"
                font.pixelSize: Math.max(9, Kirigami.Units.gridUnit * 0.65)
            }

            PlasmaComponents3.ToolButton {
                Layout.preferredWidth: Kirigami.Units.gridUnit * 1.25
                Layout.preferredHeight: Kirigami.Units.gridUnit * 1.25
                checkable: true
                checked: !!root.alertStages[transportRow.route.id]
                display: QQC2.AbstractButton.IconOnly
                icon.name: checked ? "notifications" : "notifications-disabled"
                text: checked ? "Cancel transport alert" : "Arm transport alert"
                onClicked: root.toggleTransportAlert(transportRow.route)
                QQC2.ToolTip.visible: hovered
                QQC2.ToolTip.text: root.alertTooltip(transportRow.route)
            }
        }
    }
}
