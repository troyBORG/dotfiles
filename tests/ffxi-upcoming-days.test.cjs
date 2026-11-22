'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const source = path.join(__dirname, '../plasmoid/FFXITimers/contents/code/ffxi.js');
const api = vm.createContext({});
vm.runInContext(fs.readFileSync(source, 'utf8').replace(/^\.pragma library\s*/, ''), api);
const B = 1024844400000;
const D = 3456000;
const names = ['Firesday', 'Earthsday', 'Watersday', 'Windsday', 'Iceday', 'Lightningday', 'Lightsday', 'Darksday'];
const colors = ['#e05a47', '#c6a64b', '#58a6d6', '#59b26b', '#8ba9e6', '#bd72d9', '#dedede', '#858585'];
function plain(value) { return JSON.parse(JSON.stringify(value)); }
function check(now) {
    const rows = api.upcomingDays(now);
    assert.equal(rows.length, 10);
    const nextDay = Math.floor((now - B) / D) + 1;
    for (let i = 0; i < rows.length; i++) {
        const row = rows[i];
        const start = B + (nextDay + i) * D;
        const dayIndex = ((6 + nextDay + i) % 8 + 8) % 8;
        assert.equal(row.startMs, start);
        assert.ok(row.startMs > now);
        assert.equal(row.countdownMs, start - now);
        assert.equal(row.dayName, names[dayIndex]);
        assert.equal(row.dayColor, colors[dayIndex]);
        assert.equal(api.vanaTime(start).clock, '00:00:00');
        if (i) assert.equal(row.startMs - rows[i - 1].startMs, D);
    }
    return rows;
}
test('upcoming: strict next ten, epoch, wrap, jumps, DST and local midnight', () => {
    assert.equal(typeof api.upcomingDays, 'function');
    assert.equal(api.BASIS_MS, B);
    assert.equal(api.GAME_DAY_MS, D);
    assert.equal(check(B)[0].dayName, 'Darksday');
    assert.equal(check(B)[1].dayName, 'Firesday');
    assert.equal(check(B)[8].dayName, 'Darksday');
    for (const now of [B - D - 1, B - 1, B, B + 1, B + D - 1,
                       B + D, B + D + 1, B + 1234567,
                       B + 70 * D, B - 70 * D,
                       Date.parse('2026-03-08T07:59:59Z'),
                       Date.parse('2026-11-01T06:59:59Z'),
                       Date.parse('2026-11-23T05:59:59Z')]) check(now);
    const before = check(B + D - 1);
    const at = check(B + D);
    assert.equal(before[0].countdownMs, 1);
    assert.equal(at[0].startMs, before[1].startMs);
    assert.equal(at[0].countdownMs, D);
    const a = check(B + 2000);
    const b = check(B + 3000);
    assert.equal(a[0].startMs, b[0].startMs);
    assert.equal(a[0].countdownMs - b[0].countdownMs, 1000);
    // Recompute backwards too: no cached/incremental countdown state.
    assert.deepEqual(plain(check(B + 2000)), plain(a));
    assert.equal(api.formatDuration(D, true), '57m 36s');
});

test('snapshot exposes upcoming starts and preserves all existing fields', () => {
    for (const now of [B - 1, B, B + D - 1, B + D, Date.parse('2026-11-22T12:34:56Z')]) {
        const value = api.snapshot(now);
        assert.ok(Array.isArray(value.upcomingDays));
        assert.deepEqual(plain(value.upcomingDays), plain(api.upcomingDays(now)));
        assert.deepEqual(plain(value.vana), plain(api.vanaTime(now)));
        assert.deepEqual(plain(value.moon), plain(api.moon(now)));
        assert.deepEqual(plain(value.conquest), plain(api.conquest(now)));
        assert.deepEqual(plain(value.airships), plain(api.airships(now)));
        assert.deepEqual(plain(value.boats), plain(api.boats(now)));
        assert.deepEqual(plain(value.guilds), plain(api.guilds.map(g => api.guildState(g, now, value.vana))));
    }
});
