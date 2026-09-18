#!/bin/bash
# install.sh - Color Folder installer for KDE Plasma 6 (and 5)
# (c) 2024, GPL-2.0

set -e

desktop_file_src='colorfolder-breeze.desktop'
desktop_file='colorfolder.desktop'
script_file='colorfolder.sh'

# ── Locate the user-writable service-menu directory ──────────────────────────
# Plasma 6 ships kio/servicemenus and kf6-config (the successor to kf5-config).
# qtpaths is NOT a Plasma 6 tool — it is Qt5-era — so we must not rely on it.
#
# Resolution order:
#   1. kf6-config --path services   (Plasma 6)
#   2. kf5-config --path services   (Plasma 5)
#   3. hard-coded Plasma 6 default  (~/.local/share/kio/servicemenus)
#
# From the colon-separated list we pick the first entry that is not system-wide
# (/usr/...), i.e. the one a normal user can write to.

resolve_service_path() {
    local config_tool=""

    if command -v kf6-config &>/dev/null; then
        config_tool="kf6-config"
    elif command -v kf5-config &>/dev/null; then
        config_tool="kf5-config"
    fi

    if [ -n "$config_tool" ]; then
        local paths p
        paths=$("$config_tool" --path services 2>/dev/null || true)
        IFS=":" read -ra paths <<< "$paths"
        for p in "${paths[@]}"; do
            # Skip empty and system-wide entries; keep the first user-writable one.
            if [ -n "$p" ] && [[ "$p" != /usr/* ]]; then
                echo "$p"
                return 0
            fi
        done
    fi

    # Fall back to the documented Plasma 6 user-local path.
    echo "$HOME/.local/share/kio/servicemenus"
}

service_path=$(resolve_service_path)

if [ -z "$service_path" ]; then
    kdialog --title "Color Folder" --error \
        "Installation failed: could not determine service menu path."
    exit 1
fi

# ── Create destination directory if needed ───────────────────────────────────
if [ ! -d "$service_path" ]; then
    echo "Creating directory: $service_path"
    mkdir -p "$service_path"
fi

# ── Copy files ───────────────────────────────────────────────────────────────
echo "Installing: $service_path/$desktop_file"
echo "Installing: $service_path/$script_file"

cp "./$desktop_file_src" "$service_path/$desktop_file"
cp "./$script_file"       "$service_path/$script_file"

# ── Rewrite script path inside the .desktop file ─────────────────────────────
full_script_path="$service_path/$script_file"
# Escape forward slashes for sed
escaped_path="${full_script_path//\//\\/}"
sed -i "s/colorfolder\.sh/$escaped_path/g" "$service_path/$desktop_file"

# ── Mark both files executable (required by Plasma 6 authorization check) ────
chmod +x "$service_path/$script_file"
chmod +x "$service_path/$desktop_file"

# ── Rebuild sycoca ────────────────────────────────────────────────────────────
# Plasma 6 uses kbuildsycoca6; fall back to kbuildsycoca5 for Plasma 5
if command -v kbuildsycoca6 &>/dev/null; then
    kbuildsycoca6 --noincremental 2>/dev/null || kbuildsycoca6
elif command -v kbuildsycoca5 &>/dev/null; then
    kbuildsycoca5
else
    echo "Warning: kbuildsycoca not found. You may need to log out and back in."
fi

echo "Color Folder installed successfully!"
echo "Right-click any folder in Dolphin to find the 'Tint' submenu."
