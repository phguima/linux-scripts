#!/usr/bin/env bash
# plasma-setup.sh — aplica o layout do KDE Plasma definido neste arquivo.
#
# Fluxo:
#   1) instala a fonte, se faltar (via gerenciador de pacotes, pede sudo)
#   2) abre a janela "Obter novos..." do KDE para instalar os assets da
#      KDE Store manualmente e espera a confirmação, verificando a instalação
#   3) aplica tema, KWin (KZones) e recria painéis/widgets
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

# Aplicado só se existir na pasta de imagens do usuário (~/Pictures)
PICTURES_DIR="$(xdg-user-dir PICTURES 2>/dev/null || echo "$HOME/Pictures")"
WALLPAPER="$PICTURES_DIR/wallpapers/wallpaper_16.jpeg"

VIRTUAL_DESKTOPS=4
VIRTUAL_DESKTOP_ROWS=2

TASK_LAUNCHERS="applications:systemsettings.desktop,applications:brave-origin.desktop,applications:brave-browser.desktop,applications:org.kde.konsole.desktop,preferred://filemanager,applications:com.microsoft.VSCode.desktop,applications:com.spotify.Client.desktop,applications:org.kde.discover.desktop"

TRAY_ITEMS="org.kde.kdeconnect,org.kde.plasma.vault,org.kde.kscreen,org.kde.plasma.battery,org.kde.plasma.bluetooth,org.kde.plasma.brightness,org.kde.plasma.cameraindicator,org.kde.plasma.clipboard,org.kde.plasma.devicenotifier,org.kde.plasma.keyboardindicator,org.kde.plasma.keyboardlayout,org.kde.plasma.manage-inputmethod,org.kde.plasma.mediacontroller,org.kde.plasma.networkmanagement,org.kde.plasma.notifications,org.kde.plasma.printmanager,org.kde.plasma.volume,org.kde.plasma.weather"

PANEL_COLORIZER_PRESET="Transparent"

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
        "name": "Triple Grid Rigth",
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
  local dir
  dir="$HOME/.config/plasma-setup-backup-$(date +%Y%m%d-%H%M%S)"
  mkdir -p "$dir"
  local f
  for f in plasma-org.kde.plasma.desktop-appletsrc plasmashellrc kdeglobals kwinrc kscreenlockerrc; do
    [[ -f "$HOME/.config/$f" ]] && cp -a "$HOME/.config/$f" "$dir/"
  done
  ok "Backup das configs atuais em $dir"
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

  if [[ -f "$WALLPAPER" ]]; then
    info "Wallpaper: $WALLPAPER"
    kwriteconfig6 --file kscreenlockerrc --group Greeter --group Wallpaper --group org.kde.image --group General --key Image "file://$WALLPAPER"
    kwriteconfig6 --file kscreenlockerrc --group Greeter --group Wallpaper --group org.kde.image --group General --key PreviewImage "file://$WALLPAPER"
  else
    warn "Wallpaper não encontrado em $WALLPAPER — pulando (papel de parede atual mantido)"
    WALLPAPER=""
  fi
  ok "Tema aplicado"
}

apply_kwin() {
  info "KWin: $VIRTUAL_DESKTOPS áreas de trabalho em $VIRTUAL_DESKTOP_ROWS linhas + KZones"
  kwriteconfig6 --file kwinrc --group Desktops --key Number "$VIRTUAL_DESKTOPS"
  kwriteconfig6 --file kwinrc --group Desktops --key Rows "$VIRTUAL_DESKTOP_ROWS"
  kwriteconfig6 --file kwinrc --group Plugins --key kzonesEnabled true
  kwriteconfig6 --file kwinrc --group Script-kzones --key layoutsJson "$KZONES_LAYOUTS"
  qdbus org.kde.KWin /KWin reconfigure >/dev/null 2>&1 || true
  ok "KWin configurado"
}

# Sensor da bateria do sistema (BAT0, BAT1...), ignorando periféricos (mouse etc.)
battery_sensor() {
  local d
  for d in /sys/class/power_supply/*; do
    [[ "$(cat "$d/type" 2>/dev/null)" == Battery && "$(cat "$d/scope" 2>/dev/null)" != Device ]] || continue
    echo "power/battery_$(basename "$d")"
    return
  done
}

# Há sensor agregado de GPU? (sem kstatsviewer, assume que sim)
has_gpu_sensor() {
  command -v kstatsviewer >/dev/null || return 0
  kstatsviewer --list 2>/dev/null | grep '^gpu/all/usage ' >/dev/null
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
var HAS_GPU = @HAS_GPU@;

function cfg(w, group, values) {
  w.currentConfigGroup = group;
  for (var k in values) w.writeConfig(k, values[k]);
}

// Limpa o layout atual
panels().forEach(function (p) { p.remove(); });
desktops().forEach(function (d) {
  d.widgets().forEach(function (w) { w.remove(); });
  if (WALLPAPER) {
    d.wallpaperPlugin = "org.kde.image";
    cfg(d, ["Wallpaper", "org.kde.image", "General"], { Image: "file://" + WALLPAPER });
  }
});

// ── Painel superior: bandeja, relógio, pager ──
var top = new Panel;
top.location = "top";
top.height = 34;
top.floating = true;
top.lengthMode = "fit";
top.hiding = "autohide";
top.addWidget("org.kde.plasma.marginsseparator");
top.addWidget("org.kde.plasma.pager");
top.addWidget("org.kde.plasma.systemtray");
cfg(top.addWidget("org.kde.plasma.digitalclock"), ["Appearance"], { fontWeight: 400 });
top.addWidget("org.kde.plasma.showdesktop");

// ── Painel lateral esquerdo: menu, tarefas, Panel Colorizer ──
var left = new Panel;
left.location = "left";
left.height = 52;
left.floating = true;
left.lengthMode = "fit";
left.hiding = "autohide";
left.addWidget("org.kde.plasma.kickerdash");
cfg(left.addWidget("org.kde.plasma.icontasks"), ["General"], { launchers: LAUNCHERS });
var colorizer = left.addWidget("luisbocanegra.panel.colorizer");
var colorizerCfg = { hideWidget: true, configurationOverrides: '{"overrides":{},"associations":[]}' };
if (COLORIZER) colorizerCfg.globalSettings = JSON.stringify(COLORIZER);
cfg(colorizer, ["General"], colorizerCfg);

// ── Widgets da área de trabalho (tela principal) ──
var desk = desktopsForActivity(currentActivity()).filter(function (d) { return d.screen === 0; })[0] || desktops()[0];
var g = screenGeometry(desk.screen);
var W = g.width, H = g.height;
// A área de trabalho encaixa tamanhos numa grade de 16px: calcula já nela.
// Os três gráficos inferiores têm a mesma largura; a sobra (< 48px) é
// dividida nas bordas, mantendo o grupo centralizado
var FW = Math.floor(W / 16) * 16, third = Math.floor(FW / 3 / 16) * 16;
var left = Math.floor((FW - 3 * third) / 2 / 16) * 16;

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

// Faixa de informações do sistema (topo); bateria só se a máquina tiver
var infoSensors = ["os/system/uptime", "cpu/all/averageTemperature", "os/kernel/prettyName", "os/plasma/plasmaVersion",
  "disk/all/usedPercent", "memory/physical/used", "memory/swap/used"];
var infoColors = { "cpu/all/averageTemperature": "255,85,0", "disk/all/usedPercent": "85,255,255",
  "memory/physical/used": "255,170,255", "memory/swap/used": "0,170,255",
  "os/kernel/prettyName": "85,255,127", "os/plasma/plasmaVersion": "255,255,127",
  "os/system/uptime": "0,170,255" };
var infoLabels = { "cpu/all/averageTemperature": "CPU Temperature", "disk/all/usedPercent": "Disk Usage",
  "memory/physical/used": "Used Memory", "memory/swap/used": "Used Swap",
  "os/plasma/plasmaVersion": "KDE Plasma" };
if (BATTERY) {
  infoSensors.push(BATTERY + "/chargeRate", BATTERY + "/chargePercentage");
  infoColors[BATTERY + "/chargeRate"] = "255,85,0";
  infoColors[BATTERY + "/chargePercentage"] = "85,255,127";
  infoLabels[BATTERY + "/chargeRate"] = "Charging Rate";
  infoLabels[BATTERY + "/chargePercentage"] = "Charge Percentage";
}
monitor(0, 0, FW, 64, "org.kde.ksysguard.textonly", infoSensors, infoColors, infoLabels);

// Relógio grande
place("com.github.vKaras1337.modernclock", 0, 64, FW, 160);

// Gráficos na base: CPU/GPU | Rede | Disco
// Altura mínima em que os três cabem iguais: 112px medidos com gridUnit 18
// (o de CPU/GPU não desce disso pela legenda). Escala pela fonte da máquina
// e arredonda para a grade de 16px da área de trabalho
var BOTTOM_H = Math.ceil(112 * gridUnit / 18 / 16) * 16, y = H - BOTTOM_H - 8;
// CPU + uso agregado de todas as GPUs (só se a máquina tiver sensor de GPU)
monitor(left, y, third, BOTTOM_H, "org.kde.ksysguard.linechart",
  HAS_GPU ? ["cpu/all/usage", "gpu/all/usage"] : ["cpu/all/usage"],
  { "cpu/all/usage": "0,170,255", "gpu/all/usage": "255,85,0" },
  { "cpu/all/usage": "CPU", "gpu/all/usage": "GPUs" });
monitor(left + third, y, third, BOTTOM_H, "org.kde.ksysguard.linechart",
  ["network/all/download", "network/all/upload"],
  { "network/all/download": "0,170,255", "network/all/upload": "255,85,0" },
  { "network/all/download": "Download", "network/all/upload": "Upload" });
monitor(left + 2 * third, y, third, BOTTOM_H, "org.kde.ksysguard.linechart",
  ["disk/all/write", "disk/all/read"],
  { "disk/all/read": "255,85,0", "disk/all/write": "0,170,255" },
  { "disk/all/read": "Read", "disk/all/write": "Write" });

print("DESK " + desk.id + " " + W + "x" + H + " " + placed.join("") + "\n");
JS
)
  js="${js//@WALLPAPER@/$WALLPAPER}"
  js="${js//@LAUNCHERS@/$TASK_LAUNCHERS}"
  js="${js//@COLORIZER@/$colorizer}"
  js="${js//@BATTERY@/$(battery_sensor)}"
  js="${js//@HAS_GPU@/$(has_gpu_sensor && echo true || echo false)}"
  local out
  out="$(plasma_js "$js")" || die "Falha ao aplicar o layout do Plasma"
  read -r _ DESK_ID DESK_RES DESK_GEOM < <(grep '^DESK ' <<<"$out")
  [[ -n "${DESK_GEOM:-}" ]] || die "O Plasma não devolveu as posições dos widgets: $out"

  # A bandeja cria o próprio containment de forma assíncrona: configura depois
  sleep 2
  plasma_js "$(cat <<JS
panels().forEach(function (p) {
  p.widgets("org.kde.plasma.systemtray").forEach(function (t) {
    var tray = desktopById(t.readConfig("SystrayContainmentId"));
    if (!tray) return;
    tray.currentConfigGroup = ["General"];
    tray.writeConfig("extraItems", "$TRAY_ITEMS");
    tray.writeConfig("knownItems", "$TRAY_ITEMS");
  });
});
JS
)" >/dev/null || warn "Não consegui configurar os itens da bandeja"
  ok "Painéis e widgets criados"
}

stop_plasmashell() {
  systemctl --user stop plasma-plasmashell.service 2>/dev/null || kquitapp6 plasmashell >/dev/null 2>&1 || true
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
    panels().forEach(function (p) { print("PANEL " + p.location + " " + p.widgets().map(function (w) { return w.type; }).join(",") + "\n"); });
    var d = desktopById('"$DESK_ID"');
    if (d) print("DESKW " + d.widgets().map(function (w) { return w.type; }).join(",") + "\n");
  ')"
  grep -q '^PANEL top .*org.kde.plasma.systemtray' <<<"$out" || errors+=("painel superior ausente ou sem bandeja")
  grep -q '^PANEL left .*org.kde.plasma.icontasks' <<<"$out" || errors+=("painel lateral ausente ou sem tarefas")
  local deskw; deskw="$(grep '^DESKW ' <<<"$out" || true)"
  [[ "$(grep -o 'org.kde.plasma.systemmonitor' <<<"$deskw" | wc -l)" -eq 4 ]] || errors+=("esperava 4 monitores do sistema na área de trabalho")
  grep -q 'com.github.vKaras1337.modernclock' <<<"$deskw" || errors+=("relógio da área de trabalho ausente")

  saved="$(kreadconfig6 --file plasma-org.kde.plasma.desktop-appletsrc --group Containments --group "$DESK_ID" --key "ItemGeometries-$DESK_RES")"
  local bad
  # O Plasma encaixa os widgets numa grade de 16px, pode aumentar a altura até
  # o mínimo do widget e reescalar posições em outra resolução; por isso confere
  # a estrutura, com folga de 2 células (32px), e não a coordenada exata:
  #   topo: começa à esquerda, largura toda, perto do y esperado
  #   base: da esquerda p/ direita sem sobreposição, cobrindo a largura,
  #         encostados no rodapé, com a mesma altura e a mesma largura
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
        if gx > TOL or gw < W - TOL:
            print(f"{k}: deveria ocupar a largura toda, atual x={gx:g} w={gw:g} (tela {W:g})")
        if abs(gy - y) > 48:
            print(f"{k}: deveria estar no topo (y≈{y:g}), atual y={gy:g}")
    else:
        bottom.append((gx, gw, gy, gh, k))
        if abs(gx - x) > TOL or abs(gw - w) > TOL:
            print(f"{k}: esperado x≈{x:g} w≈{w:g}, atual x={gx:g} w={gw:g}")
        if abs((gy + gh) - (y + h)) > 16:
            print(f"{k}: deveria encostar na base ({y + h:g}), atual {gy + gh:g}")
bottom.sort()
for a, b in zip(bottom, bottom[1:]):
    if a[0] + a[1] > b[0] + 2:
        print(f"{a[4]} e {b[4]} estão sobrepostos")
if bottom:
    if bottom[0][0] > TOL or bottom[-1][0] + bottom[-1][1] < W - TOL:
        print(f"monitores inferiores não cobrem a largura (de {bottom[0][0]:g} a {bottom[-1][0] + bottom[-1][1]:g}, tela {W:g})")
    hs = [b[3] for b in bottom]
    if max(hs) - min(hs) > 2:
        print(f"monitores inferiores com alturas diferentes: {hs}")
    ws = [b[1] for b in bottom]
    if max(ws) - min(ws) > 2:
        print(f"monitores inferiores com larguras diferentes: {ws}")
PY2
)"
  [[ -z "$bad" ]] || errors+=("posição errada — $bad")

  ((${#errors[@]} == 0)) && return 0
  local e; for e in "${errors[@]}"; do warn "$e"; done
  return 1
}

step_layout() {
  bold "━━ 3/3 — Aplicando layout"
  backup_configs
  apply_theme
  apply_kwin
  apply_layout

  local attempt
  for attempt in 1 2 3; do
    info "Fixando posições dos widgets e reiniciando o plasmashell (tentativa $attempt/3)"
    stop_plasmashell
    write_geometry
    start_plasmashell
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
