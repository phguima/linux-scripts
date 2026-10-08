#!/usr/bin/env bash
# plasma-setup.sh — aplica o layout do KDE Plasma definido neste arquivo.
#
# Fluxo:
#   1) instala a fonte, se faltar (via gerenciador de pacotes, pede sudo)
#   2) abre a janela "Obter novos..." do KDE para instalar os assets da
#      KDE Store manualmente e espera a confirmação, verificando a instalação
#   3) aplica tema, ícones de apps, KWin (KZones) e recria painéis/widgets
#
# Requer uma sessão Plasma 6 em execução. Faz backup das configs antes.
set -euo pipefail

# ============================================================== DEFINIÇÕES ===

# Nome (para buscar na loja) | arquivo .knsrc (tipo de item) | caminho instalado
# Instalados pela janela "Obter novos..." do KDE: ficam no registro do
# KNewStuff e recebem atualizações pelo Discover.
ASSETS=(
  "Advanced Modern Clock|plasmoids.knsrc|$HOME/.local/share/plasma/plasmoids/com.github.vKaras1337.modernclock"
  "Panel Colorizer|plasmoids.knsrc|$HOME/.local/share/plasma/plasmoids/luisbocanegra.panel.colorizer"
  "Ars Dark Icons|icons.knsrc|$HOME/.local/share/icons/Ars-Dark-Icons"
  "Ars Light Icons|icons.knsrc|$HOME/.local/share/icons/Ars-Light-Icons"
  "KZones|kwinscripts.knsrc|$HOME/.local/share/kwin/scripts/kzones"
)

LOOK_AND_FEEL="org.kde.breezedark.desktop"
ICON_THEME="Ars-Dark-Icons"
FONT_FAMILY="Roboto Medium"          # instalada no passo 1 se faltar

# Vem em assets/wallpapers/ ao lado do script e é copiado para a pasta de
# imagens do usuário (~/Pictures/wallpapers), se ainda não estiver lá
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PICTURES_DIR="$(xdg-user-dir PICTURES 2>/dev/null || echo "$HOME/Pictures")"
WALLPAPER_SRC="$SCRIPT_DIR/assets/wallpapers/wallpaper_16.jpeg"
WALLPAPER="$PICTURES_DIR/wallpapers/$(basename "$WALLPAPER_SRC")"

VIRTUAL_DESKTOPS=4
VIRTUAL_DESKTOP_ROWS=2

TASK_LAUNCHERS="applications:systemsettings.desktop,applications:brave-origin.desktop,applications:brave-browser.desktop,applications:org.kde.konsole.desktop,applications:com.rtosta.zapzap.desktop,preferred://filemanager,applications:antigravity.desktop,applications:com.microsoft.VSCode.desktop,applications:com.spotify.Client.desktop,applications:org.kde.discover.desktop"

TRAY_ITEMS="org.kde.kdeconnect,org.kde.plasma.vault,org.kde.kscreen,org.kde.plasma.battery,org.kde.plasma.bluetooth,org.kde.plasma.brightness,org.kde.plasma.cameraindicator,org.kde.plasma.clipboard,org.kde.plasma.devicenotifier,org.kde.plasma.keyboardindicator,org.kde.plasma.keyboardlayout,org.kde.plasma.manage-inputmethod,org.kde.plasma.mediacontroller,org.kde.plasma.networkmanagement,org.kde.plasma.notifications,org.kde.plasma.printmanager,org.kde.plasma.volume,org.kde.plasma.weather"

PANEL_COLORIZER_PRESET="Transparent"

# Ícone personalizado por app: arquivo .desktop | nome do ícone (do tema acima).
# O .desktop é gerado a partir do instalado no sistema, trocando só o ícone
# (se o app só tiver .desktop local, ele é editado no lugar); app não
# instalado é pulado
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
ask()  { local a; read -rp "$1 " a; [[ "$a" =~ ^[sS] ]]; }

qdbus() { if command -v qdbus-qt6 >/dev/null; then qdbus-qt6 "$@"; else qdbus6 "$@"; fi; }
plasma_js() { qdbus org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "$1"; }

# ========================================================== 1) FONTE =========

step_font() {
  bold "━━ 1/3 — Fonte"
  if fc-list : family | grep -iF "$FONT_FAMILY" >/dev/null; then
    ok "Fonte '$FONT_FAMILY' já instalada"
    return
  fi
  local cmd
  if command -v dnf >/dev/null; then cmd=(dnf install -y google-roboto-fonts)
  elif command -v apt-get >/dev/null; then cmd=(apt-get install -y fonts-roboto)
  elif command -v pacman >/dev/null; then cmd=(pacman -S --noconfirm ttf-roboto)
  elif command -v zypper >/dev/null; then cmd=(zypper install -y google-roboto-fonts)
  else warn "Gerenciador de pacotes não suportado — instale a fonte '$FONT_FAMILY' manualmente"; return
  fi
  info "Instalando a fonte '$FONT_FAMILY' (sudo ${cmd[*]})"
  if sudo "${cmd[@]}"; then
    fc-cache -f >/dev/null 2>&1 || true
    ok "Fonte instalada"
  else
    warn "Falha ao instalar a fonte — o layout será aplicado com a fonte padrão"
  fi
}

# ========================================================= 2) ASSETS =========

# Nome do tipo de item no idioma do usuário (ex.: "Widgets do Plasma")
knsrc_label() {
  local file="/usr/share/knsrcfiles/$1" lang="${LANG%%.*}" label
  label="$(grep -m1 "^Name\[$lang\]=" "$file" 2>/dev/null ||
           grep -m1 "^Name\[${lang%%_*}\]=" "$file" 2>/dev/null ||
           grep -m1 '^Name=' "$file" 2>/dev/null || true)"
  echo "${label#*=}"
}

# O KNewStuff 6 não abre um item pelo ID (kns://), então abre a janela do
# tipo certo e o usuário busca pelo nome
open_store() {
  info "Abrindo \"$(knsrc_label "$1")\" — busque por: $2"
  knewstuff-dialog6 "$1" >/dev/null 2>&1 &
  disown
}

step_assets() {
  bold "━━ 2/3 — Assets da KDE Store"
  echo "Para cada item, abra a janela, busque pelo nome e clique em Instalar."
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
    read -rp "Número para abrir, [t] todos os pendentes, [Enter] verificar, [q] sair: " choice

    if [[ "$choice" =~ ^[0-9]+$ ]] && ((choice >= 1 && choice <= ${#ASSETS[@]})); then
      IFS='|' read -r name knsrc path <<<"${ASSETS[choice - 1]}"
      open_store "$knsrc" "$name"
    elif [[ "$choice" =~ ^[tT]$ ]]; then
      # Uma janela por tipo, listando os nomes pendentes daquele tipo
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
      [[ "$opened" == " " ]] && ok "Nada pendente"
    elif [[ -z "$choice" ]]; then
      missing=()
      for entry in "${ASSETS[@]}"; do
        IFS='|' read -r name knsrc path <<<"$entry"
        [[ -e "$path" ]] || missing+=("$name")
      done
      ((${#missing[@]} == 0)) && { ok "Todos os assets instalados"; return; }
      warn "Ainda não encontrei: ${missing[*]}"
      warn "O layout só é aplicado depois que todos estiverem instalados."
    elif [[ "$choice" =~ ^[qQ]$ ]]; then
      die "Cancelado — nenhuma configuração foi alterada."
    else
      warn "Opção inválida: $choice"
    fi
  done
}

# ========================================================= 3) LAYOUT =========

backup_configs() {
  BACKUP_DIR="$HOME/.config/plasma-setup-backup-$(date +%Y%m%d-%H%M%S)"
  mkdir -p "$BACKUP_DIR"
  local f
  for f in plasma-org.kde.plasma.desktop-appletsrc plasmashellrc kdeglobals kwinrc kscreenlockerrc; do
    [[ -f "$HOME/.config/$f" ]] && cp -a "$HOME/.config/$f" "$BACKUP_DIR/"
  done
  ok "Backup das configs atuais em $BACKUP_DIR"
}

apply_theme() {
  info "Tema global: $LOOK_AND_FEEL"
  plasma-apply-lookandfeel --apply "$LOOK_AND_FEEL" >/dev/null 2>&1 || warn "Falha ao aplicar $LOOK_AND_FEEL"

  info "Ícones: $ICON_THEME"
  /usr/libexec/plasma-changeicons "$ICON_THEME" >/dev/null 2>&1 || warn "Tema de ícones $ICON_THEME não encontrado"

  info "Fontes: $FONT_FAMILY"
  local k
  for k in font:10 menuFont:10 toolBarFont:9 smallestReadableFont:8; do
    kwriteconfig6 --file kdeglobals --group General --key "${k%%:*}" "$FONT_FAMILY,${k##*:},-1,5,400,0,0,0,0,0,0,0,0,0,0,1,,0,0"
  done
  kwriteconfig6 --file kdeglobals --group WM --key activeFont "$FONT_FAMILY,10,-1,5,400,0,0,0,0,0,0,0,0,0,0,1,,0,0"
  kwriteconfig6 --file kdeglobals --group General --key XftAntialias true
  kwriteconfig6 --file kdeglobals --group General --key XftHintStyle hintslight
  kwriteconfig6 --file kdeglobals --group General --key XftSubPixel none

  if [[ ! -f "$WALLPAPER" && -f "$WALLPAPER_SRC" ]]; then
    mkdir -p "$(dirname "$WALLPAPER")"
    cp "$WALLPAPER_SRC" "$WALLPAPER" && info "Wallpaper copiado para $WALLPAPER"
  fi
  if [[ -f "$WALLPAPER" ]]; then
    info "Wallpaper: $WALLPAPER"
    kwriteconfig6 --file kscreenlockerrc --group Greeter --group Wallpaper --group org.kde.image --group General --key Image "file://$WALLPAPER"
    kwriteconfig6 --file kscreenlockerrc --group Greeter --group Wallpaper --group org.kde.image --group General --key PreviewImage "file://$WALLPAPER"
  else
    warn "Wallpaper não encontrado em $WALLPAPER nem em $WALLPAPER_SRC — pulando (papel de parede atual mantido)"
    WALLPAPER=""
  fi
  ok "Tema aplicado"
}

# Gera em ~/.local/share/applications (que tem prioridade) uma cópia do .desktop
# do sistema trocando só o Icon= da seção principal; partir do arquivo instalado
# mantém traduções e ações do pacote. Sem .desktop no sistema (app instalado só
# para o usuário), edita o local. A versão local anterior vai para o backup
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
      src="$BACKUP_DIR/$file"   # só local: edita a partir da cópia do backup
    elif [[ -z "$src" ]]; then
      warn "Ícone de $file: app não instalado — pulando"
      continue
    fi
    mkdir -p "$dest"
    [[ -f "$dest/$file" ]] && cp -a "$dest/$file" "$BACKUP_DIR/"
    sed '/^\[Desktop Entry\]/,/^\[/ s|^Icon=.*|Icon='"$icon"'|' "$src" >"$dest/$file"
    info "Ícone de $file: $icon"
  done
  kbuildsycoca6 >/dev/null 2>&1 || true
}

apply_kwin() {
  info "KWin: $VIRTUAL_DESKTOPS áreas de trabalho em $VIRTUAL_DESKTOP_ROWS linhas + KZones"
  kwriteconfig6 --file kwinrc --group Desktops --key Number "$VIRTUAL_DESKTOPS"
  kwriteconfig6 --file kwinrc --group Desktops --key Rows "$VIRTUAL_DESKTOP_ROWS"
  kwriteconfig6 --file kwinrc --group Plugins --key kzonesEnabled true
  kwriteconfig6 --file kwinrc --group Script-kzones --key layoutsJson "$KZONES_LAYOUTS"
  qdbus org.kde.KWin /KWin reconfigure >/dev/null 2>&1 || true

  # Cria as áreas que faltam e ajusta as linhas na sessão atual (sem logout).
  # Só cria, nunca remove, para não fechar áreas com janelas abertas
  local vdm=(org.kde.KWin /VirtualDesktopManager) iface=org.kde.KWin.VirtualDesktopManager count
  count="$(qdbus "${vdm[@]}" "$iface.count" 2>/dev/null || echo 0)"
  while ((count > 0 && count < VIRTUAL_DESKTOPS)); do
    qdbus "${vdm[@]}" "$iface.createDesktop" "$count" "" >/dev/null 2>&1 || break
    count=$((count + 1))
  done
  qdbus "${vdm[@]}" "$iface.rows" "$VIRTUAL_DESKTOP_ROWS" >/dev/null 2>&1 || true
  ok "KWin configurado"
}

# Sensor da bateria do sistema (BAT0, BAT1...), ignorando periféricos (mouse etc.).
# O ksystemstats identifica a bateria pelo número de série do UPower e só usa
# o fim do caminho UPower (battery_BAT0) quando ela não tem série; por isso o
# ID muda de máquina para máquina (ex.: "power/3986" ou "power/battery_BAT1").
# Confere no kstatsviewer quando disponível
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
    serial="$(sed 's/^[[:space:]]*//; s/[[:space:]]*$//' <<<"$serial")"   # como o UPower
    for id in ${serial:+"$serial"} "battery_$name"; do
      if [[ -z "$list" ]] || grep -qF "power/$id/chargePercentage " <<<"$list"; then
        echo "power/$id"
        return
      fi
    done
  done
}

# Sensor de uso de GPU para o gráfico de CPU ("" se não houver).
# Em híbridos (NVIDIA + integrada) usa só a integrada: ler a NVIDIA faz o
# ksystemstats rodar "nvidia-smi dmon", que acorda a dGPU a cada 2s e impede
# o RTD3. O ksystemstats chama cada GPU pelo número do card DRM (card1 →
# gpu1), não pela ordem; o vendor PCI do mesmo card diz se é NVIDIA (0x10de).
# Por garantia, também pula a gpuN cujo nome (gpu/gpuN/name, que só a NVIDIA
# preenche) cite NVIDIA; ler o nome não acorda a GPU.
gpu_sensor() {
  local d n vendor nvidia=0 other=0
  local -A vendors=()   # número do card → vendor PCI
  for d in /sys/class/drm/card[0-9]*; do
    n="${d##*/card}"
    [[ "$n" =~ ^[0-9]+$ ]] || continue   # pula conectores (card1-eDP-1 etc.)
    vendor="$(cat "$d/device/vendor" 2>/dev/null)"
    [[ -n "$vendor" ]] || continue
    vendors[$n]="$vendor"
    if [[ "$vendor" == 0x10de ]]; then nvidia=1; else other=1; fi
  done

  if ! command -v kstatsviewer >/dev/null; then
    # Sem como escolher a GPU: em híbrido, nada de GPU; senão, o agregado
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

# Sensor de temperatura da GPU ("" se não houver), a partir da GPU escolhida
# em gpu_sensor (em híbridos, só a integrada; ler a NVIDIA acordaria a dGPU).
# Só vale se ler um valor > 0: a Intel integrada, por exemplo, expõe o sensor
# mas sempre devolve 0 (a temperatura dela é a da própria CPU)
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

apply_layout() {
  info "Recriando painéis e widgets"

  # Preset do Panel Colorizer vem do próprio plasmoid instalado
  local preset="$HOME/.local/share/plasma/plasmoids/luisbocanegra.panel.colorizer/contents/ui/presets/$PANEL_COLORIZER_PRESET/settings.json"
  local colorizer="null"
  [[ -f "$preset" ]] && colorizer="$(python3 -c 'import json,sys; print(json.dumps(json.load(open(sys.argv[1]))["globalSettings"]))' "$preset")"

  local js
  js=$(cat <<'JS'
var WALLPAPER = "@WALLPAPER@";
var LAUNCHERS = "@LAUNCHERS@";
var COLORIZER = @COLORIZER@;
var BATTERY = "@BATTERY@";   // ex.: "power/battery_BAT1" ("" se não houver bateria)
var GPU = "@GPU@";        // ex.: "gpu/all/usage", "gpu/gpu1/usage" (só a integrada em híbridos) ou ""
var GPU_TEMP = "@GPU_TEMP@";   // ex.: "gpu/gpu0/temperature" ("" se a GPU não informar temperatura)

function cfg(w, group, values) {
  w.currentConfigGroup = group;
  for (var k in values) w.writeConfig(k, values[k]);
}

// Limpa o layout atual. Os painéis antigos só são removidos depois de criar
// os novos: criar uma bandeja depois que o processo removeu outra derruba o
// plasmashell (Plasma 6.6), que volta sem a bandeja nova. Por isso o shell
// também é reiniciado antes deste script (step_layout)
var oldPanels = panels();
desktops().forEach(function (d) {
  d.widgets().forEach(function (w) { w.remove(); });
  if (WALLPAPER) {
    d.wallpaperPlugin = "org.kde.image";
    cfg(d, ["Wallpaper", "org.kde.image", "General"], { Image: "file://" + WALLPAPER });
  }
});

// Tudo vai para a tela principal (no Plasma, a tela 0). Sem isso, o painel
// novo nasce na tela ativa do KWin (a do mouse/janela em foco)
var PRIMARY = 0;

// ── Painel superior: bandeja, relógio, pager ──
var top = new Panel;
top.screen = PRIMARY;
top.location = "top";
top.height = 34;
top.floating = true;
top.lengthMode = "fit";
top.hiding = "autohide";
top.addWidget("org.kde.plasma.marginsseparator");
top.addWidget("org.kde.plasma.pager");
var tray = top.addWidget("org.kde.plasma.systemtray");   // itens: ver write_tray
cfg(top.addWidget("org.kde.plasma.digitalclock"), ["Appearance"], { fontWeight: 400 });
top.addWidget("org.kde.plasma.showdesktop");

// ── Painel lateral esquerdo: menu, tarefas, Panel Colorizer ──
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

// ── Widgets da área de trabalho (tela principal) ──
var desk = desktopsForActivity(currentActivity()).filter(function (d) { return d.screen === PRIMARY; })[0] || desktops()[0];
var g = screenGeometry(desk.screen);
var W = g.width, H = g.height;
// A área de trabalho encaixa tamanhos numa grade de 16px: calcula já nela.
// Os três gráficos inferiores têm a mesma largura; a sobra (< 48px) é
// dividida nas bordas, mantendo o grupo centralizado
var FW = Math.floor(W / 16) * 16, third = Math.floor(FW / 3 / 16) * 16;
var marginX = Math.floor((FW - 3 * third) / 2 / 16) * 16;

// Posições gravadas depois em ItemGeometries (o addWidget sozinho não fixa)
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

// Faixa de informações do sistema (topo); bateria só se a máquina tiver.
// A face "textonly" divide a linha em colunas iguais, todas da largura do
// maior item; se não couberem, quebra em outra linha, e o rótulo some quando
// o valor ocupa a coluna toda. O kernel é o valor mais longo: usa só a versão
// (sem o "Linux "); swap e uptime ficam de fora para sobrar espaço para os rótulos
var infoSensors = ["cpu/all/averageTemperature", "os/kernel/version", "os/plasma/plasmaVersion",
  "disk/all/usedPercent", "memory/physical/used"];
var infoLabels = { "cpu/all/averageTemperature": "CPU Temperature", "disk/all/usedPercent": "Disk Usage",
  "memory/physical/used": "Used Memory", "os/kernel/version": "Kernel", "os/plasma/plasmaVersion": "KDE Plasma" };
// Temperatura da GPU, se ela informar (ver gpu_temp_sensor)
if (GPU_TEMP) {
  infoSensors.splice(1, 0, GPU_TEMP);
  infoLabels[GPU_TEMP] = "GPU Temperature";
}
if (BATTERY) {
  infoSensors.push(BATTERY + "/chargeRate", BATTERY + "/chargePercentage");
  infoLabels[BATTERY + "/chargeRate"] = "Charging Rate";
  infoLabels[BATTERY + "/chargePercentage"] = "Charge Percentage";
}
// Cores na ordem dos itens, repetindo o ciclo: #00aaff #ff5500 #55ff7f #ffff00
var INFO_PALETTE = ["0,170,255", "255,85,0", "85,255,127", "255,255,0"], infoColors = {};
infoSensors.forEach(function (id, i) { infoColors[id] = INFO_PALETTE[i % INFO_PALETTE.length]; });
monitor(0, 0, FW, 64, "org.kde.ksysguard.textonly", infoSensors, infoColors, infoLabels);

// Relógio grande: dia e data sem nome localizado, hora em 24h
cfg(place("com.github.vKaras1337.modernclock", 0, 64, FW, 160), ["Appearance"],
  { use_local_day_name: false, use_local_date_name: false, use_24_hour_format: true });

// Gráficos na base: CPU/GPU | Rede | Disco
// Altura mínima em que os três cabem iguais: 112px medidos com gridUnit 18
// (o de CPU/GPU não desce disso pela legenda). Escala pela fonte da máquina
// e arredonda para a grade de 16px da área de trabalho
var BOTTOM_H = Math.ceil(112 * gridUnit / 18 / 16) * 16, y = H - BOTTOM_H - 8;
// CPU + uso de GPU (todas, ou só a integrada em híbridos; ver gpu_sensor)
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

print("DESK " + desk.id + " " + W + "x" + H + " " + placed.join("") + "\n");
print("TRAYID " + top.id + " " + tray.id + "\n");
JS
)
  js="${js//@WALLPAPER@/$WALLPAPER}"
  js="${js//@LAUNCHERS@/$TASK_LAUNCHERS}"
  js="${js//@COLORIZER@/$colorizer}"
  js="${js//@BATTERY@/$(battery_sensor)}"
  local gpu; gpu="$(gpu_sensor)"
  js="${js//@GPU@/$gpu}"
  js="${js//@GPU_TEMP@/$(gpu_temp_sensor "$gpu")}"
  local out
  out="$(plasma_js "$js")" || die "Falha ao aplicar o layout do Plasma"
  read -r _ DESK_ID DESK_RES DESK_GEOM < <(grep '^DESK ' <<<"$out")
  [[ -n "${DESK_GEOM:-}" ]] || die "O Plasma não devolveu as posições dos widgets: $out"
  read -r _ TRAY_PANEL_ID TRAY_ID < <(grep '^TRAYID ' <<<"$out")
  ok "Painéis e widgets criados"
}

# Grava os itens da bandeja com o plasmashell parado (Plasma recente, em que
# a bandeja é o próprio containment). Configurar ao vivo uma bandeja recém-
# criada faz o shell iniciar todos os itens de uma vez, o que derruba o
# plasmashell 6.6 (crash dentro do QML dos applets) antes de ele salvar a
# bandeja nova; na inicialização normal os mesmos itens carregam sem problema
write_tray() {
  [[ -n "${TRAY_ID:-}" ]] || return 0
  local key
  for key in extraItems knownItems; do
    kwriteconfig6 --file plasma-org.kde.plasma.desktop-appletsrc --group Containments --group "$TRAY_PANEL_ID" \
      --group Applets --group "$TRAY_ID" --group General --key "$key" "$TRAY_ITEMS"
  done
}

# Define os itens da bandeja ao vivo. Roda após cada reinício do plasmashell:
# em Plasma antigo a bandeja só ganha containment (SystrayContainmentId) depois
# de iniciada, e ele precisa receber os itens; no recente, write_tray já gravou
# os mesmos itens e isto só confere
configure_tray() {
  # Onde ficam os itens depende da versão do Plasma:
  #   - antigas: a bandeja cria um containment próprio (SystrayContainmentId)
  #     de forma assíncrona; espera ele existir (até ~30s, VMs lentas)
  #   - recentes (ex.: 6.7): a própria bandeja é o containment e não tem
  #     SystrayContainmentId; os itens vão no [General] dela
  # Os itens entram como string JS, com \ e " escapados
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
    if (!tray) return;   // Plasma antigo: containment ainda não criado
    tray.currentConfigGroup = ["General"];
    // Já gravado por write_tray: regravar ao vivo faz a bandeja reiniciar os
    // itens enquanto ainda os carrega, o que derruba o plasmashell 6.6
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
  ((tray_ok)) || warn "Não consegui configurar os itens da bandeja (${tray_out:-sem resposta})"
}

# O plasmashell pode estar fora do serviço do systemd (ex.: reiniciado após
# um crash); aí o "systemctl stop" não falha, mas também não o encerra
stop_plasmashell() {
  systemctl --user stop plasma-plasmashell.service 2>/dev/null || true
  pgrep -x plasmashell >/dev/null && { kquitapp6 plasmashell >/dev/null 2>&1 || true; }
  local _
  for _ in {1..30}; do pgrep -x plasmashell >/dev/null || return 0; sleep 0.5; done
  die "plasmashell não encerrou"
}

start_plasmashell() {
  systemctl --user start plasma-plasmashell.service 2>/dev/null || (kstart plasmashell >/dev/null 2>&1 &)
  local _
  for _ in {1..60}; do
    plasma_js 'print("ok")' 2>/dev/null | grep ok >/dev/null && { sleep 3; return 0; }
    sleep 0.5
  done
  die "plasmashell não iniciou"
}

# Grava as posições dos widgets com o plasmashell parado (senão ele sobrescreve)
write_geometry() {
  local key
  for key in "ItemGeometries-$DESK_RES" ItemGeometriesHorizontal; do
    kwriteconfig6 --file plasma-org.kde.plasma.desktop-appletsrc \
      --group Containments --group "$DESK_ID" --key "$key" "$DESK_GEOM"
  done
}

# Confere painéis, widgets e posições; imprime o que estiver errado
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
  grep -q '^PANEL top .*org.kde.plasma.systemtray' <<<"$out" || errors+=("painel superior ausente ou sem bandeja")
  grep '^PANEL ' <<<"$out" | grep -vq '^PANEL [a-z]* screen0 ' && errors+=("painel fora da tela principal: $(grep '^PANEL ' <<<"$out" | grep -v '^PANEL [a-z]* screen0 ' | cut -d' ' -f2-3 | tr '\n' ' ')")
  # Sem itens configurados, a bandeja pode ficar vazia e, com o painel em "fit", invisível
  grep -q '^TRAYC top ok' <<<"$out" || errors+=("bandeja do painel superior sem itens configurados")
  grep -q '^PANEL left .*org.kde.plasma.icontasks' <<<"$out" || errors+=("painel lateral ausente ou sem tarefas")
  local deskw; deskw="$(grep '^DESKW ' <<<"$out" || true)"
  [[ "$(grep -o 'org.kde.plasma.systemmonitor' <<<"$deskw" | wc -l)" -eq 4 ]] || errors+=("esperava 4 monitores do sistema na área de trabalho")
  grep -q 'com.github.vKaras1337.modernclock' <<<"$deskw" || errors+=("relógio da área de trabalho ausente")

  saved="$(kreadconfig6 --file plasma-org.kde.plasma.desktop-appletsrc --group Containments --group "$DESK_ID" --key "ItemGeometries-$DESK_RES")"
  local bad
  # O Plasma encaixa os widgets numa grade de 16px, pode aumentar a altura até
  # o mínimo do widget e reescalar posições em outra resolução; por isso confere
  # a estrutura, com folga de 2 células (32px), e não a coordenada exata:
  #   topo: os de largura toda começam à esquerda e cobrem a tela; os demais
  #         ficam perto de x/largura esperados; todos perto do y
  #   base: da esquerda p/ direita sem sobreposição, cobrindo a largura,
  #         com a mesma largura (altura/base: só aviso)
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
        print(f"{k}: não encontrado"); continue
    gx, gy, gw, gh = g
    if y < H / 2:
        if w >= W - TOL and (gx > TOL or gw < W - TOL):
            print(f"{k}: deveria ocupar a largura toda, atual x={gx:g} w={gw:g} (tela {W:g})")
        if w < W - TOL and (abs(gx - x) > TOL or abs(gw - w) > TOL):
            print(f"{k}: esperado x≈{x:g} w≈{w:g}, atual x={gx:g} w={gw:g}")
        if abs(gy - y) > 48:
            print(f"{k}: deveria estar no topo (y≈{y:g}), atual y={gy:g}")
    else:
        bottom.append((gx, gw, gy, gh, k))
        if abs(gx - x) > TOL or abs(gw - w) > TOL:
            print(f"{k}: esperado x≈{x:g} w≈{w:g}, atual x={gx:g} w={gw:g}")
        if abs((gy + gh) - (y + h)) > 16:
            print(f"AVISO {k}: não encosta na base ({y + h:g}), atual {gy + gh:g}")
bottom.sort()
for a, b in zip(bottom, bottom[1:]):
    if a[0] + a[1] > b[0] + 2:
        print(f"{a[4]} e {b[4]} estão sobrepostos")
if bottom:
    if bottom[0][0] > TOL or bottom[-1][0] + bottom[-1][1] < W - TOL:
        print(f"monitores inferiores não cobrem a largura (de {bottom[0][0]:g} a {bottom[-1][0] + bottom[-1][1]:g}, tela {W:g})")
    hs = [b[3] for b in bottom]
    if max(hs) - min(hs) > 2:
        print(f"AVISO monitores inferiores com alturas diferentes: {hs}")
    ws = [b[1] for b in bottom]
    if max(ws) - min(ws) > 2:
        print(f"monitores inferiores com larguras diferentes: {ws}")
PY2
)"
  # Altura é só aviso: o Plasma impõe o mínimo de cada widget
  local line
  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    if [[ "$line" == AVISO* ]]; then warn "${line#AVISO }"; else errors+=("posição errada — $line"); fi
  done <<<"$bad"

  ((${#errors[@]} == 0)) && return 0
  local e; for e in "${errors[@]}"; do warn "$e"; done
  return 1
}

step_layout() {
  bold "━━ 3/3 — Aplicando layout"
  backup_configs
  apply_theme
  apply_icon_overrides
  apply_kwin
  # Shell recém-iniciado: se ele já tiver removido uma bandeja (ex.: o usuário
  # apagou um painel), criar outra o derruba (Plasma 6.6); ver apply_layout
  info "Reiniciando o plasmashell antes de recriar os painéis"
  stop_plasmashell
  start_plasmashell
  apply_layout

  local attempt
  for attempt in 1 2 3; do
    info "Fixando posições dos widgets e reiniciando o plasmashell (tentativa $attempt/3)"
    stop_plasmashell
    write_geometry
    write_tray
    start_plasmashell
    configure_tray
    if verify_layout; then
      ok "Layout verificado: painéis, widgets e posições corretos"
      echo
      ok "Pronto! Faça logout/login para que fontes e cores entrem em vigor em todos os apps."
      return
    fi
  done
  die "O layout não ficou como esperado após 3 tentativas (backup das configs acima)."
}

# =================================================================== MAIN ====

pgrep -x plasmashell >/dev/null || die "Rode dentro de uma sessão Plasma em execução."

step_font
step_assets
step_layout
