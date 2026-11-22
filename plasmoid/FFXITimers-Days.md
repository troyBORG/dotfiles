# FFXI Timers 1.5.0 — Days

The fourth **Days** tab lists exactly ten future Vana'diel day starts (not weather), excluding the current day. Each row uses the existing weekday palette and shows a local start date/time plus a countdown. The existing one-second snapshot drives all rows; no settings, notifications, network requests or timers were added. Existing typography, sizes, header, moon, conquest, transport and guild UI are unchanged; the tab row distributes its existing width among four buttons.

The first entry advances at midnight, even when sampled at the exact boundary. Boundaries use epoch milliseconds, not local calendar arithmetic. Local formatting reuses the existing formatter and omits seconds/timezone offsets. Ten rows intentionally repeat two weekdays. Ordinary ticks preserve scroll and delegates; tab changes or a changed first start reset scroll.

## Tests

From the repository root:

```sh
node --test tests/ffxi-upcoming-days.test.cjs tests/ffxi-days-ui.test.cjs
TZ=America/Chicago node --test tests/ffxi-upcoming-days.test.cjs
```

The dependency-free Node tests evaluate the production QML JavaScript after stripping its pragma. UI source assertions are structural checks, not rendering tests.

Optional genuine isolated Plasma loader (Qt 6 Widgets/Quick/Qml/Network/Test, Plasma, PlasmaQuick and KF6Package development packages, CMake, a C++ compiler, BreezeDark colors, and dbus-run-session required):

```sh
cmake -S tests/plasma -B tests/plasma/build
cmake --build tests/plasma/build -j2
python3 -B tests/plasma/run.py
```

This loads the real package into an AppletContext, uses an isolated configuration/data directory and private bus, and software rendering. Test-only network proxy settings prevent external requests. It exercises actual tab clicks, repeated Days clicks, row exclusivity, stable delegates, countdown updates, scrolling, rollover, clock jumps and minimum-width bounds. Screenshots/logs are retained in the printed temporary directory. The test clock is changed only through the harness, never the system or production code.

Verified on Plasma workspace/libplasma 6.8.3, Qt 6.12.0 and KPackage 6.32.0. Offscreen Windowsystem/Wayland platform warnings are expected; QML errors are not. A baseline/candidate 499×493 render comparison showed pixel changes confined to the tab strip and identical non-tab label geometry. This is isolated validation, not proof of a running desktop shell reloading the package.

## Packaging and updating

`plasmoid/FFXITimers.plasmoid` is a separately maintained legacy archive; this change does **not** replace it. Build the current source directory rather than installing that older archive:

```sh
python3 -c 'from pathlib import Path; import zipfile; p=Path("plasmoid/FFXITimers"); z=zipfile.ZipFile("FFXITimers-1.5.0.plasmoid","x",zipfile.ZIP_DEFLATED); [z.write(p/r,r) for r in ["metadata.json","contents/code/ffxi.js","contents/ui/main.qml"]]; z.close()'
```

Back up the installed `com.pennywiseops.ffxitimers` directory before upgrading as the desktop owner. Never restart the entire Plasma shell automatically. Fresh package bytes may not be loaded until the owner chooses a refresh or normal logout/login. Owner theme/font preferences remain untouched.
