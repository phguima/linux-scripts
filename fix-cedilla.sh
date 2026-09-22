#!/usr/bin/env bash
#
# fix-cedilla
#
# Configures your personal "~/.XCompose" so that typing 'c generates a cedilla c
# (ç) instead of an accented c (ć). Follows the same approach as the afpi
# "desktop" role:
#
#   - creates ~/.XCompose from the system Compose file if it does not exist;
#   - otherwise edits it in place, keeping your own customizations;
#   - replaces both the strings (ć/Ć) and the keysyms (U0107/U0106), so apps
#     that read the keysym instead of the string (e.g. Chromium on Wayland)
#     also get ç;
#   - is idempotent: running it again changes nothing.
#
# Based on http://github.com/marcopaganini/gnome-cedilla-fix
# (C) Marco Paganini <paganini@paganini.net>

set -euo pipefail

LANG=${LANG:-en_US.UTF-8}
COMPOSE_DIR="/usr/share/X11/locale"
USER_COMPOSE="$HOME/.XCompose"
PROGNAME="${0##*/}"

if [[ -t 1 ]] && command -v tput >/dev/null; then
  BOLD=$(tput bold 2>/dev/null || true)
  RESET=$(tput sgr0 2>/dev/null || true)
else
  BOLD=""; RESET=""
fi

die() { echo >&2 "${PROGNAME} error: $*"; exit 1; }

# Strings and keysyms to replace (ć→ç, Ć→Ç, U0107→ccedilla, U0106→Ccedilla)
PENDING_RE='ć|Ć|U0107|U0106'
apply_mapping() {
  sed -i -e 's/ć/ç/g' -e 's/Ć/Ç/g' \
         -e 's/U0107/ccedilla/g' -e 's/U0106/Ccedilla/g' "$1"
}

# Find the compose file for the current language.
[[ -r ${COMPOSE_DIR}/compose.dir ]] || die "Unable to read ${COMPOSE_DIR}/compose.dir"
compose_name=$(sed -ne "s/^\([^:]*\):[ \t]*$LANG/\1/p" <"${COMPOSE_DIR}/compose.dir" | head -1)
[[ -n $compose_name ]] || die "Unable to find a system compose file for your system language (${LANG})"
system_compose="${COMPOSE_DIR}/${compose_name}"
[[ -s $system_compose ]] || die "Unable to open system Compose file: ${system_compose}"

if [[ ! -e $USER_COMPOSE ]]; then
  cp "$system_compose" "$USER_COMPOSE"
  chmod 0644 "$USER_COMPOSE"
  echo "Created ${USER_COMPOSE} from ${system_compose}."
elif ! grep -qE "$PENDING_RE" "$USER_COMPOSE"; then
  echo "${USER_COMPOSE} already maps 'c to ç. Nothing to do."
  exit 0
else
  backup="${USER_COMPOSE}.$(date +%Y%m%d-%H%M%S).bak"
  cp -p "$USER_COMPOSE" "$backup"
  echo >&2 "${BOLD}*** WARNING: ***${RESET}"
  echo >&2 "${USER_COMPOSE} already exists; editing it in place."
  echo >&2 "Backup saved to ${backup}"
  echo >&2
fi

apply_mapping "$USER_COMPOSE"

cat <<EOM
${BOLD}Cedilla fix applied to ${USER_COMPOSE}.${RESET}

Please log out of your session and re-login to effect changes.

To revert, remove ${USER_COMPOSE} (or restore the .bak backup, if one was made).

If things don't work after a re-login, make sure your Input Method is
configured to "Auto" in the desktop settings.
EOM
