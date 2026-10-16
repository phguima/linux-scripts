#!/usr/bin/env bash
# install-vbox-ga.sh — installs VirtualBox Guest Additions (dnf/yum/apt) matching the host version
# Runs INSIDE the VM (guest). Aborts if VirtualBox isn't detected.
# Usage:
#   sudo ./install-vbox-ga.sh              # detects the host version and installs/updates
#   sudo ./install-vbox-ga.sh --force      # reinstalls even if the version already matches
#   sudo ./install-vbox-ga.sh --pkg        # uses the distro packages
#   sudo VBOX_VERSION=7.1.4 ./install-vbox-ga.sh   # forces a version
set -euo pipefail

[[ $EUID -eq 0 ]] || { echo "Run as root (sudo)."; exit 1; }

MODE="iso"; FORCE=0
for a in "$@"; do
  case $a in
    --pkg)   MODE="pkg" ;;
    --force) FORCE=1 ;;
    *) echo "Unknown option: $a"; exit 1 ;;
  esac
done

KVER="$(uname -r)"
MNT="/mnt/vbox-ga"
TARGET_USER="${SUDO_USER:-}"

log()  { printf '\e[1;34m==>\e[0m %s\n' "$*"; }
warn() { printf '\e[1;33mWARNING:\e[0m %s\n' "$*" >&2; }
die()  { printf '\e[1;31mERROR:\e[0m %s\n' "$*" >&2; exit 1; }

# --- safety lock: only runs inside a VirtualBox VM ---
VIRT="$(systemd-detect-virt 2>/dev/null || true)"
[[ $VIRT == oracle ]] \
  || die "This is not a VirtualBox VM (detected: ${VIRT:-unknown}). Aborting."

# --- versions ---
host_version() {
  local v=""
  # 1) SMBIOS OEM strings (type 11) — doesn't depend on anything installed
  for f in /sys/firmware/dmi/entries/11-*/raw; do
    [[ -r $f ]] || continue
    v="$(grep -aoP 'vboxVer_\K[0-9]+\.[0-9]+\.[0-9]+' "$f" | head -1 || true)"
    [[ -n $v ]] && break
  done
  # 2) dmidecode, if available
  if [[ -z $v ]] && command -v dmidecode >/dev/null; then
    v="$(dmidecode -t 11 2>/dev/null | grep -oP 'vboxVer_\K[0-9]+\.[0-9]+\.[0-9]+' | head -1 || true)"
  fi
  # 3) guest property (requires GA already installed)
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

iso_version() {  # ISO label: VBox_GAs_7.1.4
  blkid -o value -s LABEL "$1" 2>/dev/null | grep -oP 'VBox_GAs_\K[0-9.]+'
}

HOST_VER="$(host_version)"
INST_VER="$(installed_version || true)"
log "Host VirtualBox: ${HOST_VER:-unknown} | installed GA: ${INST_VER:-none} | kernel: $KVER"

if [[ -n $HOST_VER && $HOST_VER == "$INST_VER" && $FORCE -eq 0 ]]; then
  log "Guest Additions already matches the host version. Nothing to do (use --force to reinstall)."
  exit 0
fi

# --- package manager ---
if   command -v dnf     >/dev/null; then PM=dnf
elif command -v yum     >/dev/null; then PM=yum
elif command -v apt-get >/dev/null; then PM=apt; export DEBIAN_FRONTEND=noninteractive
else die "Requires dnf, yum or apt-get."
fi
pm_install() { if [[ $PM == apt ]]; then apt-get install -y "$@"; else $PM install -y "$@"; fi; }
[[ $PM == apt ]] && apt-get update

# --- distro package mode ---
if [[ $MODE == pkg ]]; then
  if [[ $PM == apt ]]; then
    pm_install virtualbox-guest-utils virtualbox-guest-x11 \
      || die "Package not found. Enable multiverse/contrib or use the ISO mode."
  else
    pm_install virtualbox-guest-additions
  fi
  NEW_VER="$(installed_version || true)"
  if [[ -n $HOST_VER && -n $NEW_VER && $NEW_VER != "$HOST_VER" ]]; then
    warn "Distro package ($NEW_VER) differs from the host ($HOST_VER). It usually works; if there are problems, use the ISO mode."
  fi
  if [[ -n $TARGET_USER ]]; then usermod -aG vboxsf "$TARGET_USER" || true; fi
  log "Done. Reboot the VM."; exit 0
fi

# --- removes the distro-packaged GA (conflicts with the ISO one) ---
if [[ $PM == apt ]]; then
  DISTRO_GA="$(dpkg-query -W -f='${Package} ${Status}\n' 'virtualbox-guest-*' 2>/dev/null \
    | awk '/install ok installed/ {print $1}' || true)"
  if [[ -n $DISTRO_GA ]]; then
    log "Removing the distro Guest Additions: $(echo $DISTRO_GA)"
    apt-get purge -y $DISTRO_GA
  fi
else
  DISTRO_GA="$(rpm -qa 'virtualbox-guest-additions*' 2>/dev/null || true)"
  if [[ -n $DISTRO_GA ]]; then
    log "Removing the distro Guest Additions: $(echo $DISTRO_GA)"
    $PM remove -y $DISTRO_GA
  fi
fi

# --- build dependencies ---
log "Installing build dependencies..."
if [[ $PM == apt ]]; then
  pm_install build-essential dkms perl bzip2 tar curl "linux-headers-$KVER" \
    || die "No linux-headers-$KVER. Run 'apt-get upgrade', reboot and try again."
else
  pm_install gcc make perl bzip2 tar curl elfutils-libelf-devel "kernel-devel-$KVER" kernel-headers \
    || die "No kernel-devel-$KVER. Run '$PM update', reboot and try again."
fi

# --- picks the version and gets the ISO ---
WANT_VER="${VBOX_VERSION:-$HOST_VER}"
[[ $WANT_VER == latest ]] && WANT_VER="$(curl -fsSL https://download.virtualbox.org/virtualbox/LATEST-STABLE.TXT)"

mkdir -p "$MNT"
ISO_TMP=""
cleanup() {
  if mountpoint -q "$MNT"; then umount "$MNT" || true; fi
  if [[ -n $ISO_TMP ]]; then rm -f "$ISO_TMP"; fi
}
trap cleanup EXIT

# tries the inserted CD first, if the version matches (or if we don't know which one we want)
for d in /dev/cdrom /dev/sr0 /dev/sr1; do
  [[ -b $d ]] || continue
  CD_VER="$(iso_version "$d" || true)"
  [[ -n $CD_VER ]] || continue
  if [[ -z $WANT_VER || $CD_VER == "$WANT_VER" ]]; then
    log "Using the inserted CD ($d, version $CD_VER)."
    mount -o ro "$d" "$MNT"; WANT_VER="$CD_VER"; break
  else
    warn "Inserted CD is $CD_VER, but the host is $WANT_VER — downloading the right version."
  fi
done

if ! mountpoint -q "$MNT"; then
  [[ -n $WANT_VER ]] || die "Could not detect the host version or find the CD. Set VBOX_VERSION=x.y.z."
  ISO_TMP="$(mktemp --suffix=.iso)"
  log "Downloading Guest Additions $WANT_VER..."
  curl -fL -o "$ISO_TMP" \
    "https://download.virtualbox.org/virtualbox/${WANT_VER}/VBoxGuestAdditions_${WANT_VER}.iso" \
    || die "Download failed for version $WANT_VER."
  mount -o loop,ro "$ISO_TMP" "$MNT"
fi

[[ -f $MNT/VBoxLinuxAdditions.run ]] || die "VBoxLinuxAdditions.run not found in the ISO."

# --- install ---
log "Installing Guest Additions $WANT_VER..."
# answers "yes" to the "version already installed" prompt (leftovers from previous installs)
set +e; sh "$MNT/VBoxLinuxAdditions.run" --nox11 <<< yes; rc=$?; set -e
[[ $rc -eq 0 || $rc -eq 2 ]] || die "Installer returned $rc. See /var/log/vboxadd-setup.log"

if [[ -n $TARGET_USER ]]; then
  usermod -aG vboxsf "$TARGET_USER" && log "User $TARGET_USER added to the vboxsf group."
fi
log "Finished ($WANT_VER). Reboot the VM: sudo reboot"
