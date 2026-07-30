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

function airships(nowMs, vana) {
    var elapsed = positiveMod(nowMs - BASIS_MS, GAME_DAY_MS);
    var interval = GAME_DAY_MS / 4;
    var routes = [
        { name: "Jeuno → Bastok",   offset: 4 * 60 + 10 },
        { name: "Jeuno → Kazham",   offset: 5 * 60 + 35 },
        { name: "Jeuno → San d'Oria", offset: 1 * 60 + 10 },
        { name: "Jeuno → Windurst", offset: 2 * 60 + 40 },
        { name: "Bastok → Jeuno",   offset: 1 * 60 + 10 },
        { name: "Kazham → Jeuno",   offset: 2 * 60 + 40 },
        { name: "San d'Oria → Jeuno", offset: 4 * 60 + 10 },
        { name: "Windurst → Jeuno", offset: 5 * 60 + 45 }
    ];
    var output = [];
    for (var i = 0; i < routes.length; i++) {
        var departure = routes[i].offset * GAME_HOUR_MS / 60;
        while (departure <= elapsed) departure += interval;
        output.push({
            name: routes[i].name,
            departureMs: departure - elapsed,
            boardingMs: Math.max(0, departure - elapsed - 144000)
        });
    }
    return output;
}

function boats(nowMs) {
    var manaclipper = [
        { name: "Bibiki → Purgonorg", hour: 5, minute: 30, boarding: "04:50" },
        { name: "Purgonorg → Bibiki", hour: 9, minute: 15, boarding: "08:40" },
        { name: "Reef tour", hour: 12, minute: 50, boarding: "12:10" },
        { name: "Bibiki → Purgonorg", hour: 17, minute: 30, boarding: "16:50" },
        { name: "Purgonorg → Bibiki", hour: 21, minute: 15, boarding: "20:30" },
        { name: "Dhalmel Rock tour", hour: 0, minute: 50, boarding: "00:10" }
    ];
    var output = [];
    for (var i = 0; i < manaclipper.length; i++) {
        var route = manaclipper[i];
        output.push({
            name: route.name,
            departure: pad2(route.hour) + ":" + pad2(route.minute),
            boarding: route.boarding,
            departureMs: nextGameTime(nowMs, route.hour, route.minute)
        });
    }
    output.sort(function(a, b) { return a.departureMs - b.departureMs; });

    var ferryElapsed = positiveMod(nowMs - BASIS_MS, GAME_DAY_MS / 3);
    var ferryLeft = GAME_DAY_MS / 3 - ferryElapsed;
    return {
        manaclipper: output,
        ferryDepartureMs: ferryLeft,
        ferryArrivalMs: Math.max(0, ferryLeft - 216000)
    };
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
