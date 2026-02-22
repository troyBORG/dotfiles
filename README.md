# Dotfiles

My personal dotfiles configuration for Linux (CachyOS/Arch-based).

<img width="1480" height="869" alt="image" src="https://github.com/user-attachments/assets/37598953-8c6d-4fab-816b-e8a512a1b1d2" />





## Contents

- **Fastfetch** - System information display
- **Starship** - Cross-shell prompt
- **Konsole** - Terminal profile with color scheme and font configuration
- **KDE** - Desktop theme configuration (colors, icons, look-and-feel)
- **Scripts** - Helper scripts for Starship modules and system management

## Installation

### Prerequisites

- Linux system (tested on CachyOS/Arch-based)
- `fastfetch` - System information tool
- `starship` - Prompt framework
- `fish` shell (or your preferred shell)
- `dbus-send` - For music info script (usually comes with D-Bus)
- `nvidia-smi` or AMD GPU tools - For GPU load script (optional)
- `ffmpeg` - For screenshot cropping script (optional)

### Setup

1. **Clone this repository:**
   ```bash
   git clone https://github.com/troyBORG/dotfiles.git ~/dotfiles
   ```

2. **Install Fastfetch config:**
   ```bash
   mkdir -p ~/.config/fastfetch
   cp ~/dotfiles/config/fastfetch/config.jsonc ~/.config/fastfetch/config.jsonc
   ```
   **Note:** Fastfetch only reads `~/.config/fastfetch/config.jsonc`. After any edit to the config in dotfiles, copy again so fastfetch (e.g. `fastfetch` / your fastshow alias) uses the new config:
   ```bash
   cp ~/dotfiles/config/fastfetch/config.jsonc ~/.config/fastfetch/config.jsonc
   ```

3. **Install Starship binary:**
   ```bash
   curl -sS https://starship.rs/install.sh | sh
   ```
   To update Starship later, rerun the above script. It will replace the current version without touching Starship's configuration.

4. **Install Starship config:**
   ```bash
   mkdir -p ~/.config
   cp ~/dotfiles/config/starship/starship.toml ~/.config/starship.toml
   ```

5. **Install scripts (core):**
   ```bash
   mkdir -p ~/.local/bin
   cp ~/dotfiles/scripts/media-info.sh ~/.local/bin/media-info.sh
   cp ~/dotfiles/scripts/gpu-load.sh ~/.local/bin/gpu-load.sh
   chmod +x ~/.local/bin/media-info.sh
   chmod +x ~/.local/bin/gpu-load.sh
   ```

   <details>
   <summary><strong>Optional: Konsole, KDE theme, ZFS/screenshot/wallpaper scripts</strong></summary>

   **Konsole profile:**
   ```bash
   mkdir -p ~/.local/share/konsole ~/.config
   cp ~/dotfiles/config/konsole/"Troy Theme.profile" ~/.local/share/konsole/
   cp ~/dotfiles/config/konsole/DarkOneNuanced.colorscheme ~/.local/share/konsole/
   cp ~/dotfiles/config/konsole/konsolerc ~/.config/konsolerc
   ```
   Then open Konsole settings and set "Troy Theme" as your default profile.

   **KDE theme (Option A - color scheme):**
   ```bash
   mkdir -p ~/.local/share/color-schemes
   cp ~/dotfiles/config/kde/TroyGreen.colors ~/.local/share/color-schemes/
   ```
   Then KDE System Settings → Appearance → Colors → "Troy Green".

   **KDE theme (Option B - direct config):**
   ```bash
   cp ~/dotfiles/config/kde/kdeglobals ~/.config/kdeglobals
   cp ~/dotfiles/config/kde/plasmarc ~/.config/plasmarc
   ```
   Note: Uses CachyOS-Nord look-and-feel; adjust `LookAndFeelPackage` in `kdeglobals` if needed.

   **ZFS Rollback Script:**
   ```bash
   sudo ln -s ~/dotfiles/scripts/zfs-rollback.sh /usr/local/bin/zfs-rollback
   ```

   **Screenshot Cropping Script:**
   ```bash
   chmod +x ~/dotfiles/scripts/crop_screenshot.sh
   sudo ln -s ~/dotfiles/scripts/crop_screenshot.sh /usr/local/bin/crop-screenshot
   ```

   **Automatic Snapshot Cleanup:**
   ```bash
   sudo cp ~/dotfiles/scripts/zfs-pacman-snapshot-cleanup.service /etc/systemd/system/
   sudo cp ~/dotfiles/scripts/zfs-pacman-snapshot-cleanup.timer /etc/systemd/system/
   sudo systemctl daemon-reload
   sudo systemctl enable --now zfs-pacman-snapshot-cleanup.timer
   ```

   **Random wallpapers (Plasma 6, per-monitor):**
   ```bash
   mkdir -p ~/.config/systemd/user
   cp ~/dotfiles/scripts/random-wallpapers.service ~/.config/systemd/user/
   cp ~/dotfiles/scripts/random-wallpapers.timer ~/.config/systemd/user/
   systemctl --user daemon-reload
   systemctl --user enable --now random-wallpapers.timer
   ```
   Edit script paths and `LEFT_INDEX`/`RIGHT_INDEX` for your setup. Runs 2 min after login and every 10 min.

   </details>

6. **Initialize Starship in your shell:**
   
   For **Fish shell** (add to `~/.config/fish/config.fish`):
   ```fish
   starship init fish | source
   ```
   
   For **Bash** (add to `~/.bashrc`):
   ```bash
   eval "$(starship init bash)"
   ```
   
   For **Zsh** (add to `~/.zshrc`):
   ```zsh
   eval "$(starship init zsh)"
   ```

<details>
<summary><strong>📁 File locations</strong></summary>

### Configuration Files

| Source | Destination |
|--------|-------------|
| `config/fastfetch/config.jsonc` | `~/.config/fastfetch/config.jsonc` |
| `config/starship/starship.toml` | `~/.config/starship/starship.toml` |
| `config/konsole/Troy Theme.profile` | `~/.local/share/konsole/Troy Theme.profile` |
| `config/konsole/DarkOneNuanced.colorscheme` | `~/.local/share/konsole/DarkOneNuanced.colorscheme` |
| `config/konsole/konsolerc` | `~/.config/konsolerc` |
| `config/kde/TroyGreen.colors` | `~/.local/share/color-schemes/TroyGreen.colors` (recommended - shows in System Settings) |
| `config/kde/kdeglobals` | `~/.config/kdeglobals` (alternative method) |
| `config/kde/plasmarc` | `~/.config/plasmarc` |

### Scripts

| Source | Destination |
|--------|-------------|
| `scripts/media-info.sh` | `~/.local/bin/media-info.sh` |
| `scripts/gpu-load.sh` | `~/.local/bin/gpu-load.sh` |
| `scripts/zfs-rollback.sh` | `~/dotfiles/scripts/zfs-rollback.sh` (or symlink to `/usr/local/bin/zfs-rollback`) |
| `scripts/apply-zfs-snapshot-retention.sh` | `~/dotfiles/scripts/apply-zfs-snapshot-retention.sh` (or add to PATH) |
| `scripts/check-boot-space.sh` | `~/dotfiles/scripts/check-boot-space.sh` (or add to PATH) |
| `scripts/crop_screenshot.sh` | `~/dotfiles/scripts/crop_screenshot.sh` (or add to PATH) |
| `scripts/check-arc-cache.sh` | `~/dotfiles/scripts/check-arc-cache.sh` (or add to PATH) |
| `scripts/zfs-pacman-snapshot-cleanup.service` | `/etc/systemd/system/zfs-pacman-snapshot-cleanup.service` (for automatic pacman snapshot cleanup) |
| `scripts/zfs-pacman-snapshot-cleanup.timer` | `/etc/systemd/system/zfs-pacman-snapshot-cleanup.timer` (for automatic pacman snapshot cleanup) |
| `scripts/random-wallpapers.sh` | `~/dotfiles/scripts/random-wallpapers.sh` (used by user timer) |
| `scripts/random-wallpapers.service` | `~/.config/systemd/user/random-wallpapers.service` (Plasma per-monitor wallpapers) |
| `scripts/random-wallpapers.timer` | `~/.config/systemd/user/random-wallpapers.timer` (rotate every 10 min) |

</details>

<details>
<summary><strong>✨ Features</strong></summary>

### Fastfetch
- System information display with custom layout
- GPU temperature and VRAM usage (via `gpu-load.sh`)
- CPU temperature
- Storage usage with progress bars (disk module shows all mounts including ZFS, same style as RAM/swap)
- Custom ASCII art logo

### Starship
- Catppuccin Mocha color scheme
- Powerline-style prompt with colored segments
- Git status indicators
- Custom music module (shows currently playing track from any MPRIS player)
- Custom GPU load module (NVIDIA/AMD support)

### Konsole
- "Troy Theme" profile with DarkOneNuanced color scheme
- Configured with Hack font (Nerd Font compatible)
- Optimized for terminal usage with custom colors

### KDE
- Custom color scheme with green accent color (RGB: 61,212,37)
- CachyOS-Nord look-and-feel package
- breeze-dark icon theme
- Custom window manager colors
- Configured file dialog settings

### Scripts

#### `media-info.sh`
Displays currently playing media from any MPRIS-compatible player (Spotify, VLC, YouTube, Twitch, Netflix, etc.)
- Works with any MPRIS player (music players and browsers)
- Shows artist and title for music, or video title for streaming services
- Platform-specific icons (YouTube, Twitch, Netflix, Hulu, Amazon Prime, Vimeo, SoundCloud, Plex)
- Automatically removes platform names from titles
- Automatically hides when no media is playing

#### `gpu-load.sh`
Displays GPU utilization percentage
- **NVIDIA**: Uses `nvidia-smi`
- **AMD (ROCm)**: Uses `rocm-smi`
- **AMD (open-source)**: Falls back to sysfs (`/sys/class/drm/card*/device/gpu_busy_percent`)
- Automatically detects GPU vendor

#### `zfs-rollback.sh`
ZFS snapshot management and rollback helper for systems using ZFS with automatic pacman snapshots
- **List snapshots**: `zfs-rollback list` - View all pacman snapshots
- **Latest snapshot**: `zfs-rollback latest` - Show the most recent snapshot
- **Rollback**: `zfs-rollback rollback [SNAPSHOT]` - Rollback to a specific snapshot (or latest)
- **Info**: `zfs-rollback info [SNAPSHOT]` - Show detailed snapshot information
- **Cleanup**: `zfs-rollback cleanup [DAYS]` - Delete snapshots older than N days (default: 30)
- Works with automatic pacman pre-transaction snapshots
- Includes safety prompts before destructive operations
- Designed for CachyOS/Arch Linux with ZFS root filesystem

#### `apply-zfs-snapshot-retention.sh`
Flexible ZFS auto-snapshot retention policy management for `zfs-auto-snapshot`
- **Dynamic configuration**: Generates systemd service overrides on-the-fly with any retention values
- **Usage**: `./apply-zfs-snapshot-retention.sh [MONTHLY] [DAILY] [WEEKLY]`
  - Defaults: monthly=3, daily=14, weekly=4 (conservative desktop policy)
  - Examples:
    - `./apply-zfs-snapshot-retention.sh` - Use defaults
    - `./apply-zfs-snapshot-retention.sh 6` - Set monthly=6, keep daily=14, weekly=4
    - `./apply-zfs-snapshot-retention.sh 4 7` - Set monthly=4, daily=7, keep weekly=4
    - `./apply-zfs-snapshot-retention.sh 6 14 8` - Set all three values
- **Validates inputs**: Ensures all values are positive integers
- **Applies immediately**: Creates systemd drop-in overrides and reloads daemon
- **No static files needed**: Generates configuration dynamically
- Manages `znap_*` snapshots created by `zfs-auto-snapshot` (hourly/daily/weekly/monthly)

#### `check-boot-space.sh`
Monitor `/boot` and `/boot/efi` partition space to prevent running out of space during kernel updates
- **Quick check**: `check-boot-space.sh` - Shows space usage, largest files, and installed kernels
- **Warnings**: Alerts when space usage exceeds 60% (warning) or 80% (critical)
- **Kernel info**: Lists installed kernel packages and boot files
- **Recommendations**: Provides cleanup suggestions when needed
- Helps prevent the "boot partition full" issue during kernel updates

#### `crop_screenshot.sh`
FFmpeg utility to split tall screenshots into chunks
- **Auto-detection**: Automatically detects image dimensions
- **Smart chunking**: Auto-calculates optimal chunk height to create ~12 chunks
- **Manual override**: Optional chunk height parameter for custom chunk sizes
- **Usage**: `./crop_screenshot.sh image.png [chunk_height]`
- Useful for processing very tall screenshots or images that are too large to handle as a single file

#### `check-arc-cache.sh`
ZFS ARC cache analysis tool to see what datasets are likely cached
- **ARC statistics**: Shows total ARC size, data cache size, and cache hit rate
- **Dataset analysis**: Calculates which datasets are likely cached by comparing sizes to ARC
- **Cache effectiveness**: Displays hit rate and cache status (excellent/good/fair/poor)
- **Usage**: 
  - `./check-arc-cache.sh` - Check all datasets
  - `./check-arc-cache.sh --resonite` - Only check Resonite datasets
  - `./check-arc-cache.sh --dataset zpcachyos/ROOT/cos/home/resonite-cache` - Check specific dataset
  - `./check-arc-cache.sh --brief` - Brief output format
- Helps identify what files are being cached by ZFS ARC (useful for understanding why RAM usage is high)

### ZFS Pools & Resonite Tuning

**Pools:** `zpcachyos` (root), `m2_4tb` (Steam/ai_models/downloads/misc). All datasets use `compression=lz4`.

**Resonite datasets on zpcachyos:**
- **Cache** (`zpcachyos/ROOT/cos/home/resonite-cache`): `recordsize=1M`, `logbias=throughput`, `primarycache=metadata`, `atime=on`. Compressratio ~1.14x.
- **Data/DB** (`zpcachyos/ROOT/cos/home/resonite-data`, DB at `~/Resonite/Data/Data.litedb`): `recordsize=16K`, `logbias=latency`, `atime=on`. Compressratio ~1.09x.

Turn off auto-snapshots on these (and other volatile datasets like cache/yay/Downloads) so they don't bloat `znap_*` snapshots:  
`sudo zfs set com.sun:auto-snapshot=false zpcachyos/ROOT/cos/home/resonite-cache zpcachyos/ROOT/cos/home/resonite-data`

Check compression: `zfs get -r -t filesystem,volume compression,compressratio zpcachyos m2_4tb`

**Automatic Cleanup Setup:**
Snapshots will accumulate over time and won't auto-cleanup by default. To set up automatic weekly cleanup:

1. Install the systemd service and timer (see `scripts/zfs-pacman-snapshot-cleanup.service` and `scripts/zfs-pacman-snapshot-cleanup.timer`):
   ```bash
   sudo cp ~/dotfiles/scripts/zfs-pacman-snapshot-cleanup.service /etc/systemd/system/
   sudo cp ~/dotfiles/scripts/zfs-pacman-snapshot-cleanup.timer /etc/systemd/system/
   sudo systemctl daemon-reload
   sudo systemctl enable --now zfs-pacman-snapshot-cleanup.timer
   ```

2. This will automatically delete snapshots older than 14 days every week (runs in non-interactive mode). The 14-day retention period is appropriate for pacman snapshots on rolling distributions like CachyOS - they're transactional rollback points, not archival backups. If you need longer-term recovery, use the `znap_*` snapshots instead.

3. To adjust the retention period, edit `/etc/systemd/system/zfs-pacman-snapshot-cleanup.service` and change the `cleanup 14` parameter. Typical values: 7 days (aggressive), 10-14 days (recommended), or 30 days (overkill but harmless).

4. Check timer status: `systemctl status zfs-pacman-snapshot-cleanup.timer`

**Note:** This cleanup timer only manages `pacman-pre-*` snapshots. The `znap_*` snapshots created by `zfs-auto-snapshot` (hourly/daily/weekly/monthly) are managed separately by their respective timers and have their own retention policies. Use `apply-zfs-snapshot-retention.sh` to configure retention for `zfs-auto-snapshot` snapshots.

</details>

<details>
<summary><strong>📦 Dependencies</strong></summary>

- `fastfetch` - [Installation](https://github.com/fastfetch-cli/fastfetch)
- `starship` - [Installation](https://starship.rs/guide/#%F0%9F%9A%80-installation)
- `dbus-send` - Usually comes with D-Bus (system package)
- `nvidia-smi` - Comes with NVIDIA drivers (for NVIDIA GPU load)
- `rocm-smi` - AMD ROCm tools (optional, for AMD GPU load)
- `zfs` - ZFS filesystem tools (for `zfs-rollback.sh` and `check-arc-cache.sh` scripts, requires ZFS root filesystem)
- `ffmpeg` - Image/video processing tools (for `crop_screenshot.sh` script)
- `arc_summary` - ZFS ARC statistics tool (comes with zfs-utils package, for `check-arc-cache.sh`)

</details>

<details>
<summary><strong>🎨 Customization</strong></summary>

### Starship Colors
The Starship config uses the Catppuccin Mocha palette. To change colors, edit `~/.config/starship.toml` and modify the `[palettes.catppuccin_mocha]` section.

### Fastfetch Layout
To customize the Fastfetch display, edit `~/dotfiles/config/fastfetch/config.jsonc` and modify the `modules` array. Then copy to the system so fastfetch uses it:  
`cp ~/dotfiles/config/fastfetch/config.jsonc ~/.config/fastfetch/config.jsonc`  
(Fastfetch only reads `~/.config/fastfetch/config.jsonc`, not the dotfiles copy.)

### Konsole Profile
The Konsole profile uses the DarkOneNuanced color scheme with Hack font. To customize, edit the profile files in `~/.local/share/konsole/` or modify the color scheme file.

### KDE Theme
The KDE theme configuration includes a custom "Troy Green" color scheme with a green accent color (RGB: 61,212,37). The theme can be installed as a selectable color scheme (recommended) or by copying config files directly.

**As a color scheme:** Install `TroyGreen.colors` to `~/.local/share/color-schemes/` and select it from KDE System Settings → Appearance → Colors.

**Direct config:** The `kdeglobals` file contains color scheme definitions and the `plasmarc` file contains wallpaper settings (sanitized in the repository). The config uses the CachyOS-Nord look-and-feel package and breeze-dark icons. To customize, edit these files or use KDE System Settings to modify and then copy the updated files back to the repository.

</details>

## License

Personal dotfiles - feel free to use and modify as needed.

