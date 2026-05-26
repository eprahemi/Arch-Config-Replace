#!/usr/bin/env bash

# ===========================================================================
#  Eprahemi Updated Dots — Restore Script
#  Restores all dotfiles, wallpapers, and themes to system locations
# ===========================================================================

set -e

# Read from installed version file first (keeps in sync with install.sh)
if [ -f "$HOME/.local/state/wiferice-version" ]; then
    source "$HOME/.local/state/wiferice-version"
    DOTS_VERSION="${LOCAL_VERSION:-1.7.92}"
else
    DOTS_VERSION="1.7.92"
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BACKUP_DIR="$HOME/.config/backup_$(date +%Y%m%d_%H%M%S)"
CURRENT_USER=$(whoami)

echo ""
echo "  ███████╗██╗    ██╗     ██╗      ██████╗"
echo "  ██╔════╝██║    ██║     ██║     ██╔════╝"
echo "  █████╗  ██║    ██║     ██║     ██║"
echo "  ██╔══╝  ██║    ██║     ██║     ██║"
echo "  ██║     ██║    ███████╗███████╗╚██████╗"
echo "  ╚═╝     ╚═╝    ╚══════╝╚══════╝ ╚═════╝"
echo ""
echo "  Eprahemi Updated Dots — System Restore"
echo "  User: $CURRENT_USER"
echo "  https://github.com/eprahemi"
echo ""
echo "  ──────────────────────────────────────────────"
echo ""

# ─── INSTALL DEPENDENCIES ─────────────────────────────────────────────

echo "  [1/9] Installing required packages..."
echo ""

if command -v pacman &>/dev/null; then
    sudo pacman -S --noconfirm --needed xdg-user-dirs xdg-desktop-portal-hyprland 2>/dev/null || true
    xdg-user-dirs-update 2>/dev/null || true
    echo "    [OK] xdg-user-dirs, xdg-desktop-portal-hyprland"
fi

echo ""

# ─── BACKUP EXISTING CONFIGS ──────────────────────────────────────────────

echo "  [2/9] Backing up current configs to: $BACKUP_DIR"
echo ""

mkdir -p "$BACKUP_DIR"
for dir in hypr kitty nvim rofi swaync matugen; do
    if [ -d "$HOME/.config/$dir" ]; then
        cp -r "$HOME/.config/$dir" "$BACKUP_DIR/" 2>/dev/null
        echo "    [BACKUP] ~/.config/$dir"
    fi
done

echo ""

# ─── RESTORE CONFIG FILES (Force overwrite) ───────────────────────────────

echo "  [3/9] Restoring configuration files..."
echo ""

# Hyprland (force overwrite all configs including config/ subdirectory)
if [ -d "$SCRIPT_DIR/Hyprland" ]; then
    rm -rf "$HOME/.config/hypr" 2>/dev/null || true
    mkdir -p "$HOME/.config/hypr"
    cp -rf "$SCRIPT_DIR/Hyprland"/* "$HOME/.config/hypr/"
    echo "    [RESTORED] Hyprland (force overwrite)"
fi

if [ -d "$SCRIPT_DIR/Kitty" ]; then
    rm -rf "$HOME/.config/kitty" 2>/dev/null || true
    mkdir -p "$HOME/.config/kitty"
    cp -f "$SCRIPT_DIR/Kitty"/* "$HOME/.config/kitty/"
    echo "    [RESTORED] Kitty"
fi

if [ -d "$SCRIPT_DIR/Neovim" ]; then
    rm -rf "$HOME/.config/nvim" 2>/dev/null || true
    mkdir -p "$HOME/.config/nvim"
    cp -f "$SCRIPT_DIR/Neovim"/* "$HOME/.config/nvim/"
    echo "    [RESTORED] Neovim"
fi

if [ -d "$SCRIPT_DIR/Rofi" ]; then
    rm -rf "$HOME/.config/rofi" 2>/dev/null || true
    mkdir -p "$HOME/.config/rofi"
    cp -f "$SCRIPT_DIR/Rofi"/* "$HOME/.config/rofi/"
    echo "    [RESTORED] Rofi"
fi

if [ -d "$SCRIPT_DIR/SwayNC" ]; then
    rm -rf "$HOME/.config/swaync" 2>/dev/null || true
    mkdir -p "$HOME/.config/swaync"
    cp -f "$SCRIPT_DIR/SwayNC"/* "$HOME/.config/swaync/"
    echo "    [RESTORED] SwayNC"
fi

if [ -d "$SCRIPT_DIR/Matugen" ]; then
    rm -rf "$HOME/.config/matugen" 2>/dev/null || true
    mkdir -p "$HOME/.config/matugen/templates"
    cp -f "$SCRIPT_DIR/Matugen/config.toml" "$HOME/.config/matugen/"
    cp -f "$SCRIPT_DIR/Matugen/templates"/* "$HOME/.config/matugen/templates/"
    echo "    [RESTORED] Matugen"
fi

echo ""

# ─── REGENERATE CONFIGS FOR CURRENT USER ───────────────────────────

echo "  [4/10] Regenerating configs for current user..."
echo ""

if [ -f "$HOME/.config/hypr/scripts/settings_watcher.sh" ]; then
    bash "$HOME/.config/hypr/scripts/settings_watcher.sh" --compile 2>/dev/null || true
    echo "    [OK] Configs regenerated for user $CURRENT_USER"
fi

echo ""

# ─── INSTALL .zshrc ─────────────────────────────────────────────────

echo "  [5/10] Installing .zshrc..."
echo ""

if [ -f "$SCRIPT_DIR/.zshrc" ] && [ ! -f "$HOME/.zshrc" ]; then
    cp -f "$SCRIPT_DIR/.zshrc" "$HOME/.zshrc"
    echo "    [INSTALLED] ~/.zshrc (first install)"
fi

echo ""

# ─── SDDM FACE ICON + WALLPAPER (never overwrite user's files) ────────

echo "  [6/10] Installing SDDM face icon and wallpaper..."
echo ""

# Face icon: only deploy if not already present
if [ -f "$SCRIPT_DIR/Faces/.face.icon" ]; then
    if [ ! -f /usr/share/sddm/faces/.face.icon ] && [ ! -f /usr/share/sddm/faces/.face ]; then
        if command -v sudo &>/dev/null; then
            sudo mkdir -p /usr/share/sddm/faces
            sudo cp -f "$SCRIPT_DIR/Faces/.face.icon" /usr/share/sddm/faces/.face.icon
        fi
        echo "    [INSTALLED] /usr/share/sddm/faces/.face.icon"
    else
        echo "    [SKIPPED] /usr/share/sddm/faces/.face.icon — user file exists"
    fi
fi

# Wallpaper: only deploy default if dir has no image files (any format)
# Also always deploy QML theme files (Main.qml, Colors.qml, etc.)
if [ -d "$SCRIPT_DIR/SDDM/matugen-minimal" ] && command -v sudo &>/dev/null; then
    sudo mkdir -p /usr/share/sddm/themes/matugen-minimal
    # Always update QML/theme files
    for f in "$SCRIPT_DIR/SDDM/matugen-minimal/"*; do
        filename=$(basename "$f")
        case "$filename" in
            wallpaper.png|wallpaper.jpg|wallpaper.jpeg|wallpaper.webp|wallpaper.bmp|background.png)
                ;;
            *)
                sudo cp -f "$f" /usr/share/sddm/themes/matugen-minimal/
                ;;
        esac
    done
    # Deploy default wallpaper only if user has none
    _has_wp=0
    for ext in png jpg jpeg webp bmp; do
        [ -f "/usr/share/sddm/themes/matugen-minimal/wallpaper.$ext" ] && _has_wp=1 && break
    done
    if [ "$_has_wp" -eq 0 ] && [ -f "$SCRIPT_DIR/SDDM-Wallpaper/wallpaper.png" ]; then
        sudo cp -f "$SCRIPT_DIR/SDDM-Wallpaper/wallpaper.png" /usr/share/sddm/themes/matugen-minimal/
        echo "    [INSTALLED] Default wallpaper to SDDM theme"
    else
        echo "    [SKIPPED] SDDM wallpaper — preserving user's"
    fi
fi

# Legacy LoginScreen Settings dir (no longer used by SDDM, kept for manual/hyprlock use)
mkdir -p "$HOME/.config/hypr/LoginScreen Settings/Wallpaper" "$HOME/.config/hypr/LoginScreen Settings/faces" 2>/dev/null || true

echo ""

# ─── COPY WALLPAPERS TO PICTURES FOLDER ───────────────────────────────

echo "  [7/10] Setting up wallpapers for picker (Super+W)..."
echo ""

LOCK_WALL_DIR="$HOME/.config/hypr/Lockscreen Wallpaper"
mkdir -p "$LOCK_WALL_DIR"
if [ -f "$SCRIPT_DIR/Wallpapers/README.md" ]; then
    cp -f "$SCRIPT_DIR/Wallpapers/README.md" "$LOCK_WALL_DIR/README.md" 2>/dev/null || true
fi
# Clean up old ~/.Wallpapers location (no longer used)
rm -rf "$HOME/.Wallpapers" 2>/dev/null || true
mkdir -p "$HOME/Pictures/Wallpapers"

if [ -d "$SCRIPT_DIR/Wallpapers" ]; then
    find "$SCRIPT_DIR/Wallpapers" -maxdepth 1 -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" -o -iname "*.gif" \) -exec cp -f {} "$HOME/Pictures/Wallpapers/" \;
    echo "    [COPIED] Wallpapers → ~/Pictures/Wallpapers/"
fi

echo "    [INFO] Add more wallpapers to ~/Pictures/Wallpapers/"

# Clear wallpaper picker thumbnail cache for a fresh start
rm -rf "$HOME/.cache/wallpaper_picker" 2>/dev/null || true
echo "    [OK] Wallpaper thumbnail cache cleared"

# Re-enable tumblerd thumbnail service and clear Thunar thumbnail cache
systemctl --user enable --now tumblerd 2>/dev/null || true
rm -rf "$HOME/.cache/thumbnails" 2>/dev/null || true
echo "    [OK] Thumbnail service re-enabled and Thunar thumbnail cache cleared"

echo ""

# ─── SDDM WALLPAPER ──────────────────────────────────────────

echo "  [8/10] Restoring SDDM wallpaper..."
echo ""

if [ -d "$SCRIPT_DIR/SDDM-Wallpaper" ]; then
    # Lock screen wallpaper — always restore the default, never touch user's custom lock image
    if command -v sudo &>/dev/null; then
        sudo mkdir -p /usr/share/wallpapers
        sudo cp -f "$SCRIPT_DIR/SDDM-Wallpaper/wallpaper.png" /usr/share/wallpapers/lock.png
        echo "    [RESTORED] /usr/share/wallpapers/lock.png (System default lockscreen)"
    fi
    # SDDM login wallpaper — always overwrite with latest
    if command -v sudo &>/dev/null; then
        sudo mkdir -p /usr/share/sddm/themes/matugen-minimal
        sudo cp -f "$SCRIPT_DIR/SDDM-Wallpaper/wallpaper.png" /usr/share/sddm/themes/matugen-minimal/wallpaper.png
        echo "    [RESTORED] /usr/share/sddm/themes/matugen-minimal/wallpaper.png (Login Screen)"
    fi
fi

echo ""

# ─── FIX KEYBINDINGS PERMISSIONS ─────────────────────────────────────

echo "  [9/10] Setting up keybinding permissions..."
echo ""

# Make scripts executable (use find to avoid glob failure when no .sh files exist)
find "$HOME/.config/hypr/scripts" -maxdepth 1 -name "*.sh" -exec chmod +x {} + 2>/dev/null || true
echo "    [OK] Scripts made executable"

echo ""

# ─── CLEANUP STALE REFERENCES ───────────────────────────────────────────

echo "  [10/10] Cleaning up stale references..."
echo ""

rm -f "$HOME/.local/state/imperative-dots-version" 2>/dev/null

# Remove stale # THE LOCATIONS.txt files from all config dirs
find "$HOME/.config" "$HOME/Pictures/Wallpapers" -name "# THE LOCATIONS.txt" -delete 2>/dev/null || true

echo "  [10/10] Writing version file..."
echo ""

mkdir -p "$HOME/.local/state"
echo "LOCAL_VERSION=\"$DOTS_VERSION\"" > "$HOME/.local/state/wiferice-version"
echo "    [VERSION] v$DOTS_VERSION"

echo ""

# ─── RELOAD HYPRLAND ────────────────────────────────────────────────────

echo "  Reloading Hyprland..."
hyprctl reload 2>/dev/null && echo "    [OK] Hyprland reloaded" || echo "    [WARN] Hyprland not running (reload manually)"

# ─── DONE ───────────────────────────────────────────────────────────────

echo ""
echo "  ──────────────────────────────────────────────"
echo ""
echo "  ✅ All configs restored successfully! (v$DOTS_VERSION)"
echo ""
echo "  👤 User: $CURRENT_USER"
echo "  📂 Old configs backed up to: $BACKUP_DIR"
echo ""
echo "  ⌨️  Keybindings:"
echo "     • Super+T = Open terminal (Kitty)"
echo "     • Super+W = Wallpaper picker"
echo "     • Super+Q = Close window"
echo "     • Super+D = App launcher"
echo "     • Super+H = Help/Guide"
echo ""
echo "  🖼  Face Icon:"
echo "     • Lockscreen → ~/.config/hypr/Faces/.face.icon"
echo "     • SDDM Login → /usr/share/sddm/faces/.face.icon"
echo "     • SDDM Override → ~/.config/hypr/LoginScreen Settings/faces/.face.icon"
echo ""
echo "  🖼  Wallpapers:"
echo "     • Folder → ~/Pictures/Wallpapers/ (for picker - Super+W)"
echo "     • Lockscreen → /usr/share/wallpapers/lock.png (default)"
echo "     • Login (SDDM) → /usr/share/sddm/themes/matugen-minimal/wallpaper.png"
echo "     • SDDM Override → ~/.config/hypr/LoginScreen Settings/Wallpaper/wallpaper.png"
echo ""
echo "  📝 Terminal:"
echo "     • ~/.zshrc installed (oh-my-zsh auto-installs)"
echo ""
echo "  ⚠️  Add your OpenWeather API key:"
echo "     Create: ~/.config/hypr/scripts/quickshell/calendar/.env"
echo ""
echo "  ──────────────────────────────────────────────"
echo ""
