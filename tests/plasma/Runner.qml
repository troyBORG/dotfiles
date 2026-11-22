import QtQuick
import "../../plasmoid/FFXITimers/contents/code/ffxi.js" as FFXI
Item {
    id: test
    required property var widget
    required property var driver
    required property var testWindow
    required property bool isBaseline
    property var flick
    property var rows
    property var originalRows
    property var firstStart
    property var countBefore
    property var now: Date.parse("2026-11-22T19:47:00Z")
    property int step: 0
    function check(ok, message) { if (!ok) throw new Error(message) }
    function all(item) {
        var out = [item]
        if (item.children) for (var i=0;i<item.children.length;i++) out = out.concat(all(item.children[i]))
        return out
    }
    function button(label) { return all(widget.fullRepresentationItem).filter(x => x.text === label && x.checkable !== undefined)[0] }
    function click(label, view) { driver.click(button(label)); check(widget.selectedView === view, "actual click: " + label) }
    function setTime(ms) { widget.timerData = FFXI.snapshot(ms) }
    function activeRows() { return all(widget.fullRepresentationItem).filter(x => x.dayInfo !== undefined) }
    function fitsButtons() {
        var labels = isBaseline ? ["Guilds","Airships","Boats"] : ["Guilds","Airships","Boats","Days"]
        for(var label of labels) {
            var b = button(label)
            check(b.visible && b.width > 0 && b.height > 0, label + " visible")
            check(b.contentItem.implicitWidth <= b.contentItem.width + 1, label + " text fits")
            var pos = b.mapToItem(widget.fullRepresentationItem, 0,0)
            check(pos.x >= 0 && pos.x+b.width <= widget.width+1, label + " bounds")
        }
    }
    function geometry() {
        return all(widget.fullRepresentationItem).filter(x => x.text !== undefined && x.visible).map(x => {
            var p=x.mapToItem(widget.fullRepresentationItem,0,0)
            return {text:x.text,x:p.x,y:p.y,w:x.width,h:x.height,pixelSize:x.font ? x.font.pixelSize:0}
        })
    }
    Timer {
        interval: 180; running: true; repeat: true
        onTriggered: {
            try {
                if(step === 0) {
                    check(widget.fullRepresentationItem !== null,"real fullRepresentation loaded")
                    driver.stopTimers(widget)
                    widget.horizonStatus = "online"; widget.horizonPlayers=1509
                    setTime(now)
                    check(widget.selectedView === 0,"Guilds initial default")
                    click("Airships",1)
                } else if(step === 1) {
                    fitsButtons()
                    driver.capture(isBaseline ? "isBaseline-airships.png" : "candidate-airships.png")
                    driver.save(isBaseline ? "isBaseline-geometry.json" : "candidate-geometry.json",JSON.stringify(geometry()))
                    if(isBaseline) { console.log("BASELINE_LOAD_PASS"); driver.finish(0); return }
                    click("Days",3)
                } else if(step === 2) {
                    fitsButtons()
                    click("Days",3)
                    check(button("Days").checked,"Days remains checked on repeat click")
                    rows=activeRows(); originalRows=rows.slice()
                    check(rows.length === 10,"exact ten delegates")
                    check(rows[0].dayInfo.dayName === FFXI.dayNames[(widget.timerData.vana.day+1)%8],"next weekday")
                    flick=all(widget.fullRepresentationItem).filter(x => x.firstDayStartMs !== undefined)[0]
                    check(flick.contentHeight > flick.height,"days scrollable")
                    check(all(widget.fullRepresentationItem).filter(x => x.route !== undefined && x.visible).length === 0,"no route overlay")
                    driver.capture("candidate-days.png")
                    firstStart=rows[0].dayInfo.startMs; countBefore=rows[0].dayInfo.countdownMs
                    flick.contentY=flick.contentHeight-flick.height
                    setTime(now+1000)
                } else if(step === 3) {
                    check(flick.contentY > 0,"tick preserves scroll")
                    check(activeRows().every((r,i)=>r===originalRows[i]),"delegates stable")
                    check(rows[0].dayInfo.countdownMs === countBefore-1000,"live snapshot countdown")
                    check(rows[0].dayInfo.startMs === firstStart,"stable start")
                    var end=rows[9].mapToItem(flick,0,rows[9].height)
                    check(end.y <= flick.height+1,"tenth row reachable")
                    setTime(firstStart)
                } else if(step === 4) {
                    check(flick.contentY === 0,"rollover resets scroll")
                    check(rows[0].dayInfo.startMs === firstStart+FFXI.GAME_DAY_MS,"rollover first replaced")
                    check(rows[0].dayInfo.countdownMs === FFXI.GAME_DAY_MS,"full day countdown")
                    flick.contentY=30; setTime(now-10*FFXI.GAME_DAY_MS)
                } else if(step === 5) {
                    check(flick.contentY === 0,"backwards clock jump resets")
                    flick.contentY=30; setTime(now+100*FFXI.GAME_DAY_MS)
                } else if(step === 6) {
                    check(flick.contentY === 0,"forward clock jump resets")
                    flick.contentY=30; click("Boats",2)
                } else if(step === 7) {
                    check(flick.contentY === 0,"tab resets scroll")
                    check(rows.every(r=>!r.visible),"Days hidden on Boats")
                    click("Guilds",0)
                    check(all(widget.fullRepresentationItem).some(x=>x.visible && x.text && x.text.indexOf("Alchemy")>=0),"Guilds intact")
                    click("Airships",1); click("Days",3)
                    testWindow.width=324; testWindow.height=396
                    setTime(now)
                } else if(step === 8) {
                    fitsButtons()
                    for(var row of activeRows()) {
                        check(row.width<=flick.width+1,"row width")
                        for(var child of all(row).filter(x=>x.text!==undefined)) {
                            var p=child.mapToItem(flick,0,0)
                            check(p.x>=-1 && p.x+child.width<=flick.width+1,"label horizontal bounds: "+child.text)
                            check(child.contentHeight<=child.height+1,"label vertical fit: "+child.text)
                        }
                    }
                    driver.capture("candidate-days-minimum.png")
                    console.log("APPLET_CONTEXT_PASS clicks, ten rows, exclusive visibility, stable delegates, countdown, rollover, forward/backward jumps, scrolling, minimum width")
                    console.log("LOCAL_FORMAT",Qt.formatDateTime(new Date("2026-03-08T07:59:59Z"),"ddd MMM d, h:mm AP"),Qt.formatDateTime(new Date("2026-03-08T08:00:00Z"),"ddd MMM d, h:mm AP"),Qt.formatDateTime(new Date("2026-11-01T06:59:59Z"),"ddd MMM d, h:mm AP"),Qt.formatDateTime(new Date("2026-11-01T07:00:00Z"),"ddd MMM d, h:mm AP"))
                    driver.finish(0)
                }
                step++
            } catch(e) { console.error("TEST_FAIL",step,e); driver.finish(1) }
        }
    }
}
