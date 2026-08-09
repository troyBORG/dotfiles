.pragma library

// FFXI clock and calendar calculations derived from Pyogenes' FFXI Timer.
// Original source: https://www.pyogenes.com/ffxi/timer/v2.html
// The original author permits reuse with credit and a source link.

var REAL_DAY_MS = 24 * 60 * 60 * 1000;
var GAME_DAY_MS = REAL_DAY_MS / 25;
var GAME_HOUR_MS = 60 * 60 * 1000 / 25;
var BASIS_MS = Date.UTC(2002, 5, 23, 15, 0, 0, 0);
var MOON_BASIS_MS = Date.UTC(2004, 0, 25, 2, 31, 12, 0);

var dayNames = ["Firesday", "Earthsday", "Watersday", "Windsday", "Iceday", "Lightningday", "Lightsday", "Darksday"];
var phaseNames = ["Full Moon", "Waning Gibbous", "Last Quarter", "Waning Crescent", "New Moon", "Waxing Crescent", "First Quarter", "Waxing Gibbous"];
var dayColors = ["#e05a47", "#c6a64b", "#58a6d6", "#59b26b", "#8ba9e6", "#bd72d9", "#dedede", "#858585"];

var guilds = [
    { name: "Alchemy",     open: 8, close: 23, holiday: 6 },
    { name: "Blacksmith",  open: 8, close: 23, holiday: 2 },
    { name: "Boneworking", open: 8, close: 23, holiday: 3 },
    { name: "Goldsmith",   open: 8, close: 23, holiday: 4 },
    { name: "Clothcraft",  open: 6, close: 21, holiday: 0 },
    { name: "Woodworking", open: 6, close: 21, holiday: 0 },
    { name: "Leathercraft",open: 3, close: 18, holiday: 4 },
    { name: "Fishing",     open: 3, close: 18, holiday: 5 },
    { name: "Cooking",     open: 5, close: 20, holiday: 7 }
];

function positiveMod(value, divisor) {
    return ((value % divisor) + divisor) % divisor;
}

function pad2(value) {
    return value < 10 ? "0" + value : "" + value;
}

function formatDuration(ms, includeSeconds) {
    ms = Math.max(0, Math.floor(ms));
    var totalSeconds = Math.floor(ms / 1000);
    var days = Math.floor(totalSeconds / 86400);
    var hours = Math.floor((totalSeconds % 86400) / 3600);
    var minutes = Math.floor((totalSeconds % 3600) / 60);
    var seconds = totalSeconds % 60;
    var output = "";
    if (days > 0) output += days + "d ";
    if (days > 0 || hours > 0) output += hours + "h ";
    output += minutes + "m";
    if (includeSeconds && days === 0) output += " " + pad2(seconds) + "s";
    return output;
}

function vanaTime(nowMs) {
    var vanaMs = ((898 * 360 + 30) * REAL_DAY_MS) + (nowMs - BASIS_MS) * 25;
    var year = Math.floor(vanaMs / (360 * REAL_DAY_MS));
    var month = Math.floor(positiveMod(vanaMs, 360 * REAL_DAY_MS) / (30 * REAL_DAY_MS)) + 1;
    var date = Math.floor(positiveMod(vanaMs, 30 * REAL_DAY_MS) / REAL_DAY_MS) + 1;
    var hour = Math.floor(positiveMod(vanaMs, REAL_DAY_MS) / (60 * 60 * 1000));
    var minute = Math.floor(positiveMod(vanaMs, 60 * 60 * 1000) / (60 * 1000));
    var second = Math.floor(positiveMod(vanaMs, 60 * 1000) / 1000);
    var day = Math.floor(positiveMod(vanaMs, 8 * REAL_DAY_MS) / REAL_DAY_MS);
    return {
        year: year, month: month, date: date, hour: hour, minute: minute, second: second,
        day: day, dayName: dayNames[day], dayColor: dayColors[day],
        clock: pad2(hour) + ":" + pad2(minute) + ":" + pad2(second),
        calendar: year + "-" + pad2(month) + "-" + pad2(date)
    };
}

function moon(nowMs) {
    var elapsed = nowMs - MOON_BASIS_MS;
    var moonDay = positiveMod(Math.floor(elapsed / GAME_DAY_MS), 84);
    var dayElapsed = positiveMod(elapsed, GAME_DAY_MS);
    var signedPercent = -Math.round((42 - moonDay) / 42 * 100);
    var phase = 0;
    var nextBoundary = 0;
    var optimalPhase = 4;
    var optimalBoundary = 38;

    if (signedPercent <= -94) {
        phase = 0; nextBoundary = 3;
    } else if (signedPercent >= 90) {
        phase = 0; nextBoundary = 87; optimalBoundary = 122;
    } else if (signedPercent <= -62) {
        phase = 1; nextBoundary = 17;
    } else if (signedPercent <= -41) {
        phase = 2; nextBoundary = 25;
    } else if (signedPercent <= -11) {
        phase = 3; nextBoundary = 38;
    } else if (signedPercent <= 6) {
        phase = 4; nextBoundary = 45; optimalPhase = 0; optimalBoundary = 80;
    } else if (signedPercent <= 36) {
        phase = 5; nextBoundary = 58; optimalPhase = 0; optimalBoundary = 80;
    } else if (signedPercent <= 56) {
        phase = 6; nextBoundary = 66; optimalPhase = 0; optimalBoundary = 80;
    } else {
        phase = 7; nextBoundary = 80; optimalPhase = 0; optimalBoundary = 80;
    }

    var nextMs = (nextBoundary - moonDay) * GAME_DAY_MS - dayElapsed;
    var optimalMs = (optimalBoundary - moonDay) * GAME_DAY_MS - dayElapsed;
    return {
        phase: phase,
        name: phaseNames[phase],
        percent: Math.abs(signedPercent),
        nextName: phaseNames[(phase + 1) % 8],
        nextMs: nextMs,
        optimalName: phaseNames[optimalPhase],
        optimalMs: optimalMs
    };
}

function conquest(nowMs) {
    var elapsed = positiveMod(nowMs - BASIS_MS, 7 * REAL_DAY_MS);
    var left = 7 * REAL_DAY_MS - elapsed;
    return {
        leftMs: left,
        vanaDays: Math.floor(left / GAME_DAY_MS) + 1,
        at: new Date(nowMs + left)
    };
}

function guildState(guild, nowMs, vana) {
    var elapsedInGameDay = positiveMod(nowMs - BASIS_MS, GAME_DAY_MS);
    var openAt = guild.open * GAME_HOUR_MS;
    var closeAt = guild.close * GAME_HOUR_MS;
    var isHoliday = vana.day === guild.holiday;
    var isOpen = !isHoliday && elapsedInGameDay >= openAt && elapsedInGameDay < closeAt;
    var nextMs;
    var label;

    if (isOpen) {
        nextMs = closeAt - elapsedInGameDay;
        label = "Closes";
    } else {
        var daysAhead = elapsedInGameDay < openAt ? 0 : 1;
        if (isHoliday && daysAhead === 0) daysAhead = 1;
        while ((vana.day + daysAhead) % 8 === guild.holiday) daysAhead++;
        nextMs = daysAhead * GAME_DAY_MS + openAt - elapsedInGameDay;
        label = "Opens";
    }

    return {
        name: guild.name,
        isOpen: isOpen,
        isHoliday: isHoliday,
        label: label,
        countdownMs: nextMs,
        holiday: dayNames[guild.holiday],
        hours: pad2(guild.open) + ":00-" + pad2(guild.close) + ":00"
    };
}

function nextGameTime(nowMs, hour, minute) {
    var elapsed = positiveMod(nowMs - BASIS_MS, GAME_DAY_MS);
    var target = (hour * 60 + minute) * GAME_HOUR_MS / 60;
    var left = target - elapsed;
    if (left <= 0) left += GAME_DAY_MS;
    return left;
}

function scheduledTripState(nowMs, boardingMinute, departureMinute, arrivalMinute, intervalMinutes) {
    var nowMinutes = (nowMs - BASIS_MS) / GAME_HOUR_MS * 60;
    var compareNow = nowMinutes + 0.0000001;
    var cycleStart = Math.floor((compareNow - boardingMinute) / intervalMinutes) * intervalMinutes;
    var boarding = cycleStart + boardingMinute;
    var departure = cycleStart + departureMinute;
    var arrival = cycleStart + arrivalMinute;

    if (compareNow < departure) {
        return { state: "boarding", countdownMs: (departure - nowMinutes) * GAME_HOUR_MS / 60 };
    }
    if (compareNow < arrival) {
        return { state: "transit", countdownMs: (arrival - nowMinutes) * GAME_HOUR_MS / 60 };
    }
    return { state: "waiting", countdownMs: (boarding + intervalMinutes - nowMinutes) * GAME_HOUR_MS / 60 };
}

function scheduledTripsState(nowMs, trips, intervalMinutes) {
    var nowMinutes = (nowMs - BASIS_MS) / GAME_HOUR_MS * 60;
    var compareNow = nowMinutes + 0.0000001;
    var cycleBase = Math.floor(compareNow / intervalMinutes) * intervalMinutes;
    var nextBoarding = Infinity;

    for (var shift = -1; shift <= 1; shift++) {
        var base = cycleBase + shift * intervalMinutes;
        for (var i = 0; i < trips.length; i++) {
            var boarding = base + trips[i][0];
            var departure = base + trips[i][1];
            var arrival = base + trips[i][2];
            if (compareNow >= boarding && compareNow < departure) {
                return { state: "boarding", countdownMs: (departure - nowMinutes) * GAME_HOUR_MS / 60 };
            }
            if (compareNow >= departure && compareNow < arrival) {
                return { state: "transit", countdownMs: (arrival - nowMinutes) * GAME_HOUR_MS / 60 };
            }
            if (boarding > compareNow) nextBoarding = Math.min(nextBoarding, boarding);
        }
    }
    return { state: "waiting", countdownMs: (nextBoarding - nowMinutes) * GAME_HOUR_MS / 60 };
}

function transportRoute(nowMs, id, name, boardingMinute, departureMinute, arrivalMinute, intervalMinutes, group) {
    var state = scheduledTripState(nowMs, boardingMinute, departureMinute, arrivalMinute, intervalMinutes);
    return {
        id: id,
        name: name,
        group: group,
        state: state.state,
        countdownMs: state.countdownMs
    };
}

function transportMultiRoute(nowMs, id, name, trips, intervalMinutes, group) {
    var state = scheduledTripsState(nowMs, trips, intervalMinutes);
    return {
        id: id,
        name: name,
        group: group,
        state: state.state,
        countdownMs: state.countdownMs
    };
}

function advanceTransportAlert(previousState, currentState, stage) {
    if (stage === "boarding" && previousState !== "boarding" && currentState === "boarding") {
        return { triggered: true, stage: "arrival" };
    }
    if (stage === "arrival" && previousState === "transit" && currentState !== "transit") {
        return { triggered: true, stage: "" };
    }
    return { triggered: false, stage: stage };
}

function airships(nowMs) {
    var interval = 360;
    return [
        transportRoute(nowMs, "air-j-b", "Jeuno → Bastok", 190, 250, 370, interval, "AIRSHIPS"),
        transportRoute(nowMs, "air-j-k", "Jeuno → Kazham", 275, 335, 460, interval, "AIRSHIPS"),
        transportRoute(nowMs, "air-j-s", "Jeuno → San d'Oria", 10, 70, 190, interval, "AIRSHIPS"),
        transportRoute(nowMs, "air-j-w", "Jeuno → Windurst", 100, 160, 285, interval, "AIRSHIPS"),
        transportRoute(nowMs, "air-b-j", "Bastok → Jeuno", 10, 70, 190, interval, "AIRSHIPS"),
        transportRoute(nowMs, "air-k-j", "Kazham → Jeuno", 100, 160, 275, interval, "AIRSHIPS"),
        transportRoute(nowMs, "air-s-j", "San d'Oria → Jeuno", 190, 250, 370, interval, "AIRSHIPS"),
        transportRoute(nowMs, "air-w-j", "Windurst → Jeuno", 285, 345, 460, interval, "AIRSHIPS")
    ];
}

function boats(nowMs) {
    return [
        transportRoute(nowMs, "ferry-s-m", "Selbina ↔ Mhaura", 390, 480, 870, 480, "FERRIES"),
        transportRoute(nowMs, "ferry-m-w", "Mhaura ↔ Whitegate", 160, 240, 640, 480, "FERRIES"),
        transportRoute(nowMs, "ferry-w-n", "Whitegate ↔ Nashmau", 300, 480, 780, 480, "FERRIES"),
        transportRoute(nowMs, "mana-dhalmel", "Dhalmel Rock tour", 10, 50, 290, 1440, "MANACLIPPER / CLAMMING"),
        transportMultiRoute(nowMs, "mana-purg", "Bibiki → Purgonorg", [[290, 330, 520], [1010, 1050, 1230]], 1440, "MANACLIPPER / CLAMMING"),
        transportMultiRoute(nowMs, "mana-bibiki", "Purgonorg → Bibiki", [[520, 555, 730], [1230, 1275, 1450]], 1440, "MANACLIPPER / CLAMMING"),
        transportRoute(nowMs, "mana-reef", "Maliyakaleya Reef tour", 730, 770, 1010, 1440, "MANACLIPPER / CLAMMING")
    ];
}

function parseServerStatus(value) {
    var text = String(value).trim();
    if (!/^\d+$/.test(text)) return { state: "unknown", players: 0 };
    var players = parseInt(text, 10);
    return { state: players > 0 ? "online" : "offline", players: players };
}

function snapshot(nowMs) {
    var vana = vanaTime(nowMs);
    var moonInfo = moon(nowMs);
    var conquestInfo = conquest(nowMs);
    var states = [];
    for (var i = 0; i < guilds.length; i++) states.push(guildState(guilds[i], nowMs, vana));
    return {
        vana: vana,
        moon: moonInfo,
        conquest: conquestInfo,
        guilds: states,
        airships: airships(nowMs, vana),
        boats: boats(nowMs)
    };
}
