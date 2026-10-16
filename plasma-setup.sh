#!/usr/bin/env bash
# plasma-setup.sh — applies the KDE Plasma layout defined in this file.
#
# Flow:
#   1) installs the font, if missing (via the package manager, asks for sudo)
#   2) opens KDE's "Get New..." window so the KDE Store assets can be
#      installed manually and waits for confirmation, checking the install
#   3) applies the theme, app icons, KWin (KZones) and rebuilds panels/widgets
#
# Requires a running Plasma 6 session. Backs up the configs first.
set -euo pipefail

# ============================================================= DEFINITIONS ===

# Name (to search in the store) | .knsrc file (item type) | installed path
# Installed through KDE's "Get New..." window: they are tracked by KNewStuff
# and get updates through Discover.
ASSETS=(
  "Advanced Modern Clock|plasmoids.knsrc|$HOME/.local/share/plasma/plasmoids/com.github.vKaras1337.modernclock"
  "Panel Colorizer|plasmoids.knsrc|$HOME/.local/share/plasma/plasmoids/luisbocanegra.panel.colorizer"
  "Ars Dark Icons|icons.knsrc|$HOME/.local/share/icons/Ars-Dark-Icons"
  "Ars Light Icons|icons.knsrc|$HOME/.local/share/icons/Ars-Light-Icons"
  "KZones|kwinscripts.knsrc|$HOME/.local/share/kwin/scripts/kzones"
)

LOOK_AND_FEEL="org.kde.breezedark.desktop"
ICON_THEME="Ars-Dark-Icons"
FONT_FAMILY="Roboto Medium"          # installed in step 1 if missing

# Package that provides FONT_FAMILY for each package manager: manager | package.
# When changing the font, change the packages too
FONT_PACKAGES=(
  "dnf|google-roboto-fonts"
  "apt-get|fonts-roboto"
  "pacman|ttf-roboto"
  "zypper|google-roboto-fonts"
)
# No package in the repositories (e.g. AlmaLinux/EL10): latest official
# release, installed in the same folder and with the same .version that aapi
# uses, so the two don't duplicate the font
FONT_RELEASE_API="https://api.github.com/repos/googlefonts/roboto-3-classic/releases/latest"
FONT_RELEASE_DIR="/usr/local/share/fonts/roboto"

# Ships in assets/wallpapers/ next to the script and is copied to the user's
# pictures folder (~/Pictures/wallpapers), if it isn't there yet
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PICTURES_DIR="$(xdg-user-dir PICTURES 2>/dev/null || echo "$HOME/Pictures")"
WALLPAPER_SRC="$SCRIPT_DIR/assets/wallpapers/wallpaper_16.jpeg"
WALLPAPER="$PICTURES_DIR/wallpapers/$(basename "$WALLPAPER_SRC")"

VIRTUAL_DESKTOPS=4
VIRTUAL_DESKTOP_ROWS=2

TASK_LAUNCHERS="applications:systemsettings.desktop,applications:brave-origin.desktop,applications:brave-browser.desktop,applications:org.kde.konsole.desktop,applications:com.rtosta.zapzap.desktop,applications:com.slack.Slack.desktop,preferred://filemanager,applications:antigravity.desktop,applications:com.microsoft.VSCode.desktop,applications:com.spotify.Client.desktop,applications:org.kde.discover.desktop"

TRAY_ITEMS="org.kde.kdeconnect,org.kde.plasma.vault,org.kde.kscreen,org.kde.plasma.battery,org.kde.plasma.bluetooth,org.kde.plasma.brightness,org.kde.plasma.cameraindicator,org.kde.plasma.clipboard,org.kde.plasma.devicenotifier,org.kde.plasma.keyboardindicator,org.kde.plasma.keyboardlayout,org.kde.plasma.manage-inputmethod,org.kde.plasma.mediacontroller,org.kde.plasma.networkmanagement,org.kde.plasma.notifications,org.kde.plasma.printmanager,org.kde.plasma.volume,org.kde.plasma.weather"

PANEL_COLORIZER_PRESET="Transparent"

# Info strip at the top of the desktop, in display order:
# sensor | label | widest expected value (for measuring only) | extra.
# The "textonly" face splits the row into equal columns, all as wide as the
# widest item (label + value); if they don't fit, it wraps to another row and
# hides labels. That's why the "extra" items only go in if they still fit on
# screen, measured at runtime with the configured font (the kernel is usually
# the widest). @GPU_TEMP@ and @BATTERY@ become the machine's sensors; without
# them, the item is dropped. Colors follow the position, repeating a 6-color
# cycle when the extras go in and a 4-color one when they don't (see
# INFO_PALETTE in apply_layout)
INFO_ITEMS=(
  "os/system/uptime|Uptime|99 days 23:59:59|extra"
  "cpu/all/averageTemperature|CPU Temperature|100.0 °C|"
  "@GPU_TEMP@|GPU Temperature|100.0 °C|"
  "os/kernel/version|Kernel|@KERNEL@|"
  "os/plasma/plasmaVersion|KDE Plasma|@PLASMA@|"
  "disk/all/usedPercent|Disk Usage|100%|"
  "memory/physical/used|Used Memory|999.9 GiB|"
  "memory/swap/used|Used Swap|999.9 GiB|extra"
  "@BATTERY@/chargeRate|Charging Rate|-99.9 W|"
  "@BATTERY@/chargePercentage|Charge Percentage|100%|"
)

# Custom icon per app: .desktop file | icon name (from the theme above).
# The .desktop is generated from the one installed on the system, changing
# only the icon (if the app only has a local .desktop, it's edited in place);
# apps that aren't installed are skipped
ICON_OVERRIDES=(
  "brave-browser.desktop|brave-desktop-dev"
  "antigravity.desktop|antigravity"
)

KZONES_LAYOUTS=$(cat <<'JSON'
[
    {
        "name": "Priority Grid",
        "padding": 0,
        "zones": [
            {
                "x": 0,
                "y": 0,
                "height": 100,
                "width": 25
            },
            {
                "x": 25,
                "y": 0,
                "height": 100,
                "width": 50
            },
            {
                "x": 75,
                "y": 0,
                "height": 100,
                "width": 25
            }
        ]
    },
    {
        "name": "Quadrant Grid",
        "zones": [
            {
                "x": 0,
                "y": 0,
                "height": 50,
                "width": 50
            },
            {
                "x": 0,
                "y": 50,
                "height": 50,
                "width": 50
            },
            {
                "x": 50,
                "y": 50,
                "height": 50,
                "width": 50
            },
            {
                "x": 50,
                "y": 0,
                "height": 50,
                "width": 50
            }
        ]
    },
    {
        "name": "Double Grid",
        "padding": 5,
        "zones": [
            {
                "x": 0,
                "y": 0,
                "height": 100,
                "width": 50
            },
            {
                "x": 50,
                "y": 0,
                "height": 100,
                "width": 50
            }
        ]
    },
    {
        "name": "Triple Grid Left",
        "padding": 5,
        "zones": [
            {
                "x": 0,
                "y": 0,
                "height": 100,
                "width": 50
            },
            {
                "x": 50,
                "y": 0,
                "height": 50,
                "width": 50
            },
            {
                "x": 50,
                "y": 50,
                "height": 50,
                "width": 50
            }
        ]
    },
    {
        "name": "Triple Grid Right",
        "padding": 5,
        "zones": [
            {
                "x": 0,
                "y": 0,
                "height": 50,
                "width": 50
            },
            {
                "x": 0,
                "y": 50,
                "height": 50,
                "width": 50
            },
            {
                "x": 50,
                "y": 0,
                "height": 100,
                "width": 50
            }
        ]
    },
    {
        "name": "Bigger Grid",
        "padding": 17,
        "zones": [
            {
                "x": 0,
                "y": 0,
                "height": 100,
                "width": 1
            },
            {
                "x": 1,
                "y": 0,
                "height": 100,
                "width": 98
            },
            {
                "x": 99,
                "y": 0,
                "height": 100,
                "width": 1
            }
        ]
    },
    {
        "name": "Big Grid",
        "padding": 25,
        "zones": [
            {
                "x": 0,
                "y": 0,
                "height": 100,
                "width": 2
            },
            {
                "x": 2,
                "y": 0,
                "height": 100,
                "width": 96
            },
            {
                "x": 98,
                "y": 0,
                "height": 100,
                "width": 2
            }
        ]
    },
    {
        "name": "Social Grid",
        "padding": 20,
        "zones": [
            {
                "x": 0,
                "y": 0,
                "height": 100,
                "width": 15
            },
            {
                "x": 15,
                "y": 0,
                "height": 100,
                "width": 70
            },
            {
                "x": 85,
                "y": 0,
                "height": 100,
                "width": 15
            }
        ]
    },
    {
        "name": "Konsole Grid",
        "zones": [
            {
                "x": 0,
                "y": 0,
                "height": 7,
                "width": 100
            },
            {
                "x": 0,
                "y": 7,
                "height": 86,
                "width": 20
            },
            {
                "x": 0,
                "y": 93,
                "height": 7,
                "width": 100
            },
            {
                "x": 20,
                "y": 7,
                "height": 86,
                "width": 60
            },
            {
                "x": 80,
                "y": 7,
                "height": 86,
                "width": 20
            }
        ]
    },
    {
        "name": "Sixty Grid",
        "padding": 5,
        "zones": [
            {
                "x": 0,
                "y": 0,
                "height": 100,
                "width": 60
            },
            {
                "x": 60,
                "y": 0,
                "height": 100,
                "width": 40
            }
        ]
    },
    {
        "name": "Seventy Grid",
        "padding": 5,
        "zones": [
            {
                "x": 0,
                "y": 0,
                "height": 100,
                "width": 70
            },
            {
                "x": 70,
                "y": 0,
                "height": 100,
                "width": 30
            }
        ]
    },
    {
        "name": "Dolphin Grid",
        "padding": 20,
        "zones": [
            {
                "x": 0,
                "y": 0,
                "height": 100,
                "width": 40
            },
            {
                "x": 40,
                "y": 0,
                "height": 10,
                "width": 60
            },
            {
                "x": 40,
                "y": 10,
                "height": 90,
                "width": 60
            }
        ]
    }
]
JSON
)

# ================================================================ HELPERS ====

bold() { printf '\n\e[1m%s\e[0m\n' "$*"; }
info() { printf '\e[36m::\e[0m %s\n' "$*"; }
ok()   { printf '\e[32m✔\e[0m %s\n' "$*"; }
warn() { printf '\e[33m!\e[0m %s\n' "$*"; }
die()  { printf '\e[31m✘\e[0m %s\n' "$*" >&2; exit 1; }

qdbus() { if command -v qdbus-qt6 >/dev/null; then qdbus-qt6 "$@"; else qdbus6 "$@"; fi; }
plasma_js() { qdbus org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "$1"; }

# =========================================================== 1) FONT =========

step_font() {
  bold "━━ 1/3 — Font"
  if fc-list : family | grep -iF "$FONT_FAMILY" >/dev/null; then
    ok "Font '$FONT_FAMILY' already installed"
    return
  fi
  local entry pm pkg cmd=()
  for entry in "${FONT_PACKAGES[@]}"; do
    IFS='|' read -r pm pkg <<<"$entry"
    command -v "$pm" >/dev/null || continue
    case "$pm" in
      pacman) cmd=(pacman -S --noconfirm "$pkg") ;;
      *)      cmd=("$pm" install -y "$pkg") ;;
    esac
    break
  done
  if ((${#cmd[@]} > 0)); then
    info "Installing the font '$FONT_FAMILY' (sudo ${cmd[*]})"
    if sudo "${cmd[@]}"; then
      fc-cache -f >/dev/null 2>&1 || true
    else
      warn "Package unavailable — trying the official release"
    fi
  fi
  if ! fc-list : family | grep -iF "$FONT_FAMILY" >/dev/null; then
    info "Installing the font '$FONT_FAMILY' from the latest release ($FONT_RELEASE_API)"
    install_font_release || true
  fi
  if fc-list : family | grep -iF "$FONT_FAMILY" >/dev/null; then
    ok "Font installed"
  else
    warn "Failed to install the font — the layout will be applied with the default font"
  fi
}

# Downloads the latest release (zip), checks the SHA-256 that GitHub publishes
# and installs only the static hinted TTFs (the same ones as the packages; the
# variable font alongside would duplicate the families). Runs in a subshell to
# clean up the temp dir
install_font_release() (
  command -v curl >/dev/null || { warn "curl not found"; exit 1; }
  tmp="$(mktemp -d)"
  trap 'rm -rf "${tmp:?}"' EXIT
  curl -fsSL -H 'Accept: application/vnd.github+json' "$FONT_RELEASE_API" -o "$tmp/release.json" ||
    { warn "Could not query $FONT_RELEASE_API"; exit 1; }
  read -r tag url digest < <(python3 -I -c '
import json, sys
d = json.load(open(sys.argv[1]))
a = next((a for a in d.get("assets", []) if a["name"].endswith(".zip")), None)
if a: print(d["tag_name"], a["browser_download_url"], a.get("digest") or "")
' "$tmp/release.json") || true
  [[ -n "${url:-}" ]] || { warn "Release has no .zip file"; exit 1; }

  info "Downloading $tag"
  curl -fL --progress-bar "$url" -o "$tmp/font.zip" || { warn "Download failed"; exit 1; }
  if [[ "$digest" == sha256:* ]]; then
    sha256sum -c --quiet - <<<"${digest#sha256:}  $tmp/font.zip" || { warn "SHA-256 mismatch"; exit 1; }
  fi
  python3 -I -c '
import os, re, sys, zipfile
z, out = zipfile.ZipFile(sys.argv[1]), sys.argv[2]
os.makedirs(out)
for n in z.namelist():
    if re.match(r"hinted/static/[^/.][^/]*\.ttf$", n):   # without the __MACOSX/._* junk
        with open(os.path.join(out, os.path.basename(n)), "wb") as f:
            f.write(z.read(n))
' "$tmp/font.zip" "$tmp/ttf"
  compgen -G "$tmp/ttf/*.ttf" >/dev/null || { warn "No hinted/static TTF in the zip"; exit 1; }

  info "Installing to $FONT_RELEASE_DIR (sudo)"
  sudo rm -rf "${FONT_RELEASE_DIR:?}"
  sudo install -d -m 0755 "$FONT_RELEASE_DIR"
  sudo install -m 0644 "$tmp"/ttf/*.ttf "$FONT_RELEASE_DIR/"
  echo "$tag" | sudo tee "$FONT_RELEASE_DIR/.version" >/dev/null
  sudo fc-cache -f "$FONT_RELEASE_DIR" >/dev/null 2>&1 || true
)

# ========================================================= 2) ASSETS =========

# Item type name in the user's language (e.g. "Plasma Widgets")
knsrc_label() {
  local file="/usr/share/knsrcfiles/$1" lang="${LANG%%.*}" label
  label="$(grep -m1 "^Name\[$lang\]=" "$file" 2>/dev/null ||
           grep -m1 "^Name\[${lang%%_*}\]=" "$file" 2>/dev/null ||
           grep -m1 '^Name=' "$file" 2>/dev/null || true)"
  echo "${label#*=}"
}

# KNewStuff 6 can't open an item by ID (kns://), so it opens the window for
# the right type and the user searches by name
open_store() {
  info "Opening \"$(knsrc_label "$1")\" — search for: $2"
  knewstuff-dialog6 "$1" >/dev/null 2>&1 &
  disown
}

step_assets() {
  bold "━━ 2/3 — KDE Store assets"
  echo "For each item, open the window, search for the name and click Install."
  local entry name knsrc path choice missing i opened names e n k p
  while true; do
    echo
    i=0
    for entry in "${ASSETS[@]}"; do
      i=$((i + 1))
      IFS='|' read -r name knsrc path <<<"$entry"
      if [[ -e "$path" ]]; then
        printf '  %d) \e[32m✔\e[0m %-22s (%s)\n' "$i" "$name" "$(knsrc_label "$knsrc")"
      else
        printf '  %d) \e[33m•\e[0m %-22s (%s)\n' "$i" "$name" "$(knsrc_label "$knsrc")"
      fi
    done
    echo
    read -rp "Number to open, [a] all pending, [Enter] check, [q] quit: " choice

    if [[ "$choice" =~ ^[0-9]+$ ]] && ((choice >= 1 && choice <= ${#ASSETS[@]})); then
      IFS='|' read -r name knsrc path <<<"${ASSETS[choice - 1]}"
      open_store "$knsrc" "$name"
    elif [[ "$choice" =~ ^[aA]$ ]]; then
      # One window per type, listing the pending names of that type
      opened=" "
      for entry in "${ASSETS[@]}"; do
        IFS='|' read -r name knsrc path <<<"$entry"
        [[ -e "$path" || "$opened" == *" $knsrc "* ]] && continue
        names=""
        for e in "${ASSETS[@]}"; do
          IFS='|' read -r n k p <<<"$e"
          [[ "$k" == "$knsrc" && ! -e "$p" ]] && names+="${names:+, }$n"
        done
        open_store "$knsrc" "$names"
        opened+="$knsrc "
        sleep 1
      done
      [[ "$opened" == " " ]] && ok "Nothing pending"
    elif [[ -z "$choice" ]]; then
      missing=()
      for entry in "${ASSETS[@]}"; do
        IFS='|' read -r name knsrc path <<<"$entry"
        [[ -e "$path" ]] || missing+=("$name")
      done
      ((${#missing[@]} == 0)) && { ok "All assets installed"; return; }
      warn "Still not found: ${missing[*]}"
      warn "The layout is only applied after all of them are installed."
    elif [[ "$choice" =~ ^[qQ]$ ]]; then
      die "Cancelled — no settings were changed."
    else
      warn "Invalid option: $choice"
    fi
  done
}

# ========================================================= 3) LAYOUT =========

backup_configs() {
  BACKUP_DIR="$HOME/.config/plasma-setup-backup-$(date +%Y%m%d-%H%M%S)"
  mkdir -p "$BACKUP_DIR"
  local f
  for f in plasma-org.kde.plasma.desktop-appletsrc plasmashellrc kdeglobals kwinrc kscreenlockerrc plasmakeyboardrc dolphinrc; do
    [[ -f "$HOME/.config/$f" ]] && cp -a "$HOME/.config/$f" "$BACKUP_DIR/"
  done
  ok "Current configs backed up to $BACKUP_DIR"
}

apply_theme() {
  info "Global theme: $LOOK_AND_FEEL"
  plasma-apply-lookandfeel --apply "$LOOK_AND_FEEL" >/dev/null 2>&1 || warn "Failed to apply $LOOK_AND_FEEL"

  info "Icons: $ICON_THEME"
  # plasma-changeicons is outside PATH, in a different place per distro:
  # /usr/libexec (Fedora, openSUSE), /usr/lib/<multiarch>/libexec (Debian,
  # Ubuntu), /usr/lib (Arch)
  local changeicons="" c
  for c in /usr/libexec/plasma-changeicons /usr/lib/*/libexec/plasma-changeicons \
           /usr/lib/libexec/plasma-changeicons /usr/lib/plasma-changeicons \
           "$(command -v plasma-changeicons 2>/dev/null || true)"; do
    [[ -x "$c" ]] && { changeicons="$c"; break; }
  done
  if [[ -z "$changeicons" ]]; then
    # Without the tool: write it directly (applies to apps opened after login)
    warn "plasma-changeicons not found — writing the theme to kdeglobals"
    kwriteconfig6 --file kdeglobals --group Icons --key Theme "$ICON_THEME"
  elif ! "$changeicons" "$ICON_THEME" >/dev/null 2>&1; then
    warn "Icon theme $ICON_THEME not found"
  fi

  info "Fonts: $FONT_FAMILY"
  # 17-field QFont::toString format (the last one, styleName, empty). Qt
  # 6.11+ writes 19 (feature and variable axis counts), but Qt up to 6.10
  # rejects more than 17 ("QFont::fromString: Invalid description") and falls
  # back to the default font; 6.11+ reads the 17. Flatpaks read this kdeglobals
  # with the runtime's Qt
  local k
  for k in font:10 menuFont:10 toolBarFont:9 smallestReadableFont:8; do
    kwriteconfig6 --file kdeglobals --group General --key "${k%%:*}" "$FONT_FAMILY,${k##*:},-1,5,400,0,0,0,0,0,0,0,0,0,0,1,"
  done
  kwriteconfig6 --file kdeglobals --group WM --key activeFont "$FONT_FAMILY,10,-1,5,400,0,0,0,0,0,0,0,0,0,0,1,"
  kwriteconfig6 --file kdeglobals --group General --key XftAntialias true
  kwriteconfig6 --file kdeglobals --group General --key XftHintStyle hintslight
  kwriteconfig6 --file kdeglobals --group General --key XftSubPixel none

  if [[ ! -f "$WALLPAPER" && -f "$WALLPAPER_SRC" ]]; then
    mkdir -p "$(dirname "$WALLPAPER")"
    cp "$WALLPAPER_SRC" "$WALLPAPER" && info "Wallpaper copied to $WALLPAPER"
  fi
  if [[ -f "$WALLPAPER" ]]; then
    info "Wallpaper: $WALLPAPER"
    kwriteconfig6 --file kscreenlockerrc --group Greeter --group Wallpaper --group org.kde.image --group General --key Image "file://$WALLPAPER"
    kwriteconfig6 --file kscreenlockerrc --group Greeter --group Wallpaper --group org.kde.image --group General --key PreviewImage "file://$WALLPAPER"
  else
    warn "Wallpaper not found in $WALLPAPER or $WALLPAPER_SRC — skipping (current wallpaper kept)"
    WALLPAPER=""
  fi
  ok "Theme applied"
}

# Generates in ~/.local/share/applications (which takes precedence) a copy of
# the system .desktop changing only the Icon= of the main section; starting
# from the installed file keeps the package's translations and actions.
# Without a system .desktop (app installed only for the user), edits the local
# one. The previous local version goes to the backup
apply_icon_overrides() {
  local dest="$HOME/.local/share/applications" entry file icon src dir dirs
  IFS=: read -ra dirs <<<"${XDG_DATA_DIRS:-/usr/local/share:/usr/share}"
  dirs+=(/var/lib/flatpak/exports/share "$HOME/.local/share/flatpak/exports/share")
  for entry in "${ICON_OVERRIDES[@]}"; do
    IFS='|' read -r file icon <<<"$entry"
    src=""
    for dir in "${dirs[@]}"; do
      [[ "$dir" == "$HOME/.local/share" ]] && continue
      [[ -f "$dir/applications/$file" ]] && { src="$dir/applications/$file"; break; }
    done
    if [[ -z "$src" && -f "$dest/$file" ]]; then
      src="$BACKUP_DIR/$file"   # local only: edits from the backup copy
    elif [[ -z "$src" ]]; then
      warn "Icon for $file: app not installed — skipping"
      continue
    fi
    mkdir -p "$dest"
    [[ -f "$dest/$file" ]] && cp -a "$dest/$file" "$BACKUP_DIR/"
    sed '/^\[Desktop Entry\]/,/^\[/ s|^Icon=.*|Icon='"$icon"'|' "$src" >"$dest/$file"
    info "Icon for $file: $icon"
  done
  kbuildsycoca6 >/dev/null 2>&1 || true
}

apply_kwin() {
  info "KWin: $VIRTUAL_DESKTOPS virtual desktops in $VIRTUAL_DESKTOP_ROWS rows + KZones"
  kwriteconfig6 --file kwinrc --group Desktops --key Number "$VIRTUAL_DESKTOPS"
  kwriteconfig6 --file kwinrc --group Desktops --key Rows "$VIRTUAL_DESKTOP_ROWS"
  kwriteconfig6 --file kwinrc --group Plugins --key kzonesEnabled true
  kwriteconfig6 --file kwinrc --group Script-kzones --key layoutsJson "$KZONES_LAYOUTS"
  qdbus org.kde.KWin /KWin reconfigure >/dev/null 2>&1 || true

  # Creates the missing desktops and sets the rows in the current session
  # (no logout). Only creates, never removes, so desktops with open windows
  # aren't closed
  local vdm=(org.kde.KWin /VirtualDesktopManager) iface=org.kde.KWin.VirtualDesktopManager count
  count="$(qdbus "${vdm[@]}" "$iface.count" 2>/dev/null || echo 0)"
  while ((count > 0 && count < VIRTUAL_DESKTOPS)); do
    qdbus "${vdm[@]}" "$iface.createDesktop" "$count" "" >/dev/null 2>&1 || break
    count=$((count + 1))
  done
  qdbus "${vdm[@]}" "$iface.rows" "$VIRTUAL_DESKTOP_ROWS" >/dev/null 2>&1 || true
  ok "KWin configured"
}

# "Show popup when holding a key" (accented characters when holding a key)
# comes from plasma-keyboard (Plasma 6.7+); in versions without it, the option
# doesn't exist. It only reads the config at startup; KWin relaunches it when
# it exits by a signal (treats it as a crash), so ending it applies the change
# without logout
apply_keyboard() {
  command -v plasma-keyboard >/dev/null || return 0
  info "Keyboard: accent popup when holding a key disabled"
  [[ "$(kreadconfig6 --file plasmakeyboardrc --group General --key diacriticsPopupEnabled)" == false ]] && return 0
  kwriteconfig6 --file plasmakeyboardrc --group General --key diacriticsPopupEnabled false
  local old _
  old="$(pgrep -x plasma-keyboard || true)"
  [[ -n "$old" ]] || return 0
  pkill -x plasma-keyboard || true
  for _ in {1..20}; do
    sleep 0.5
    [[ "$(pgrep -x plasma-keyboard || true)" =~ ^[0-9]+$ && "$(pgrep -x plasma-keyboard)" != "$old" ]] && return 0
  done
  warn "KWin did not relaunch plasma-keyboard — the popup only goes away after logout/login"
}

# Dolphin always opens in the home folder ("Show on startup"), instead of
# restoring the folders and tabs from last time
apply_dolphin() {
  info "Dolphin: opens in the home folder ($HOME)"
  kwriteconfig6 --file dolphinrc --group General --key RememberOpenedTabs false
  kwriteconfig6 --file dolphinrc --group General --key HomeUrl "$HOME"
}

# System battery sensor (BAT0, BAT1...), ignoring peripherals (mouse etc.).
# ksystemstats identifies the battery by its UPower serial number and only
# uses the end of the UPower path (battery_BAT0) when it has no serial; that's
# why the ID changes from machine to machine (e.g. "power/3986" or
# "power/battery_BAT1"). Checks with kstatsviewer when available
battery_sensor() {
  local d name serial id list=""
  command -v kstatsviewer >/dev/null && list="$(kstatsviewer --list 2>/dev/null)"
  for d in /sys/class/power_supply/*; do
    [[ "$(cat "$d/type" 2>/dev/null)" == Battery && "$(cat "$d/scope" 2>/dev/null)" != Device ]] || continue
    name="$(basename "$d")"
    serial=""
    command -v upower >/dev/null &&
      serial="$(upower -i "/org/freedesktop/UPower/devices/battery_$name" 2>/dev/null | sed -n 's/^ *serial: *//p')"
    [[ -n "$serial" ]] || serial="$(cat "$d/serial_number" 2>/dev/null)"
    serial="$(sed 's/^[[:space:]]*//; s/[[:space:]]*$//' <<<"$serial")"   # like UPower
    for id in ${serial:+"$serial"} "battery_$name"; do
      if [[ -z "$list" ]] || grep -qF "power/$id/chargePercentage " <<<"$list"; then
        echo "power/$id"
        return
      fi
    done
  done
}

# GPU usage sensor for the CPU chart ("" if there is none).
# On hybrids (NVIDIA + integrated) uses only the integrated one: reading the
# NVIDIA makes ksystemstats run "nvidia-smi dmon", which wakes the dGPU every
# 2s and prevents RTD3. ksystemstats names each GPU by its DRM card number
# (card1 → gpu1), not by order; the PCI vendor of the same card tells whether
# it's NVIDIA (0x10de). To be safe, it also skips the gpuN whose name
# (gpu/gpuN/name, which only NVIDIA fills in) mentions NVIDIA; reading the
# name doesn't wake the GPU.
gpu_sensor() {
  local d n vendor nvidia=0 other=0
  local -A vendors=()   # card number → PCI vendor
  for d in /sys/class/drm/card[0-9]*; do
    n="${d##*/card}"
    [[ "$n" =~ ^[0-9]+$ ]] || continue   # skips connectors (card1-eDP-1 etc.)
    vendor="$(cat "$d/device/vendor" 2>/dev/null)"
    [[ -n "$vendor" ]] || continue
    vendors[$n]="$vendor"
    if [[ "$vendor" == 0x10de ]]; then nvidia=1; else other=1; fi
  done

  if ! command -v kstatsviewer >/dev/null; then
    # No way to choose the GPU: on hybrids, no GPU; otherwise, the aggregate
    ((nvidia && other)) || echo "gpu/all/usage"
    return
  fi
  local list; list="$(kstatsviewer --list 2>/dev/null)"
  grep -q '^gpu/all/usage ' <<<"$list" || return 0
  if ! ((nvidia && other)); then echo "gpu/all/usage"; return; fi

  local name
  for n in $(printf '%s\n' "${!vendors[@]}" | sort -n); do
    [[ "${vendors[$n]}" != 0x10de ]] && grep -q "^gpu/gpu$n/usage " <<<"$list" || continue
    name="$(timeout 5 kstatsviewer "gpu/gpu$n/name" 2>/dev/null | sed "s|^gpu/gpu$n/name ||")"
    [[ "$name" == *NVIDIA* ]] && continue
    echo "gpu/gpu$n/usage"
    return
  done
}

# GPU temperature sensor ("" if there is none), based on the GPU chosen in
# gpu_sensor (on hybrids, only the integrated one; reading the NVIDIA would
# wake the dGPU). Only counts if it reads a value > 0: the integrated Intel,
# for example, exposes the sensor but always returns 0 (its temperature is the
# CPU's own)
gpu_temp_sensor() {
  local usage="$1" list id value
  [[ -n "$usage" ]] && command -v kstatsviewer >/dev/null || return 0
  list="$(kstatsviewer --list 2>/dev/null)"
  if [[ "$usage" == gpu/all/usage ]]; then
    id="$(grep -oE '^gpu/gpu[0-9]+/temperature ' <<<"$list" | head -1 || true)"
  else
    id="${usage%/usage}/temperature "
    grep -qF "$id" <<<"$list" || return 0
  fi
  id="${id% }"
  [[ -n "$id" ]] || return 0
  value="$(timeout 5 kstatsviewer "$id" 2>/dev/null | sed "s|^$id ||")"
  awk -v v="$value" 'BEGIN { exit !(v + 0 > 0) }' && echo "$id"
  return 0
}

# Info strip items as JSON ([{id, label, width, extra}]), with this machine's
# sensors and the width of each one (label + value, in px) measured with Pango
# in the kdeglobals font. Without Pango, width is null and the layout uses
# only the fixed items
info_items_json() {
  local gpu_temp="$1" battery="$2" font kernel plasma
  font="$(kreadconfig6 --file kdeglobals --group General --key font 2>/dev/null || true)"
  kernel="$(uname -r)"
  plasma="$(plasmashell --version 2>/dev/null | awk '{print $NF}')"
  python3 -I - "${font:-Noto Sans,10}" "$gpu_temp" "$battery" "$kernel" "${plasma:-6.99.99}" "${INFO_ITEMS[@]}" <<'PY'
import json, sys
font, gpu_temp, battery, kernel, plasma, *rows = sys.argv[1:]
family, size = (font.split(",") + ["10"])[:2]
try:
    import gi
    gi.require_version("Pango", "1.0"); gi.require_version("PangoCairo", "1.0")
    from gi.repository import Pango, PangoCairo
    layout = Pango.Layout.new(PangoCairo.FontMap.get_default().create_context())
    layout.set_font_description(Pango.FontDescription.from_string(f"{family} {size}"))
    def width(s):
        layout.set_text(s, -1)
        return layout.get_pixel_extents()[1].width
except Exception:
    width = lambda s: None
subst = {"@GPU_TEMP@": gpu_temp, "@BATTERY@": battery, "@KERNEL@": kernel, "@PLASMA@": plasma}
items = []
for row in rows:
    sensor, label, sample, extra = row.split("|")
    for k, v in subst.items():
        if k in sensor or k in sample:
            if not v: break
            sensor, sample = sensor.replace(k, v), sample.replace(k, v)
    else:
        w = width(label), width(sample)
        items.append({"id": sensor, "label": label, "extra": extra == "extra",
                      "width": None if None in w else sum(w)})
print(json.dumps(items, ensure_ascii=False))
PY
}

apply_layout() {
  info "Rebuilding panels and widgets"

  # The Panel Colorizer preset comes from the installed plasmoid itself
  local preset="$HOME/.local/share/plasma/plasmoids/luisbocanegra.panel.colorizer/contents/ui/presets/$PANEL_COLORIZER_PRESET/settings.json"
  local colorizer="null"
  [[ -f "$preset" ]] && colorizer="$(python3 -c 'import json,sys; print(json.dumps(json.load(open(sys.argv[1]))["globalSettings"]))' "$preset")"

  local js
  js=$(cat <<'JS'
var WALLPAPER = "@WALLPAPER@";
var LAUNCHERS = "@LAUNCHERS@";
var COLORIZER = @COLORIZER@;
var GPU = "@GPU@";        // e.g. "gpu/all/usage", "gpu/gpu1/usage" (only the integrated one on hybrids) or ""
var INFO = @INFO@;        // info strip items (see INFO_ITEMS and info_items_json)

function cfg(w, group, values) {
  w.currentConfigGroup = group;
  for (var k in values) w.writeConfig(k, values[k]);
}

// Clears the current layout. The old panels are only removed after creating
// the new ones: creating a tray after the process has removed another one
// crashes plasmashell (Plasma 6.6), which comes back without the new tray.
// That's why the shell is also restarted before this script (step_layout)
var oldPanels = panels();
desktops().forEach(function (d) {
  d.widgets().forEach(function (w) { w.remove(); });
  if (WALLPAPER) {
    d.wallpaperPlugin = "org.kde.image";
    cfg(d, ["Wallpaper", "org.kde.image", "General"], { Image: "file://" + WALLPAPER });
  }
});

// Everything goes on the primary screen (in Plasma, screen 0). Without this,
// the new panel is born on KWin's active screen (the one with the
// mouse/focused window)
var PRIMARY = 0;

// ── Top panel: tray, clock, pager ──
var top = new Panel;
top.screen = PRIMARY;
top.location = "top";
top.height = 34;
top.floating = true;
top.lengthMode = "fit";
top.hiding = "autohide";
top.addWidget("org.kde.plasma.marginsseparator");
top.addWidget("org.kde.plasma.pager");
var tray = top.addWidget("org.kde.plasma.systemtray");   // items: see write_tray
cfg(top.addWidget("org.kde.plasma.digitalclock"), ["Appearance"], { fontWeight: 400 });
top.addWidget("org.kde.plasma.showdesktop");

// ── Left side panel: menu, tasks, Panel Colorizer ──
var leftPanel = new Panel;
leftPanel.screen = PRIMARY;
leftPanel.location = "left";
leftPanel.height = 52;
leftPanel.floating = true;
leftPanel.lengthMode = "fit";
leftPanel.hiding = "autohide";
leftPanel.addWidget("org.kde.plasma.kickerdash");
cfg(leftPanel.addWidget("org.kde.plasma.icontasks"), ["General"], { launchers: LAUNCHERS });
var colorizer = leftPanel.addWidget("luisbocanegra.panel.colorizer");
var colorizerCfg = { hideWidget: true, configurationOverrides: '{"overrides":{},"associations":[]}' };
if (COLORIZER) colorizerCfg.globalSettings = JSON.stringify(COLORIZER);
cfg(colorizer, ["General"], colorizerCfg);

oldPanels.forEach(function (p) { p.remove(); });

// ── Desktop widgets (primary screen) ──
var desk = desktopsForActivity(currentActivity()).filter(function (d) { return d.screen === PRIMARY; })[0] || desktops()[0];
var g = screenGeometry(desk.screen);
var W = g.width, H = g.height;
// The desktop snaps sizes to a 16px grid: compute directly on it.
// The three bottom charts have the same width; the leftover (< 48px) is
// split between the edges, keeping the group centered
var FW = Math.floor(W / 16) * 16, third = Math.floor(FW / 3 / 16) * 16;
var marginX = Math.floor((FW - 3 * third) / 2 / 16) * 16;

// Positions written later to ItemGeometries (addWidget alone doesn't pin them)
var placed = [];
function place(plugin, x, y, w, h) {
  var widget = desk.addWidget(plugin, x, y, w, h);
  placed.push("Applet-" + widget.id + ":" + x + "," + y + "," + w + "," + h + ",0;");
  return widget;
}

function monitor(x, y, w, h, face, sensors, colors, labels) {
  var m = place("org.kde.plasma.systemmonitor", x, y, w, h);
  cfg(m, [], { CurrentPreset: "org.kde.plasma.systemmonitor", UserBackgroundHints: "ShadowBackground" });
  cfg(m, ["Appearance"], { chartFace: face, showTitle: false, title: "" });
  cfg(m, ["Sensors"], { highPrioritySensorIds: JSON.stringify(sensors) });
  cfg(m, ["SensorColors"], colors);
  cfg(m, ["SensorLabels"], labels);
  if (face === "org.kde.ksysguard.linechart")
    cfg(m, ["org.kde.ksysguard.linechart", "General"], { showGridLines: false, showYAxisLabels: false });
}

// System info strip (top). Columns are as wide as the widest item, separated
// by gridUnit (the face's Legend spacing); the extras go in, in order, while
// the whole row fits in the screen width
function infoFits(list) {
  var widest = Math.max.apply(null, list.map(function (i) { return i.width; }));
  return list.length * (widest + gridUnit) - gridUnit <= FW;
}
var chosen = INFO.filter(function (i) { return !i.extra; });
INFO.forEach(function (i) {
  if (i.extra && i.width !== null && chosen.every(function (c) { return c.width !== null; }) &&
      infoFits(chosen.concat([i])))
    chosen.push(i);
});
var infoItems = INFO.filter(function (i) { return chosen.indexOf(i) >= 0; });   // original order
var infoSensors = [], infoLabels = {}, infoColors = {};
// Colors in item order, repeating the cycle. With the extras (more items):
// #00aaff #ff5500 #55ff7f #ffff7f #55ffff #ffaaff; without them: #00aaff #ff5500 #55ff7f #ffff00
var withExtras = infoItems.some(function (i) { return i.extra; });
var INFO_PALETTE = withExtras
  ? ["0,170,255", "255,85,0", "85,255,127", "255,255,127", "85,255,255", "255,170,255"]
  : ["0,170,255", "255,85,0", "85,255,127", "255,255,0"];
infoItems.forEach(function (item, i) {
  infoSensors.push(item.id);
  infoLabels[item.id] = item.label;
  infoColors[item.id] = INFO_PALETTE[i % INFO_PALETTE.length];
});
monitor(0, 0, FW, 64, "org.kde.ksysguard.textonly", infoSensors, infoColors, infoLabels);

// Big clock: day and date without localized names, 24h time
cfg(place("com.github.vKaras1337.modernclock", 0, 64, FW, 160), ["Appearance"],
  { use_local_day_name: false, use_local_date_name: false, use_24_hour_format: true });

// Charts at the bottom: CPU/GPU | Network | Disk
// Minimum height at which all three fit equally: 112px measured with gridUnit
// 18 (the CPU/GPU one can't go below that because of the legend). Scales with
// the machine's font and rounds to the desktop's 16px grid
var BOTTOM_H = Math.ceil(112 * gridUnit / 18 / 16) * 16, y = H - BOTTOM_H - 8;
// CPU + GPU usage (all of them, or only the integrated one on hybrids; see gpu_sensor)
var cpuSensors = ["cpu/all/usage"], cpuColors = { "cpu/all/usage": "0,170,255" }, cpuLabels = { "cpu/all/usage": "CPU" };
if (GPU) {
  cpuSensors.push(GPU);
  cpuColors[GPU] = "255,85,0";
  cpuLabels[GPU] = GPU === "gpu/all/usage" ? "GPUs" : "GPU";
}
monitor(marginX, y, third, BOTTOM_H, "org.kde.ksysguard.linechart", cpuSensors, cpuColors, cpuLabels);
monitor(marginX + third, y, third, BOTTOM_H, "org.kde.ksysguard.linechart",
  ["network/all/download", "network/all/upload"],
  { "network/all/download": "0,170,255", "network/all/upload": "255,85,0" },
  { "network/all/download": "Download", "network/all/upload": "Upload" });
monitor(marginX + 2 * third, y, third, BOTTOM_H, "org.kde.ksysguard.linechart",
  ["disk/all/write", "disk/all/read"],
  { "disk/all/read": "255,85,0", "disk/all/write": "0,170,255" },
  { "disk/all/read": "Read", "disk/all/write": "Write" });

print("INFO " + infoItems.length + "/" + INFO.length + " " + FW + "px " +
  infoItems.map(function (i) { return i.label + "=" + i.width; }).join(", ") + "\n");
print("DESK " + desk.id + " " + W + "x" + H + " " + placed.join("") + "\n");
print("TRAYID " + top.id + " " + tray.id + "\n");
JS
)
  js="${js//@WALLPAPER@/$WALLPAPER}"
  js="${js//@LAUNCHERS@/$TASK_LAUNCHERS}"
  js="${js//@COLORIZER@/$colorizer}"
  local gpu; gpu="$(gpu_sensor)"
  js="${js//@GPU@/$gpu}"
  js="${js//@INFO@/$(info_items_json "$(gpu_temp_sensor "$gpu")" "$(battery_sensor)")}"
  local out
  out="$(plasma_js "$js")" || die "Failed to apply the Plasma layout"
  read -r _ DESK_ID DESK_RES DESK_GEOM < <(grep '^DESK ' <<<"$out") || true
  [[ -n "${DESK_GEOM:-}" ]] || die "Plasma did not return the widget positions: $out"
  local info_line; info_line="$(grep -m1 '^INFO ' <<<"$out" || true)"
  [[ -n "$info_line" ]] && info "Info strip: ${info_line#INFO }"
  read -r _ TRAY_PANEL_ID TRAY_ID < <(grep '^TRAYID ' <<<"$out") || true
  ok "Panels and widgets created"
}

# Writes the tray items with plasmashell stopped (recent Plasma, where the
# tray is the containment itself). Configuring a freshly created tray live
# makes the shell start all items at once, which crashes plasmashell 6.6
# (crash inside the applets' QML) before it saves the new tray; on a normal
# startup the same items load without problems
write_tray() {
  [[ -n "${TRAY_ID:-}" ]] || return 0
  local key
  for key in extraItems knownItems; do
    kwriteconfig6 --file plasma-org.kde.plasma.desktop-appletsrc --group Containments --group "$TRAY_PANEL_ID" \
      --group Applets --group "$TRAY_ID" --group General --key "$key" "$TRAY_ITEMS"
  done
}

# Sets the tray items live. Runs after each plasmashell restart: on older
# Plasma the tray only gets a containment (SystrayContainmentId) after it has
# started, and that containment needs the items; on recent ones, write_tray
# already wrote the same items and this only checks
configure_tray() {
  # Where the items live depends on the Plasma version:
  #   - older: the tray creates its own containment (SystrayContainmentId)
  #     asynchronously; waits for it to exist (up to ~30s, slow VMs)
  #   - recent (e.g. 6.7): the tray itself is the containment and has no
  #     SystrayContainmentId; the items go in its [General]
  # The items go in as a JS string, with \ and " escaped
  local items="${TRAY_ITEMS//\\/\\\\}"
  items="${items//\"/\\\"}"
  local tray_js
  tray_js=$(cat <<'JS'
var ITEMS = "@ITEMS@", total = 0, done = 0;
panels().forEach(function (p) {
  p.widgets("org.kde.plasma.systemtray").forEach(function (t) {
    total++;
    var id = t.readConfig("SystrayContainmentId");
    var tray = id ? desktopById(id) : t;
    if (!tray) return;   // older Plasma: containment not created yet
    tray.currentConfigGroup = ["General"];
    // Already written by write_tray: rewriting it live makes the tray restart
    // the items while still loading them, which crashes plasmashell 6.6
    if (String(tray.readConfig("extraItems")) === ITEMS) { done++; return; }
    tray.writeConfig("extraItems", ITEMS);
    tray.writeConfig("knownItems", ITEMS);
    done++;
  });
});
print("TRAY " + done + "/" + total + "\n");
JS
)
  tray_js="${tray_js//@ITEMS@/$items}"
  local _ tray_out="" tray_ok=0
  for _ in {1..60}; do
    tray_out="$(plasma_js "$tray_js" 2>/dev/null | grep '^TRAY ' || true)"
    if [[ "$tray_out" =~ ^TRAY\ ([0-9]+)/([0-9]+)$ ]] &&
       ((BASH_REMATCH[2] > 0 && BASH_REMATCH[1] == BASH_REMATCH[2])); then
      tray_ok=1; break
    fi
    sleep 0.5
  done
  ((tray_ok)) || warn "Could not configure the tray items (${tray_out:-no response})"
}

# plasmashell may be running outside its systemd service (e.g. restarted
# after a crash); then "systemctl stop" doesn't fail, but doesn't end it either
stop_plasmashell() {
  systemctl --user stop plasma-plasmashell.service 2>/dev/null || true
  pgrep -x plasmashell >/dev/null && { kquitapp6 plasmashell >/dev/null 2>&1 || true; }
  local _
  for _ in {1..30}; do pgrep -x plasmashell >/dev/null || return 0; sleep 0.5; done
  die "plasmashell did not exit"
}

start_plasmashell() {
  systemctl --user start plasma-plasmashell.service 2>/dev/null || (kstart plasmashell >/dev/null 2>&1 &)
  local _
  for _ in {1..60}; do
    plasma_js 'print("ok")' 2>/dev/null | grep ok >/dev/null && { sleep 3; return 0; }
    sleep 0.5
  done
  die "plasmashell did not start"
}

# Writes the widget positions with plasmashell stopped (otherwise it
# overwrites them)
write_geometry() {
  local key
  for key in "ItemGeometries-$DESK_RES" ItemGeometriesHorizontal; do
    kwriteconfig6 --file plasma-org.kde.plasma.desktop-appletsrc \
      --group Containments --group "$DESK_ID" --key "$key" "$DESK_GEOM"
  done
}

# Checks panels, widgets and positions; prints whatever is wrong
verify_layout() {
  local errors=() out saved
  out="$(plasma_js '
    panels().forEach(function (p) {
      print("PANEL " + p.location + " screen" + p.screen + " " + p.widgets().map(function (w) { return w.type; }).join(",") + "\n");
      p.widgets("org.kde.plasma.systemtray").forEach(function (t) {
        var id = t.readConfig("SystrayContainmentId"), tray = id ? desktopById(id) : t, ok = false;
        if (tray) { tray.currentConfigGroup = ["General"]; ok = !!tray.readConfig("extraItems"); }
        print("TRAYC " + p.location + " " + (ok ? "ok" : "missing") + "\n");
      });
    });
    var d = desktopById('"$DESK_ID"');
    if (d) print("DESKW " + d.widgets().map(function (w) { return w.type; }).join(",") + "\n");
  ')"
  grep -q '^PANEL top .*org.kde.plasma.systemtray' <<<"$out" || errors+=("top panel missing or without tray")
  grep '^PANEL ' <<<"$out" | grep -vq '^PANEL [a-z]* screen0 ' && errors+=("panel off the primary screen: $(grep '^PANEL ' <<<"$out" | grep -v '^PANEL [a-z]* screen0 ' | cut -d' ' -f2-3 | tr '\n' ' ')")
  # Without configured items, the tray can end up empty and, with the panel in "fit", invisible
  grep -q '^TRAYC top ok' <<<"$out" || errors+=("top panel tray has no configured items")
  grep -q '^PANEL left .*org.kde.plasma.icontasks' <<<"$out" || errors+=("side panel missing or without tasks")
  local deskw; deskw="$(grep '^DESKW ' <<<"$out" || true)"
  [[ "$(grep -o 'org.kde.plasma.systemmonitor' <<<"$deskw" | wc -l)" -eq 4 ]] || errors+=("expected 4 system monitors on the desktop")
  grep -q 'com.github.vKaras1337.modernclock' <<<"$deskw" || errors+=("desktop clock missing")

  saved="$(kreadconfig6 --file plasma-org.kde.plasma.desktop-appletsrc --group Containments --group "$DESK_ID" --key "ItemGeometries-$DESK_RES")"
  local bad
  # Plasma snaps widgets to a 16px grid, may raise the height up to the
  # widget's minimum and rescale positions at another resolution; so it checks
  # the structure, with a 2-cell (32px) tolerance, and not the exact coordinate:
  #   top: full-width ones start at the left and cover the screen; the others
  #        stay near the expected x/width; all near y
  #   bottom: left to right without overlap, covering the width, with the
  #           same width (height/bottom edge: warning only)
  bad="$(python3 - "$DESK_GEOM" "$saved" "${DESK_RES%x*}" "${DESK_RES#*x}" <<'PY2'
import sys
def parse(s):
    r = {}
    for item in filter(None, s.split(";")):
        k, v = item.split(":")
        r[k] = [float(x) for x in v.split(",")[:4]]
    return r
want, got = parse(sys.argv[1]), parse(sys.argv[2])
W, H, TOL = float(sys.argv[3]), float(sys.argv[4]), 32
bottom = []
for k, (x, y, w, h) in want.items():
    g = got.get(k)
    if g is None:
        print(f"{k}: not found"); continue
    gx, gy, gw, gh = g
    if y < H / 2:
        if w >= W - TOL and (gx > TOL or gw < W - TOL):
            print(f"{k}: should span the full width, current x={gx:g} w={gw:g} (screen {W:g})")
        if w < W - TOL and (abs(gx - x) > TOL or abs(gw - w) > TOL):
            print(f"{k}: expected x≈{x:g} w≈{w:g}, current x={gx:g} w={gw:g}")
        if abs(gy - y) > 48:
            print(f"{k}: should be at the top (y≈{y:g}), current y={gy:g}")
    else:
        bottom.append((gx, gw, gy, gh, k))
        if abs(gx - x) > TOL or abs(gw - w) > TOL:
            print(f"{k}: expected x≈{x:g} w≈{w:g}, current x={gx:g} w={gw:g}")
        if abs((gy + gh) - (y + h)) > 16:
            print(f"WARN {k}: doesn't touch the bottom ({y + h:g}), current {gy + gh:g}")
bottom.sort()
for a, b in zip(bottom, bottom[1:]):
    if a[0] + a[1] > b[0] + 2:
        print(f"{a[4]} and {b[4]} overlap")
if bottom:
    if bottom[0][0] > TOL or bottom[-1][0] + bottom[-1][1] < W - TOL:
        print(f"bottom monitors don't cover the width (from {bottom[0][0]:g} to {bottom[-1][0] + bottom[-1][1]:g}, screen {W:g})")
    hs = [b[3] for b in bottom]
    if max(hs) - min(hs) > 2:
        print(f"WARN bottom monitors with different heights: {hs}")
    ws = [b[1] for b in bottom]
    if max(ws) - min(ws) > 2:
        print(f"bottom monitors with different widths: {ws}")
PY2
)"
  # Height is only a warning: Plasma enforces each widget's minimum
  local line
  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    if [[ "$line" == WARN* ]]; then warn "${line#WARN }"; else errors+=("wrong position — $line"); fi
  done <<<"$bad"

  ((${#errors[@]} == 0)) && return 0
  local e; for e in "${errors[@]}"; do warn "$e"; done
  return 1
}

step_layout() {
  bold "━━ 3/3 — Applying layout"
  backup_configs
  apply_theme
  apply_icon_overrides
  apply_kwin
  apply_keyboard
  apply_dolphin
  # Freshly started shell: if it has already removed a tray (e.g. the user
  # deleted a panel), creating another one crashes it (Plasma 6.6); see
  # apply_layout
  info "Restarting plasmashell before rebuilding the panels"
  stop_plasmashell
  start_plasmashell
  apply_layout

  local attempt
  for attempt in 1 2 3; do
    info "Pinning widget positions and restarting plasmashell (attempt $attempt/3)"
    stop_plasmashell
    write_geometry
    write_tray
    start_plasmashell
    configure_tray
    if verify_layout; then
      ok "Layout verified: panels, widgets and positions correct"
      echo
      ok "Done! Log out and back in so fonts and colors take effect in all apps."
      return
    fi
  done
  die "The layout didn't turn out as expected after 3 attempts (config backup above)."
}

# =================================================================== MAIN ====

pgrep -x plasmashell >/dev/null || die "Run inside a running Plasma session."

step_font
step_assets
step_layout
