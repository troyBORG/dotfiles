# Dotfiles

My personal dotfiles configuration for Linux (CachyOS/Arch-based).

<img width="1280" height="568" alt="image" src="https://github.com/user-attachments/assets/5bc6eac6-6a5a-4229-a813-ed04fbcd8f69" />







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

### Dependencies (how to get them)

Not in all package managers (e.g. Ubuntu). Use these to install or copy configs to another machine:

- **fastfetch** — [GitHub repo](https://github.com/fastfetch-cli/fastfetch) (releases / build from source). CachyOS/Arch: `pacman -S fastfetch`
- **starship** — `curl -sS https://starship.rs/install.sh | sh` or binary from the [Starship releases](https://github.com/starship/starship/releases)
- **dbus-send** — Usually with D-Bus (system package)
- **nvidia-smi** — With NVIDIA drivers; **rocm-smi** — AMD ROCm (optional for GPU script)
- **zfs** — `zfs-utils` / distro package (for ZFS scripts; requires ZFS)
- **ffmpeg** — Distro package (for `crop_screenshot.sh`)
- **arc_summary** / **zarcsummary** — From `zfs-utils` (for `check-arc-cache.sh`)

<details>
<summary><strong>⚡ Quick reference — copy-paste setup</strong></summary>

Paste this whole block into a terminal on a new machine. It will clone the repo, install Fastfetch + Starship, copy configs, hook Starship into Fish/Bash/Zsh (whichever you have), and install the media/GPU scripts.

```bash
set -e

# Clone dotfiles
git clone https://github.com/troyBORG/dotfiles.git ~/dotfiles

# Fastfetch config
mkdir -p ~/.config/fastfetch ~/.config
cp ~/dotfiles/config/fastfetch/config.jsonc ~/.config/fastfetch/config.jsonc

# Starship binary + config (official installer; safe to rerun)
curl -sS https://starship.rs/install.sh | sh
cp ~/dotfiles/config/starship/starship.toml ~/.config/starship.toml

# Starship init (run for all common shells; ignore errors if shell/config doesn't exist)
if command -v fish >/dev/null 2>&1; then
  mkdir -p ~/.config/fish
  if ! grep -q "starship init fish" ~/.config/fish/config.fish 2>/dev/null; then
    echo 'starship init fish | source' >> ~/.config/fish/config.fish
  fi
fi

if command -v bash >/dev/null 2>&1; then
  if ! grep -q "starship init bash" ~/.bashrc 2>/dev/null; then
    echo 'eval "$(starship init bash)"' >> ~/.bashrc
  fi
fi

if command -v zsh >/dev/null 2>&1; then
  if ! grep -q "starship init zsh" ~/.zshrc 2>/dev/null; then
    echo 'eval "$(starship init zsh)"' >> ~/.zshrc
  fi
fi

# Optional: media/GPU scripts for Starship prompt
mkdir -p ~/.local/bin
cp ~/dotfiles/scripts/media-info.sh ~/.local/bin/media-info.sh
cp ~/dotfiles/scripts/gpu-load.sh ~/.local/bin/gpu-load.sh
chmod +x ~/.local/bin/media-info.sh ~/.local/bin/gpu-load.sh

echo
echo "Done. Restart your shell (or open a new terminal) to see the Starship prompt."
```

<div align="center">│ end of quick reference │</div>

</details>

### Setup (step by step)

1. **Clone this repository**
   ```bash
   git clone https://github.com/troyBORG/dotfiles.git ~/dotfiles
   ```

2. **Install Fastfetch config**
   ```bash
   mkdir -p ~/.config/fastfetch
   cp ~/dotfiles/config/fastfetch/config.jsonc ~/.config/fastfetch/config.jsonc
   ```
   **Note:** Fastfetch only reads `~/.config/fastfetch/config.jsonc`. After any edit in dotfiles, copy again:  
   `cp ~/dotfiles/config/fastfetch/config.jsonc ~/.config/fastfetch/config.jsonc`

3. **Install Starship (binary + config)**
   ```bash
   curl -sS https://starship.rs/install.sh | sh
   mkdir -p ~/.config
   cp ~/dotfiles/config/starship/starship.toml ~/.config/starship.toml
   ```
   To update Starship later, rerun the install script. It replaces the binary without touching config.

   **That’s all for a minimal setup.** The prompt won’t show music/GPU until you add the scripts below and have Starship init in your shell.

4. **Initialize Starship in your shell** (required for the prompt)

   **Fish** (add to `~/.config/fish/config.fish`):
   ```fish
   starship init fish | source
   ```

   **Bash** (add to `~/.bashrc`):
   ```bash
   eval "$(starship init bash)"
   ```

   **Zsh** (add to `~/.zshrc`):
   ```zsh
   eval "$(starship init zsh)"
   ```

5. **Media & GPU scripts (optional)** — powers the Starship music and GPU modules. Install and load in one place:

   ```bash
   mkdir -p ~/.local/bin
   cp ~/dotfiles/scripts/media-info.sh ~/.local/bin/media-info.sh
   cp ~/dotfiles/scripts/gpu-load.sh ~/.local/bin/gpu-load.sh
   chmod +x ~/.local/bin/media-info.sh
   chmod +x ~/.local/bin/gpu-load.sh
   ```
   Ensure `~/.local/bin` is in your PATH (it usually is). Starship will call these automatically once init is in your shell (step 4).

6. **Optional: Konsole, KDE theme, ZFS/screenshot/wallpaper scripts** <a id="optional-konsole-kde-zfs-etc"></a>

   <details>
   <summary>Bat fix (Fish/Zsh), Konsole, KDE, ZFS, wallpapers</summary>

   **Fish (default): make cat/less/more use bat correctly:**  
   CachyOS Fish config gives you **eza**, **grep --color=auto**, and bat for man. If you add **cat→bat** / **less→bat** and hit `error: unexpected argument '-R' found`, the cause is **bat's config**: `pager = less -RF` in `~/.config/bat/config`. Source this so **cat**, **less**, **more** use bat without that config:

   Add to `~/.config/fish/config.fish` (and remove any `alias cat=...` / `alias less=...` / `alias more=...` so these win):
   ```fish
   if test -f ~/dotfiles/config/fish/cat-bat-fix.fish
     source ~/dotfiles/config/fish/cat-bat-fix.fish
   end
   ```
   **Optional (fix root cause):** In `~/.config/bat/config`, change `pager = less -RF` to `pager = less -F`.

   **Other (eza, fd, rg):** eza/fd don’t have the bat-style flag issue. **grep→rg** can break `grep -E` / `grep -R` in Fish; use `command grep` when needed.

   **Zsh:** Add to `~/.zshrc`:
   ```bash
   [[ -f ~/dotfiles/config/zsh/cat-bat-fix.zsh ]] && source ~/dotfiles/config/zsh/cat-bat-fix.zsh
   ```
   Or: `alias cat='BAT_CONFIG_PATH=/dev/null bat --plain --paging=never'`

   **Konsole profile:**
   ```bash
   mkdir -p ~/.local/share/konsole ~/.config
   cp ~/dotfiles/config/konsole/"Troy Theme.profile" ~/.local/share/konsole/
   cp ~/dotfiles/config/konsole/DarkOneNuanced.colorscheme ~/.local/share/konsole/
   cp ~/dotfiles/config/konsole/konsolerc ~/.config/konsolerc
   ```
   Then set "Troy Theme" as default in Konsole settings.

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

   **Disable random wallpapers:**
   ```bash
   systemctl --user stop random-wallpapers.timer
   systemctl --user disable random-wallpapers.timer
   ```
   Then set static wallpapers in **System Settings → Appearance → Wallpaper** (or right-click desktop → Configure Wallpaper). Re-enable with `systemctl --user enable --now random-wallpapers.timer`.

   </details>

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
| `scripts/check-zfs-cache-usage.sh` | `~/dotfiles/scripts/check-zfs-cache-usage.sh` (or add to PATH) |
| `scripts/zfs-pacman-snapshot-cleanup.service` | `/etc/systemd/system/zfs-pacman-snapshot-cleanup.service` (for automatic pacman snapshot cleanup) |
| `scripts/zfs-pacman-snapshot-cleanup.timer` | `/etc/systemd/system/zfs-pacman-snapshot-cleanup.timer` (for automatic pacman snapshot cleanup) |
| `scripts/random-wallpapers.sh` | `~/dotfiles/scripts/random-wallpapers.sh` (used by user timer) |
| `scripts/random-wallpapers.service` | `~/.config/systemd/user/random-wallpapers.service` (Plasma per-monitor wallpapers) |
| `scripts/random-wallpapers.timer` | `~/.config/systemd/user/random-wallpapers.timer` (rotate every 10 min) |

</details>

<details>
<summary><strong>✨ Features</strong></summary>

<details>
<summary><strong>Fastfetch</strong></summary>

- System information display with custom layout
- GPU temperature and VRAM usage (via `gpu-load.sh`)
- CPU temperature
- Storage usage with progress bars (disk module shows all mounts including ZFS, same style as RAM/swap)
- Custom ASCII art logo

</details>

<details>
<summary><strong>Starship</strong></summary>

- Catppuccin Mocha color scheme
- Powerline-style prompt with colored segments
- Git status indicators
- Custom music module (shows currently playing track from any MPRIS player)
- Custom GPU load module (NVIDIA/AMD support)

</details>

<details>
<summary><strong>Konsole</strong></summary>

- "Troy Theme" profile with DarkOneNuanced color scheme
- Configured with Hack font (Nerd Font compatible)
- Optimized for terminal usage with custom colors

</details>

<details>
<summary><strong>KDE</strong></summary>

- Custom color scheme with green accent color (RGB: 61,212,37)
- CachyOS-Nord look-and-feel package
- breeze-dark icon theme
- Custom window manager colors
- Configured file dialog settings

</details>

<details>
<summary><strong>Scripts</strong></summary>

<details>
<summary><strong>media-info.sh</strong></summary>

Displays currently playing media from any MPRIS-compatible player (Spotify, VLC, YouTube, Twitch, Netflix, etc.)
- Works with any MPRIS player (music players and browsers)
- Shows artist and title for music, or video title for streaming services
- Platform-specific icons (YouTube, Twitch, Netflix, Hulu, Amazon Prime, Vimeo, SoundCloud, Plex)
- Automatically removes platform names from titles
- Automatically hides when no media is playing

</details>

<details>
<summary><strong>gpu-load.sh</strong></summary>

Displays GPU utilization percentage
- **NVIDIA**: Uses `nvidia-smi`
- **AMD (ROCm)**: Uses `rocm-smi`
- **AMD (open-source)**: Falls back to sysfs (`/sys/class/drm/card*/device/gpu_busy_percent`)
- Automatically detects GPU vendor

</details>

<details>
<summary><strong>zfs-rollback.sh</strong></summary>

ZFS snapshot management and rollback helper for systems using ZFS with automatic pacman snapshots
- **List snapshots**: `zfs-rollback list` - View all pacman snapshots
- **Latest snapshot**: `zfs-rollback latest` - Show the most recent snapshot
- **Rollback**: `zfs-rollback rollback [SNAPSHOT]` - Rollback to a specific snapshot (or latest)
- **Info**: `zfs-rollback info [SNAPSHOT]` - Show detailed snapshot information
- **Cleanup**: `zfs-rollback cleanup [DAYS]` - Delete snapshots older than N days (default: 30)
- Works with automatic pacman pre-transaction snapshots
- Includes safety prompts before destructive operations
- Designed for CachyOS/Arch Linux with ZFS root filesystem

</details>

<details>
<summary><strong>apply-zfs-snapshot-retention.sh</strong></summary>

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

</details>

<details>
<summary><strong>check-boot-space.sh</strong></summary>

Monitor `/boot` and `/boot/efi` partition space to prevent running out of space during kernel updates
- **Quick check**: `check-boot-space.sh` - Shows space usage, largest files, and installed kernels
- **Warnings**: Alerts when space usage exceeds 60% (warning) or 80% (critical)
- **Kernel info**: Lists installed kernel packages and boot files
- **Recommendations**: Provides cleanup suggestions when needed
- Helps prevent the "boot partition full" issue during kernel updates

</details>

<details>
<summary><strong>crop_screenshot.sh</strong></summary>

FFmpeg utility to split tall screenshots into chunks
- **Auto-detection**: Automatically detects image dimensions
- **Smart chunking**: Auto-calculates optimal chunk height to create ~12 chunks
- **Manual override**: Optional chunk height parameter for custom chunk sizes
- **Usage**: `./crop_screenshot.sh image.png [chunk_height]`
- Useful for processing very tall screenshots or images that are too large to handle as a single file

</details>

<details>
<summary><strong>check-arc-cache.sh</strong></summary>

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

</details>

<details>
<summary><strong>check-zfs-cache-usage.sh</strong></summary>

ZFS cache-dataset usage and ARC tuning helper
- **Usage report**: Shows referenced, used, and snapshot space for cache-like datasets (names matching cache, varcache, yay-cache, downloads)
- **primarycache tuning**: Suggests `primarycache=metadata` so ARC keeps hot data instead of bulk caches (metadata stays cached for fast ls/find; file contents read from disk)
- **Usage**:
  - `./check-zfs-cache-usage.sh` - Report cache-dataset usage
  - `./check-zfs-cache-usage.sh --suggest` - Print suggested `zfs set primarycache=metadata` commands (no changes made)
  - `./check-zfs-cache-usage.sh --all-datasets` - Include all datasets under home/ROOT, not just *cache*
- Complements `check-arc-cache.sh` for understanding and tuning ARC vs cache datasets

</details>

</details>

<details>
<summary><strong>ZFS Pools & Resonite Tuning</strong></summary>

**Pools:** `zpcachyos` (root), `m2_4tb` (Steam/ai_models/downloads/misc). All datasets use `compression=lz4`.

**Resonite datasets on zpcachyos:**
- **Cache** (`zpcachyos/ROOT/cos/home/resonite-cache`): `recordsize=1M`, `logbias=throughput`, `primarycache=metadata`, `atime=on`. Compressratio ~1.14x.
- **Data/DB** (`zpcachyos/ROOT/cos/home/resonite-data`, DB at `~/Resonite/Data/Data.litedb`): `recordsize=16K`, `logbias=latency`, `atime=on`. Compressratio ~1.09x.

Turn off auto-snapshots on these (and other volatile datasets like cache/yay/Downloads) so they don't bloat `znap_*` snapshots:  
`sudo zfs set com.sun:auto-snapshot=false zpcachyos/ROOT/cos/home/resonite-cache zpcachyos/ROOT/cos/home/resonite-data`

Check compression: `zfs get -r -t filesystem,volume compression,compressratio zpcachyos m2_4tb`

<details>
<summary><strong>Memory & ZFS tuning (optional)</strong></summary>

- **primarycache:** Already set: large cache-style datasets use `primarycache=metadata` or `none` so ARC keeps hot data (Resonite Data, code) instead of bulk caches. No change needed unless you add new large read-once datasets.
- **ARC:** If you ever see memory contention, you can lower `zfs_arc_max` (e.g. to 24G) to reserve RAM for apps; with ~47G free, no action needed now.
- **zram:** If swap-in latency causes hitches, try a faster compression algorithm (e.g. `lzo-rle` or `lz4`) via `/sys/block/zram0/comp_algorithm` (then re-mkswap/swapon). Skip L2ARC on all-NVMe systems unless you measure a real miss penalty.
- **Monitoring:** Use `check-arc-cache.sh` and `check-zfs-cache-usage.sh` to observe ARC and cache-dataset usage; `zarcsummary` or `arc_summary` for full ARC stats.

</details>

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

