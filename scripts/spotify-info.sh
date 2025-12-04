#!/bin/bash
# Get current music track info via MPRIS/D-Bus (works with any MPRIS player)

# Find any MPRIS player (Spotify, VLC, Rhythmbox, etc.)
# Prefer Spotify if available, otherwise use first available player
all_players=$(dbus-send --print-reply --dest=org.freedesktop.DBus /org/freedesktop/DBus org.freedesktop.DBus.ListNames 2>/dev/null | grep -oP 'org\.mpris\.MediaPlayer2\.\K[^"]+')
spotify_player=$(echo "$all_players" | grep -i "^spotify$" | head -1)
player_service=${spotify_player:-$(echo "$all_players" | head -1)}

if [ -z "$player_service" ]; then
    exit 1
fi

# Check if player is playing
playback_status=$(dbus-send --print-reply --dest=org.mpris.MediaPlayer2.$player_service /org/mpris/MediaPlayer2 org.freedesktop.DBus.Properties.Get string:org.mpris.MediaPlayer2.Player string:PlaybackStatus 2>/dev/null | grep -oP 'string "\K[^"]+' | head -1)

if [ "$playback_status" != "Playing" ]; then
    exit 1
fi

# Get metadata
metadata=$(dbus-send --print-reply --dest=org.mpris.MediaPlayer2.$player_service /org/mpris/MediaPlayer2 org.freedesktop.DBus.Properties.Get string:org.mpris.MediaPlayer2.Player string:Metadata 2>/dev/null)

# Extract artist - handle array format (xesam:artist is an array!)
# Get all artist strings inside the array (skip the "xesam:artist" key itself)
artist=$(echo "$metadata" | grep -A 10 "xesam:artist" | grep -A 10 "array \[" | grep 'string "' | grep -v "xesam:" | sed -E 's/.*string "([^"]+)".*/\1/' | tr '\n' ',' | sed 's/,$//' | sed 's/,/, /g')

# Extract title
title=$(echo "$metadata" | grep -A 1 "xesam:title" | grep "variant" | sed -E 's/.*variant.*string "([^"]+)".*/\1/')

if [ -n "$artist" ] && [ -n "$title" ] && [ "$artist" != "xesam:artist" ]; then
    # Truncate if too long (max 45 chars to fit in prompt)
    track="$artist - $title"
    if [ ${#track} -gt 45 ]; then
        track="${track:0:42}..."
    fi
    echo "🎵 $track"
    exit 0
else
    exit 1
fi
