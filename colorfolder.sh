#!/bin/bash
# (c) 2006-2024 Daniel Faust - hessijames@gmail.com
# Plasma 6 port maintained separately
#
# This file is published under the terms of the GPL
#
# v. 3.0.0 (Plasma 6 port)
#
# how to use:
#   remove icon from a .directory file:
#       colorfolder.sh remove /your/directory/.directory
#   set a red folder icon:
#       colorfolder.sh folder-red /your/directory/.directory
#
# One or more .directory files may follow the action argument; each is
# processed in turn.

DEBUG=0  # set to 1 in order to print debug messages to the log file
LOGFILE=~/.local/share/color_folder.log

log() {
    if [ "$DEBUG" != 0 ]; then
        echo "$(date) color folder: $1" >> "$LOGFILE"
    fi
}

ACTION="$1"
shift || true

if [ -z "$ACTION" ]; then
    log "no action given; aborting"
    exit 1
fi

# Process each remaining argument as a path to a .directory file.
for FILE in "$@"; do
    log "processing: $FILE"

    if [ -e "$FILE" ]; then
        log "$FILE exists"

        if [ "$ACTION" == "remove" ]; then
            # Comment out any Icon= line so the default folder icon returns.
            tmp=$(mktemp)
            sed "s/^Icon=.*/#&/g" "$FILE" > "$tmp" && mv "$tmp" "$FILE"
            log "$FILE icon removed!"
        else
            if grep -q "^#*Icon=" "$FILE"; then
                # Replace an existing (possibly commented-out) Icon= line.
                tmp=$(mktemp)
                sed "s/^#*Icon=.*/Icon=$ACTION/g" "$FILE" > "$tmp" && mv "$tmp" "$FILE"
                log "$FILE modified! (replaced icon)"
            elif grep -q "^\[Desktop Entry\]" "$FILE"; then
                # Has the section but no Icon key: add one right after the header.
                tmp=$(mktemp)
                sed "s/^\[Desktop Entry\]/[Desktop Entry]\\nIcon=$ACTION/g" "$FILE" > "$tmp" && mv "$tmp" "$FILE"
                log "$FILE modified! (added icon)"
            else
                # No section at all: append a fresh [Desktop Entry] + Icon.
                {
                    echo
                    echo "[Desktop Entry]"
                    echo "Icon=$ACTION"
                } >> "$FILE"
                log "$FILE modified! (added section + icon)"
            fi
        fi
    else
        log "$FILE doesn't exist"
        if [ "$ACTION" != "remove" ]; then
            {
                echo "[Desktop Entry]"
                echo "Icon=$ACTION"
            } > "$FILE"
            log "$FILE created!"
        fi
    fi

    # Nudge KIO/Dolphin into noticing the change. There is no reliable,
    # supported way to force Dolphin to refresh a single folder's icon from a
    # script, so we touch the folder to trip its inotify watch.
    FOLDER=$(dirname "$FILE")
    if [ -d "$FOLDER" ]; then
        touch "$FOLDER" 2>/dev/null || true
    fi
done
