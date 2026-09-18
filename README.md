# Color Folder (Plasma 6 port)

A KDE Dolphin service menu for changing the colour of specific folders — compatible with **KDE Plasma 6**.

This is an unofficial port of [dfaust/kde-color-folder](https://github.com/dfaust/kde-color-folder), which supports KDE4 and Plasma 5. All original functionality is preserved; only the parts that broke under Plasma 6 have been updated.

---

## What changed for Plasma 6

| Area | Plasma 4/5 | Plasma 6 |
|---|---|---|
| **Service menu path** | `~/.local/share/kservices5/ServiceMenus/` | `~/.local/share/kio/servicemenus/` |
| **System-wide path** | `/usr/share/kservices5/ServiceMenus/` | `/usr/share/kio/servicemenus/` |
| **`.desktop` must be executable** | Not required | **Required** (security authorisation check) |
| **Config tool** | `kf5-config` | `kf6-config` |
| **Sycoca rebuild** | `kbuildsycoca5` | `kbuildsycoca6` |
| **`ServiceTypes=` key** | `KonqPopupMenu/Plugin` | Removed; use `MimeType=inode/directory;` only |

The install/uninstall scripts detect which version of Plasma is running (`kf6-config` for Plasma 6, `kf5-config` for Plasma 5, with a hard-coded fallback) and handle both automatically, so this port is backwards-compatible with Plasma 5 as well.

---

## Installation

### From source

```bash
chmod +x install.sh
./install.sh
```

That's it. Right-click any folder in Dolphin and look for the **Tint** submenu.

### Manual installation

```bash
# Create the directory (Plasma 6 path)
mkdir -p ~/.local/share/kio/servicemenus

# Copy files
cp colorfolder-breeze.desktop ~/.local/share/kio/servicemenus/colorfolder.desktop
cp colorfolder.sh              ~/.local/share/kio/servicemenus/colorfolder.sh

# Update the Exec path inside the .desktop file
SPATH=~/.local/share/kio/servicemenus
sed -i "s/colorfolder\.sh/${SPATH//\//\\/}\/colorfolder.sh/g" "$SPATH/colorfolder.desktop"

# Mark both files executable (mandatory for Plasma 6)
chmod +x ~/.local/share/kio/servicemenus/colorfolder.desktop
chmod +x ~/.local/share/kio/servicemenus/colorfolder.sh

# Rebuild service cache
kbuildsycoca6
```

---

## Uninstallation

```bash
chmod +x uninstall.sh
./uninstall.sh
```

---

## How it works

The service menu writes an `Icon=folder-<colour>` entry into the hidden `.directory` file inside each selected folder. Dolphin and KIO read this file to determine which icon to display. The colours available are: Red, Orange, Yellow, Green, Blue, Violet, Magenta, Brown, Cyan, Grey, Black.

The **Remove color** action comments out the `Icon=` line, restoring the default folder appearance. **Remove .directory file** deletes the `.directory` file entirely.

---

## Requirements

- KDE Plasma 6 / Dolphin 24.x
- Breeze icon theme (or any icon theme that includes `folder-red`, `folder-green`, etc.)
- `bash`

---

## Licence

GPL-2.0 — same as the original project.
