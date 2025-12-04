#!/bin/bash
# Get current media info via MPRIS/D-Bus (works with any MPRIS player)
# Supports music players (Spotify, VLC, etc.) and browser players (YouTube, Twitch, Netflix, etc.)

# Find any MPRIS player (Spotify, VLC, Rhythmbox, browsers, etc.)
# Prefer Spotify if available, otherwise use first available player
all_players=$(dbus-send --print-reply --dest=org.freedesktop.DBus /org/freedesktop/DBus org.freedesktop.DBus.ListNames 2>/dev/null | grep -oP 'org\.mpris\.MediaPlayer2\.\K[^"]+')

# Prefer Spotify first
spotify_player=$(echo "$all_players" | grep -i "^spotify$" | head -1)

# Then prefer non-browser players, but allow browsers as fallback
non_browser_players=$(echo "$all_players" | grep -viE "(chromium|brave|firefox|chrome|plasma-browser)" | head -1)
browser_players=$(echo "$all_players" | grep -iE "(chromium|brave|firefox|chrome|plasma-browser)" | head -1)

# Choose player: Spotify > non-browser > browser
player_service=${spotify_player:-${non_browser_players:-$browser_players}}

if [ -z "$player_service" ]; then
    exit 1
fi

# Detect if this is a browser player
is_browser=false
if echo "$player_service" | grep -qiE "(chromium|brave|firefox|chrome|plasma-browser)"; then
    is_browser=true
fi

# Check if player is playing
playback_status=$(dbus-send --print-reply --dest=org.mpris.MediaPlayer2.$player_service /org/mpris/MediaPlayer2 org.freedesktop.DBus.Properties.Get string:org.mpris.MediaPlayer2.Player string:PlaybackStatus 2>/dev/null | grep -oP 'string "\K[^"]+' | head -1)

if [ "$playback_status" != "Playing" ]; then
    exit 1
fi

# Get metadata
metadata=$(dbus-send --print-reply --dest=org.mpris.MediaPlayer2.$player_service /org/mpris/MediaPlayer2 org.freedesktop.DBus.Properties.Get string:org.mpris.MediaPlayer2.Player string:Metadata 2>/dev/null)

# Extract artist - handle array format (xesam:artist is an array!)
# For browsers, artist might be missing or malformed, so we'll be more lenient
artist=$(echo "$metadata" | grep -A 20 "xesam:artist" | grep -A 20 "array \[" | grep 'string "' | sed -E 's/.*string "([^"]+)".*/\1/' | grep -v "^$" | grep -vE "(xesam:|variant|array|dict)" | grep -v "^string$" | head -3 | tr '\n' ',' | sed 's/,$//' | sed 's/,/, /g')

# Extract title - more robust extraction
title=$(echo "$metadata" | grep -A 2 "xesam:title" | grep "variant" | sed -E 's/.*variant.*string "([^"]+)".*/\1/' | grep -v "^$" | grep -vE "(xesam:|variant)")

# Clean up: remove any remaining D-Bus artifacts and validate
artist=$(echo "$artist" | sed 's/string ""//g' | sed 's/^string$//g' | sed 's/^[[:space:],]*//' | sed 's/[[:space:],]*$//' | tr -d '"' | sed 's/^[[:space:]]*$//')
title=$(echo "$title" | sed 's/string ""//g' | sed 's/^string$//g' | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//' | tr -d '"' | sed 's/^[[:space:]]*$//')

# Check for D-Bus artifacts in the extracted values
has_artifacts=false
if echo "$artist" | grep -qE "(string|variant|array|dict|^,|,$)" || echo "$title" | grep -qE "(string|variant|array|dict)"; then
    has_artifacts=true
fi

# For browsers: if artist extraction failed or has artifacts, use a fallback
if [ "$is_browser" = true ]; then
    # If artist is empty or has artifacts, try to get it from xesam:albumArtist or use "YouTube"
    if [ -z "$artist" ] || [ "$has_artifacts" = true ]; then
        album_artist=$(echo "$metadata" | grep -A 2 "xesam:albumArtist" | grep "variant" | sed -E 's/.*variant.*string "([^"]+)".*/\1/' | grep -v "^$" | grep -vE "(xesam:|variant|string)")
        if [ -n "$album_artist" ] && ! echo "$album_artist" | grep -qE "(string|variant|array|dict)"; then
            artist="$album_artist"
        else
            # For browsers, if we can't get artist, just show title with a browser indicator
            artist=""
        fi
    fi
fi

# Validate title (must exist and be clean)
if [ -z "$title" ] || [ ${#title} -eq 0 ] || [ ${#title} -ge 100 ] || \
   [ "$title" = "xesam:title" ] || echo "$title" | grep -qE "(string|variant|array|dict)"; then
    exit 1
fi

# Check for specific platforms in title and assign appropriate icons
# This overrides everything - check most specific first
if echo "$title" | grep -qi "youtube"; then
    # YouTube video - show with YouTube icon, remove "YouTube" from title
    track=$(echo "$title" | sed 's/ - YouTube$//i' | sed 's/YouTube - //i' | sed 's/ - YouTube//i')
    emoji="󰗃"  # Nerd Font YouTube icon
elif echo "$title" | grep -qi "twitch"; then
    # Twitch stream - show with Twitch icon, remove "Twitch" from title
    track=$(echo "$title" | sed 's/ - Twitch$//i' | sed 's/Twitch - //i' | sed 's/ - Twitch//i')
    emoji=""  # Nerd Font Twitch icon
elif echo "$title" | grep -qi "netflix"; then
    # Netflix - show with Netflix icon
    track=$(echo "$title" | sed 's/ - Netflix$//i' | sed 's/Netflix - //i' | sed 's/ - Netflix//i')
    emoji="󰝆"  # Nerd Font Netflix icon
elif echo "$title" | grep -qi "spotify"; then
    # Spotify (web player) - show with Spotify icon
    track=$(echo "$title" | sed 's/ - Spotify$//i' | sed 's/Spotify - //i' | sed 's/ - Spotify//i')
    emoji="󰓇"  # Nerd Font Spotify icon
elif echo "$title" | grep -qi "hulu"; then
    # Hulu - show with Hulu icon
    track=$(echo "$title" | sed 's/ - Hulu$//i' | sed 's/Hulu - //i' | sed 's/ - Hulu//i')
    emoji="󰠩"  # Nerd Font Hulu icon
elif echo "$title" | grep -qi "amazon.*prime\|prime.*video"; then
    # Amazon Prime Video - show with Amazon icon
    track=$(echo "$title" | sed 's/ - Amazon.*$//i' | sed 's/Amazon.* - //i' | sed 's/ - Prime.*$//i')
    emoji=""  # Nerd Font Amazon icon
elif echo "$title" | grep -qi "vimeo"; then
    # Vimeo - show with Vimeo icon
    track=$(echo "$title" | sed 's/ - Vimeo$//i' | sed 's/Vimeo - //i' | sed 's/ - Vimeo//i')
    emoji="󰕷"  # Nerd Font Vimeo icon
elif echo "$title" | grep -qi "soundcloud"; then
    # SoundCloud - show with SoundCloud icon
    track=$(echo "$title" | sed 's/ - SoundCloud$//i' | sed 's/SoundCloud - //i' | sed 's/ - SoundCloud//i')
    emoji=""  # Nerd Font SoundCloud icon (or use music note)
elif echo "$title" | grep -qi "plex"; then
    # Plex - show with Plex icon
    track=$(echo "$title" | sed 's/ - Plex$//i' | sed 's/Plex - //i' | sed 's/ - Plex//i')
    emoji="󰚺"  # Nerd Font Plex icon
# Build output based on what we have
elif [ -n "$artist" ] && [ ${#artist} -gt 0 ] && [ ${#artist} -lt 100 ] && \
   [ "$artist" != "xesam:artist" ] && ! echo "$artist" | grep -qE "(string|variant|array|dict|^,|,$)"; then
    # Full format: Artist - Title
    track="$artist - $title"
    emoji="🎵"
else
    # Browser fallback: just show title
    if [ "$is_browser" = true ]; then
        track="$title"
        emoji="📺"  # Fallback video icon
    else
        track="$title"
        emoji="🎵"
    fi
fi

# Truncate if too long (max 45 chars to fit in prompt)
if [ ${#track} -gt 45 ]; then
    track="${track:0:42}..."
fi

echo "$emoji $track"
exit 0
