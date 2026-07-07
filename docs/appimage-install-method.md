# AppImage install method

How I install AppImages on my desktop so they show up in the app menu and stay out of `~/Downloads`.

## What we do

1. **Move the AppImage to `~/Applications/`** and make it executable.
2. **Extract icons** from the AppImage (if it ships any).
3. **Install icons** under `~/.local/share/icons/hicolor/`.
4. **Create a `.desktop` file** in `~/.local/share/applications/`.
5. **Refresh caches** so KDE/Plasma picks up the new entry.

## Why this way

**AppImages are portable, not installed.** Double-clicking one in `~/Downloads` works, but it is easy to lose track of, accidentally delete, or re-download into a second copy.

This layout matches how other apps on this machine are set up (for example `~/Applications/ocenaudio.AppImage`):

| Piece | Location | Purpose |
|-------|----------|---------|
| Binary | `~/Applications/` | One stable place for AppImages; no `sudo`, easy to back up |
| Launcher | `~/.local/share/applications/*.desktop` | Shows up in the app menu, KRunner, and pinned taskbar entries |
| Icons | `~/.local/share/icons/hicolor/` | Correct icon in the menu instead of a generic placeholder |

We do **not** put AppImages in `/opt` or `/usr/local/bin` unless there is a good reason. User-owned paths keep updates simple: replace the file in `~/Applications/` and update the `.desktop` path if the filename changed.

## Install steps

Replace `APP.appimage` with the real filename and `app-id` with a short name (e.g. `clone-hero`, `yarc-launcher`).

```bash
# 1. Move and make executable
mv ~/Downloads/APP.appimage ~/Applications/APP.appimage
chmod +x ~/Applications/APP.appimage

# 2. Extract to grab icons and metadata (optional but recommended)
tmpdir=$(mktemp -d)
cd "$tmpdir"
~/Applications/APP.appimage --appimage-extract

# 3. Install icons (copy whatever sizes exist in squashfs-root/usr/share/icons/hicolor/)
mkdir -p ~/.local/share/icons/hicolor/{32x32,128x128,256x256,256x256@2}/apps
cp -r squashfs-root/usr/share/icons/hicolor/*/apps/*.png ~/.local/share/icons/hicolor/*/apps/ 2>/dev/null || true
# Fallback if icons are only at the AppDir root:
# cp squashfs-root/*.png ~/.local/share/icons/hicolor/128x128/apps/

# 4. Create ~/.local/share/applications/app-id.desktop
#    Use the built-in .desktop as a starting point if present:
#    cat squashfs-root/*.desktop

# 5. Refresh desktop + icon caches
chmod +x ~/.local/share/applications/app-id.desktop
update-desktop-database ~/.local/share/applications
gtk-update-icon-cache -f -t ~/.local/share/icons/hicolor 2>/dev/null || true

rm -rf "$tmpdir"
```

### Desktop entry template

```ini
[Desktop Entry]
Name=App Name
GenericName=Short description
Comment=What it does
Exec=/home/troyborg/Applications/APP.appimage %u
Icon=icon-name
Type=Application
StartupNotify=true
Terminal=false
Categories=Game;
Keywords=search;terms;
TryExec=/home/troyborg/Applications/APP.appimage
```

- `Exec` and `TryExec` must point at the **full path** in `~/Applications/`, not just the filename.
- `Icon` should match the icon basename installed under `~/.local/share/icons/hicolor/*/apps/` (without `.png`).

## Currently installed this way

| App | AppImage | Desktop entry | Icon |
|-----|----------|---------------|------|
| Clone Hero | `~/Applications/ch_launcher-linux.appimage` | `~/.local/share/applications/clone-hero.desktop` | `ch_launcher` |
| YARC Launcher | `~/Applications/YARC.Launcher_1.3.0_amd64.appimage` | `~/.local/share/applications/yarc-launcher.desktop` | `yarc-launcher` |
| ocenaudio | `~/Applications/ocenaudio.AppImage` | `~/.local/share/applications/ocenaudio.desktop` | `ocenaudio` |

## Notes

- Some AppImages are **launchers** (Clone Hero, YARC), not the game itself. The launcher downloads the real app on first run.
- After upgrading, if the AppImage filename changes, update `Exec` and `TryExec` in the `.desktop` file.
- If the menu entry does not appear immediately, log out and back in, or run `update-desktop-database ~/.local/share/applications` again.
