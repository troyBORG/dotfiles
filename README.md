# Dotfiles

My personal dotfiles configuration for Linux (CachyOS/Arch-based).

<a href="https://github-production-user-asset-6210df.s3.amazonaws.com/10406330/522151725-a96d875e-47da-47a6-b9a2-a30317d0378a.png?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=AKIAVCODYLSA53PQK4ZA%2F20260103%2Fus-east-1%2Fs3%2Faws4_request&X-Amz-Date=20260103T060835Z&X-Amz-Expires=300&X-Amz-Signature=93861b2726f6d668dc6c12326d11b1ddcffde5293d636a0f25ca6a17c9801c81&X-Amz-SignedHeaders=host"><img width="1278" height="645" alt="image" src="https://github.com/user-attachments/assets/a96d875e-47da-47a6-b9a2-a30317d0378a" /></a>


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

5. **Install Konsole profile (optional):**
   ```bash
   mkdir -p ~/.local/share/konsole ~/.config
   cp ~/dotfiles/config/konsole/"Troy Theme.profile" ~/.local/share/konsole/
   cp ~/dotfiles/config/konsole/DarkOneNuanced.colorscheme ~/.local/share/konsole/
   cp ~/dotfiles/config/konsole/konsolerc ~/.config/konsolerc
   ```
   Then open Konsole settings and set "Troy Theme" as your default profile.

6. **Install KDE theme configuration (optional):**
   
   **Option A: Install as a selectable color scheme (Recommended):**
   ```bash
   mkdir -p ~/.local/share/color-schemes
   cp ~/dotfiles/config/kde/TroyGreen.colors ~/.local/share/color-schemes/
   ```
   Then open KDE System Settings → Appearance → Colors and select "Troy Green" from the list.
   
   **Option B: Install by copying config files directly:**
   ```bash
   cp ~/dotfiles/config/kde/kdeglobals ~/.config/kdeglobals
   cp ~/dotfiles/config/kde/plasmarc ~/.config/plasmarc
   ```
   Note: This config uses the CachyOS-Nord look-and-feel package. You may need to install it or adjust the `LookAndFeelPackage` setting in `kdeglobals` to match your installed theme. The theme uses a green accent color and breeze-dark icons.

7. **Install scripts:**
   ```bash
   mkdir -p ~/.local/bin
   cp ~/dotfiles/scripts/media-info.sh ~/.local/bin/media-info.sh
   cp ~/dotfiles/scripts/gpu-load.sh ~/.local/bin/gpu-load.sh
   chmod +x ~/.local/bin/media-info.sh
   chmod +x ~/.local/bin/gpu-load.sh
   ```
   
   **Optional - ZFS Rollback Script:**
   ```bash
   # Add to PATH or create symlink
   sudo ln -s ~/dotfiles/scripts/zfs-rollback.sh /usr/local/bin/zfs-rollback
   # Or add to your shell config: export PATH="$HOME/dotfiles/scripts:$PATH"
   ```
   
   **Optional - Screenshot Cropping Script:**
   ```bash
   chmod +x ~/dotfiles/scripts/crop_screenshot.sh
   # Add to PATH or create symlink
   sudo ln -s ~/dotfiles/scripts/crop_screenshot.sh /usr/local/bin/crop-screenshot
   # Or add to your shell config: export PATH="$HOME/dotfiles/scripts:$PATH"
   ```
   
   **Optional - Automatic Snapshot Cleanup:**
   ```bash
   # Set up weekly automatic cleanup (keeps last 14 days of snapshots)
   sudo cp ~/dotfiles/scripts/zfs-pacman-snapshot-cleanup.service /etc/systemd/system/
   sudo cp ~/dotfiles/scripts/zfs-pacman-snapshot-cleanup.timer /etc/systemd/system/
   sudo systemctl daemon-reload
   sudo systemctl enable --now zfs-pacman-snapshot-cleanup.timer
   ```

8. **Initialize Starship in your shell:**
   
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

## File Locations

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
| `scripts/kill-wlx-overlay.sh` | `~/dotfiles/scripts/kill-wlx-overlay.sh` (or add to PATH) |
| `scripts/zfs-pacman-snapshot-cleanup.service` | `/etc/systemd/system/zfs-pacman-snapshot-cleanup.service` (for automatic pacman snapshot cleanup) |
| `scripts/zfs-pacman-snapshot-cleanup.timer` | `/etc/systemd/system/zfs-pacman-snapshot-cleanup.timer` (for automatic pacman snapshot cleanup) |

## Features

### Fastfetch
- System information display with custom layout
- GPU temperature and VRAM usage
- CPU temperature
- Storage usage with progress bars
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

#### `kill-wlx-overlay.sh`
Kill and restart wlx-overlay-s VR overlay helper
- **Kill stuck processes**: Finds and terminates any running `wlx-overlay-s` processes
- **Auto-restart**: Automatically restarts with `wlx-overlay-s --replace` after killing
- **Graceful shutdown**: Tries SIGTERM first, then SIGKILL if needed
- **Usage**: `./kill-wlx-overlay.sh` - Double-click the desktop shortcut or run from terminal
- Useful when the overlay gets stuck or needs to be restarted after VR runtime changes


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

## Dependencies

- `fastfetch` - [Installation](https://github.com/fastfetch-cli/fastfetch)
- `starship` - [Installation](https://starship.rs/guide/#%F0%9F%9A%80-installation)
- `dbus-send` - Usually comes with D-Bus (system package)
- `nvidia-smi` - Comes with NVIDIA drivers (for NVIDIA GPU load)
- `rocm-smi` - AMD ROCm tools (optional, for AMD GPU load)
- `zfs` - ZFS filesystem tools (for `zfs-rollback.sh` and `check-arc-cache.sh` scripts, requires ZFS root filesystem)
- `ffmpeg` - Image/video processing tools (for `crop_screenshot.sh` script)
- `arc_summary` - ZFS ARC statistics tool (comes with zfs-utils package, for `check-arc-cache.sh`)

## Customization

### Starship Colors
The Starship config uses the Catppuccin Mocha palette. To change colors, edit `~/.config/starship.toml` and modify the `[palettes.catppuccin_mocha]` section.

### Fastfetch Layout
To customize the Fastfetch display, edit `~/.config/fastfetch/config.jsonc` and modify the `modules` array.

### Konsole Profile
The Konsole profile uses the DarkOneNuanced color scheme with Hack font. To customize, edit the profile files in `~/.local/share/konsole/` or modify the color scheme file.

### KDE Theme
The KDE theme configuration includes a custom "Troy Green" color scheme with a green accent color (RGB: 61,212,37). The theme can be installed as a selectable color scheme (recommended) or by copying config files directly.

**As a color scheme:** Install `TroyGreen.colors` to `~/.local/share/color-schemes/` and select it from KDE System Settings → Appearance → Colors.

**Direct config:** The `kdeglobals` file contains color scheme definitions and the `plasmarc` file contains wallpaper settings (sanitized in the repository). The config uses the CachyOS-Nord look-and-feel package and breeze-dark icons. To customize, edit these files or use KDE System Settings to modify and then copy the updated files back to the repository.

## License

Personal dotfiles - feel free to use and modify as needed.

