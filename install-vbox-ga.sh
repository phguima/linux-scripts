#!/usr/bin/env bash
# install-vbox-ga.sh — instala VirtualBox Guest Additions (dnf/yum/apt) na versão do host
# Roda DENTRO da VM (guest). Aborta se não detectar VirtualBox.
# Uso:
#   sudo ./install-vbox-ga.sh              # detecta a versão do host e instala/atualiza
#   sudo ./install-vbox-ga.sh --force      # reinstala mesmo se a versão já bater
#   sudo ./install-vbox-ga.sh --pkg        # usa os pacotes da distro
#   sudo VBOX_VERSION=7.1.4 ./install-vbox-ga.sh   # força uma versão
set -euo pipefail

[[ $EUID -eq 0 ]] || { echo "Rode como root (sudo)."; exit 1; }

MODE="iso"; FORCE=0
for a in "$@"; do
  case $a in
    --pkg)   MODE="pkg" ;;
    --force) FORCE=1 ;;
    *) echo "Opção desconhecida: $a"; exit 1 ;;
  esac
done

KVER="$(uname -r)"
MNT="/mnt/vbox-ga"
TARGET_USER="${SUDO_USER:-}"

log()  { printf '\e[1;34m==>\e[0m %s\n' "$*"; }
warn() { printf '\e[1;33mAVISO:\e[0m %s\n' "$*" >&2; }
die()  { printf '\e[1;31mERRO:\e[0m %s\n' "$*" >&2; exit 1; }

# --- trava de segurança: só roda dentro de VM VirtualBox ---
VIRT="$(systemd-detect-virt 2>/dev/null || true)"
[[ $VIRT == oracle ]] \
  || die "Isto não é uma VM VirtualBox (detectado: ${VIRT:-desconhecido}). Abortando."

# --- versões ---
host_version() {
  local v=""
  # 1) SMBIOS OEM strings (tipo 11) — não depende de nada instalado
  for f in /sys/firmware/dmi/entries/11-*/raw; do
    [[ -r $f ]] || continue
    v="$(grep -aoP 'vboxVer_\K[0-9]+\.[0-9]+\.[0-9]+' "$f" | head -1 || true)"
    [[ -n $v ]] && break
  done
  # 2) dmidecode, se existir
  if [[ -z $v ]] && command -v dmidecode >/dev/null; then
    v="$(dmidecode -t 11 2>/dev/null | grep -oP 'vboxVer_\K[0-9]+\.[0-9]+\.[0-9]+' | head -1 || true)"
  fi
  # 3) guest property (exige GA já instalado)
  if [[ -z $v ]] && command -v VBoxControl >/dev/null; then
    v="$(VBoxControl --nologo guestproperty get /VirtualBox/HostInfo/VBoxVer 2>/dev/null | grep -oP 'Value: \K[0-9.]+' || true)"
  fi
  echo "$v"
}

installed_version() {
  if command -v VBoxControl >/dev/null; then
    VBoxControl --nologo --version 2>/dev/null | grep -oP '^[0-9]+\.[0-9]+\.[0-9]+' && return
  fi
  local d
  for d in /opt/VBoxGuestAdditions-*; do
    [[ -d $d ]] && echo "${d##*-}"
  done | sort -V | tail -1
}

iso_version() {  # rótulo do ISO: VBox_GAs_7.1.4
  blkid -o value -s LABEL "$1" 2>/dev/null | grep -oP 'VBox_GAs_\K[0-9.]+'
}

HOST_VER="$(host_version)"
INST_VER="$(installed_version || true)"
log "Host VirtualBox: ${HOST_VER:-desconhecida} | GA instalado: ${INST_VER:-nenhum} | kernel: $KVER"

if [[ -n $HOST_VER && $HOST_VER == "$INST_VER" && $FORCE -eq 0 ]]; then
  log "Guest Additions já está na versão do host. Nada a fazer (use --force para reinstalar)."
  exit 0
fi

# --- gerenciador de pacotes ---
if   command -v dnf     >/dev/null; then PM=dnf
elif command -v yum     >/dev/null; then PM=yum
elif command -v apt-get >/dev/null; then PM=apt; export DEBIAN_FRONTEND=noninteractive
else die "Precisa de dnf, yum ou apt-get."
fi
pm_install() { if [[ $PM == apt ]]; then apt-get install -y "$@"; else $PM install -y "$@"; fi; }
[[ $PM == apt ]] && apt-get update

# --- modo pacote da distro ---
if [[ $MODE == pkg ]]; then
  if [[ $PM == apt ]]; then
    pm_install virtualbox-guest-utils virtualbox-guest-x11 \
      || die "Pacote não encontrado. Habilite multiverse/contrib ou use o modo ISO."
  else
    pm_install virtualbox-guest-additions
  fi
  NEW_VER="$(installed_version || true)"
  if [[ -n $HOST_VER && -n $NEW_VER && $NEW_VER != "$HOST_VER" ]]; then
    warn "Pacote da distro ($NEW_VER) difere do host ($HOST_VER). Normalmente funciona; se der problema, use o modo ISO."
  fi
  if [[ -n $TARGET_USER ]]; then usermod -aG vboxsf "$TARGET_USER" || true; fi
  log "Pronto. Reinicie a VM."; exit 0
fi

# --- dependências de compilação ---
log "Instalando dependências de compilação..."
if [[ $PM == apt ]]; then
  pm_install build-essential dkms perl bzip2 tar curl "linux-headers-$KVER" \
    || die "Sem linux-headers-$KVER. Rode 'apt-get upgrade', reinicie e tente de novo."
else
  pm_install gcc make perl bzip2 tar curl elfutils-libelf-devel "kernel-devel-$KVER" kernel-headers \
    || die "Sem kernel-devel-$KVER. Rode '$PM update', reinicie e tente de novo."
fi

# --- escolhe a versão e obtém o ISO ---
WANT_VER="${VBOX_VERSION:-$HOST_VER}"
[[ $WANT_VER == latest ]] && WANT_VER="$(curl -fsSL https://download.virtualbox.org/virtualbox/LATEST-STABLE.TXT)"

mkdir -p "$MNT"
ISO_TMP=""
cleanup() {
  if mountpoint -q "$MNT"; then umount "$MNT" || true; fi
  if [[ -n $ISO_TMP ]]; then rm -f "$ISO_TMP"; fi
}
trap cleanup EXIT

# tenta o CD inserido primeiro, se a versão bater (ou se não soubermos qual queremos)
for d in /dev/cdrom /dev/sr0 /dev/sr1; do
  [[ -b $d ]] || continue
  CD_VER="$(iso_version "$d" || true)"
  [[ -n $CD_VER ]] || continue
  if [[ -z $WANT_VER || $CD_VER == "$WANT_VER" ]]; then
    log "Usando CD inserido ($d, versão $CD_VER)."
    mount -o ro "$d" "$MNT"; WANT_VER="$CD_VER"; break
  else
    warn "CD inserido é $CD_VER, mas o host é $WANT_VER — vou baixar a versão certa."
  fi
done

if ! mountpoint -q "$MNT"; then
  [[ -n $WANT_VER ]] || die "Não consegui detectar a versão do host nem achar o CD. Defina VBOX_VERSION=x.y.z."
  ISO_TMP="$(mktemp --suffix=.iso)"
  log "Baixando Guest Additions $WANT_VER..."
  curl -fL -o "$ISO_TMP" \
    "https://download.virtualbox.org/virtualbox/${WANT_VER}/VBoxGuestAdditions_${WANT_VER}.iso" \
    || die "Download falhou para a versão $WANT_VER."
  mount -o loop,ro "$ISO_TMP" "$MNT"
fi

[[ -f $MNT/VBoxLinuxAdditions.run ]] || die "VBoxLinuxAdditions.run não encontrado no ISO."

# --- instala ---
log "Instalando Guest Additions $WANT_VER..."
set +e; sh "$MNT/VBoxLinuxAdditions.run" --nox11; rc=$?; set -e
[[ $rc -eq 0 || $rc -eq 2 ]] || die "Instalador retornou $rc. Veja /var/log/vboxadd-setup.log"

if [[ -n $TARGET_USER ]]; then
  usermod -aG vboxsf "$TARGET_USER" && log "Usuário $TARGET_USER adicionado ao grupo vboxsf."
fi
log "Concluído ($WANT_VER). Reinicie a VM: sudo reboot"
