# Dotfiles

My personal dotfiles configuration for Linux (CachyOS/Arch-based).

## Contents

- **Fastfetch** - System information display
- **Starship** - Cross-shell prompt
- **Scripts** - Helper scripts for Starship modules

## Installation

### Prerequisites

- Linux system (tested on CachyOS/Arch-based)
- `fastfetch` - System information tool
- `starship` - Prompt framework
- `fish` shell (or your preferred shell)
- `dbus-send` - For music info script (usually comes with D-Bus)
- `nvidia-smi` or AMD GPU tools - For GPU load script (optional)

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

3. **Install Starship config:**
   ```bash
   mkdir -p ~/.config
   cp ~/dotfiles/config/starship/starship.toml ~/.config/starship.toml
   ```

4. **Install scripts:**
   ```bash
   mkdir -p ~/.local/bin
   cp ~/dotfiles/scripts/spotify-info.sh ~/.local/bin/spotify-info.sh
   cp ~/dotfiles/scripts/gpu-load.sh ~/.local/bin/gpu-load.sh
   chmod +x ~/.local/bin/spotify-info.sh
   chmod +x ~/.local/bin/gpu-load.sh
   ```

5. **Initialize Starship in your shell:**
   
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

### Scripts

| Source | Destination |
|--------|-------------|
| `scripts/spotify-info.sh` | `~/.local/bin/spotify-info.sh` |
| `scripts/gpu-load.sh` | `~/.local/bin/gpu-load.sh` |

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

### Scripts

#### `spotify-info.sh`
Displays currently playing music from any MPRIS-compatible player (Spotify, VLC, etc.)
- Works with any MPRIS player
- Shows artist and title
- Automatically hides when no music is playing

#### `gpu-load.sh`
Displays GPU utilization percentage
- **NVIDIA**: Uses `nvidia-smi`
- **AMD (ROCm)**: Uses `rocm-smi`
- **AMD (open-source)**: Falls back to sysfs (`/sys/class/drm/card*/device/gpu_busy_percent`)
- Automatically detects GPU vendor

## Dependencies

- `fastfetch` - [Installation](https://github.com/fastfetch-cli/fastfetch)
- `starship` - [Installation](https://starship.rs/guide/#%F0%9F%9A%80-installation)
- `dbus-send` - Usually comes with D-Bus (system package)
- `nvidia-smi` - Comes with NVIDIA drivers (for NVIDIA GPU load)
- `rocm-smi` - AMD ROCm tools (optional, for AMD GPU load)

## Customization

### Starship Colors
The Starship config uses the Catppuccin Mocha palette. To change colors, edit `~/.config/starship.toml` and modify the `[palettes.catppuccin_mocha]` section.

### Fastfetch Layout
To customize the Fastfetch display, edit `~/.config/fastfetch/config.jsonc` and modify the `modules` array.

## License

Personal dotfiles - feel free to use and modify as needed.

