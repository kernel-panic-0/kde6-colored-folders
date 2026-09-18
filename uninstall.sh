#!/bin/bash
# uninstall.sh - Color Folder uninstaller for KDE Plasma 6 (and 5)
# (c) 2024, GPL-2.0

desktop_file='colorfolder.desktop'
script_file='colorfolder.sh'

# ── Collect candidate service-menu directories ───────────────────────────────
# We remove from every path the files could plausibly live in, so a leftover
# install from either Plasma 5 or Plasma 6 is cleaned up regardless of which
# version is currently running.

collect_service_paths() {
    local paths=()
    local detected=""

    # Detected path (Plasma 6 first, then Plasma 5)
    if command -v kf6-config &>/dev/null; then
        detected=$(kf6-config --path services 2>/dev/null || true)
    elif command -v kf5-config &>/dev/null; then
        detected=$(kf5-config --path services 2>/dev/null || true)
    fi

    local p
    IFS=":" read -ra detected_paths <<< "$detected"
    for p in "${detected_paths[@]}"; do
        if [ -n "$p" ] && [[ "$p" != /usr/* ]]; then
            paths+=("$p")
        fi
    done

    # Always include the canonical Plasma 6 user-local path as a fallback,
    # in case neither kf6-config nor kf5-config is present.
    paths+=("$HOME/.local/share/kio/servicemenus")

    # De-duplicate while preserving order.
    printf '%s\n' "${paths[@]}"
}

removed=0

while IFS= read -r service_path; do
    [ -z "$service_path" ] && continue

    if [ -e "$service_path/$desktop_file" ]; then
        rm "$service_path/$desktop_file"
        echo "Removed: $service_path/$desktop_file"
        removed=1
    fi

    if [ -e "$service_path/$script_file" ]; then
        rm "$service_path/$script_file"
        echo "Removed: $service_path/$script_file"
        removed=1
    fi
done < <(collect_service_paths | awk '!seen[$0]++')

if [ $removed -eq 0 ]; then
    echo "Nothing to remove (files not found in any service-menu path)."
fi

# Rebuild sycoca
if command -v kbuildsycoca6 &>/dev/null; then
    kbuildsycoca6 2>/dev/null || true
elif command -v kbuildsycoca5 &>/dev/null; then
    kbuildsycoca5
fi

echo "Color Folder uninstalled."
