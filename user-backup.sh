#!/bin/bash

# Colors scheme
CDEF="\033[0m"                                 	        	# default color
b_CCIN="\033[1;36m"                            		        # bold info color
b_CGSC="\033[1;32m"                            		        # bold success color
b_CRER="\033[1;31m"                            		        # bold error color
b_CWAR="\033[1;33m"                            		        # bold warning color

# Display message colors
prompt () {
	local flag=${1}
	case ${flag} in
		"-s"|"--success")
			shift; echo -e "${b_CGSC}$*${CDEF}";;            # print success message
		"-e"|"--error")
			shift; echo -e "${b_CRER}$*${CDEF}";;            # print error message
		"-w"|"--warning")
			shift; echo -e "${b_CWAR}$*${CDEF}";;            # print warning message
		"-i"|"--info")
			shift; echo -e "${b_CCIN}$*${CDEF}";;            # print info message
		*)
			echo -e "$*"
		;;
	 esac
}

# Target folder: ~/<hostname>. It is deleted and recreated on every run, so
# refuse to continue if it could ever resolve to $HOME itself.
host_name="${HOSTNAME:-$(hostname)}"
if [ -z "$host_name" ] || [ -z "$HOME" ] || [ ! -d "$HOME" ]; then
  prompt -e ">>> ERROR: Can't determine HOME or hostname. Aborting."
  exit 1
fi
target_dir="${HOME}/${host_name}"
if [ "$target_dir" = "$HOME" ] || [ "$target_dir" = "$HOME/" ]; then
  prompt -e ">>> ERROR: Target folder resolves to HOME. Aborting."
  exit 1
fi

# Folders to back up (relative to HOME) and their labels
folders=(
  "Backups:backups"
  "Documents:documents"
  "Downloads:downloads"
  "Music:music"
  "Pictures:pictures"
  "Profiles:profiles"
  "Videos:videos"
  "wks:workspace [wks]"
)

cd "${HOME}" || { prompt -e ">>> ERROR: Can't enter ${HOME}. Aborting."; exit 1; }

# Create target_dir
if [ -d "$target_dir" ]; then
  prompt -w ">>> Deleting older target folder..."

  if rm -rf "$target_dir"; then
    prompt -s ">>> Older target folder was successfully deleted ..."
  else
    prompt -e ">>> ERROR: Can't delete older target folder..."
    exit 1
  fi
fi

prompt -i ">>> Creating the target folder..."
mkdir "$target_dir" || { prompt -e ">>> ERROR: Can't create ${target_dir}."; exit 1; }
prompt -s ">>> DONE"

# Start folders backup
for entry in "${folders[@]}"; do
  dir="${entry%%:*}"
  label="${entry#*:}"
  archive="$(echo "$dir" | tr '[:upper:]' '[:lower:]').tar.gz"

  if [ -d "./$dir" ]; then
    prompt -i ">>> Backing up ${label} folder..."

    if tar cpfz "${target_dir}/${archive}" "./$dir"; then
      prompt -s ">>> DONE"
    else
      prompt -e ">>> ERROR: Failed to back up ${label} folder..."
    fi
  else
    prompt -w ">>> ${label^} folder doesn't exist..."
  fi
done

prompt -s ">>> Backup finalizado! <<<"
