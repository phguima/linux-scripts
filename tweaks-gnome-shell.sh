#!/bin/bash

# Colors scheme
CDEF="\033[0m"                                 	        	# default color
CCIN="\033[0;36m"                              		        # info color
CGSC="\033[0;32m"                              		        # success color
CRER="\033[0;31m"                              		        # error color
CWAR="\033[0;33m"                              		        # waring color
b_CDEF="\033[1;37m"                            		        # bold default color
b_CCIN="\033[1;36m"                            		        # bold info color
b_CGSC="\033[1;32m"                            		        # bold success color
b_CRER="\033[1;31m"                            		        # bold error color
b_CWAR="\033[1;33m"                            		        # bold warning color

# Display message colors
prompt () {
	case ${1} in
		"-s"|"--success")
			echo -e "${b_CGSC}${@/-s/}${CDEF}";;            # print success message
		"-e"|"--error")
			echo -e "${b_CRER}${@/-e/}${CDEF}";;            # print error message
		"-w"|"--warning")
			echo -e "${b_CWAR}${@/-w/}${CDEF}";;            # print warning message
		"-i"|"--info")
			echo -e "${b_CCIN}${@/-i/}${CDEF}";;            # print info message
		*)
			echo -e "$@"
		;;
	 esac
}

# Print menu
prompt -w "Menu:"
prompt "1. Before theme install tweaks"
prompt "2. After theme install tweaks"
prompt "-"
prompt "Q. Quit"
prompt ""
read -p "Choose one options: " optionsSelection
        
# Validate user inserts and converts user selection to an array
if [[ "$optionsSelection"  =~ ^[Q-q] ]]; then
    prompt -s ">>>   Script finished   <<<"
    exit 0
elif [[ "$optionsSelection" == 1 ]]; then
    prompt -i ">>> Changing fonts... "
    gsettings set org.gnome.desktop.interface font-name "Roboto Medium 11"
    gsettings set org.gnome.desktop.interface document-font-name "Roboto Medium 11"
    gsettings set org.gnome.desktop.interface monospace-font-name "Roboto Medium 11"
   # gsettings set org.gnome.desktop.wm.preferences titlebar-font "Cantarell Bold 10"
    
    prompt -i ">>> Changing hinting and antialiasing... "
    gsettings set org.gnome.desktop.interface font-hinting full
    gsettings set org.gnome.desktop.interface font-antialiasing rgba

    prompt -i ">>> Changing text scaling factor... "
    gsettings set org.gnome.desktop.interface text-scaling-factor 0.88
    
    prompt -i ">>> Changing windows settings... "
    gsettings set org.gnome.mutter center-new-windows true
    gsettings set org.gnome.desktop.wm.preferences button-layout appmenu:minimize,maximize,close
    gsettings set org.gnome.desktop.wm.preferences action-middle-click-titlebar minimize
    
    prompt -i ">>> Disabling background logo extension... "
    gsettings set org.gnome.shell disabled-extensions "['background-logo@fedorahosted.org']"

    prompt -s ">>>   Script finished   <<<"
    exit 0
elif [[ "$optionsSelection" == 2 ]]; then
    if [[ "gnome-extensions list | grep user-theme" ]]; then
        gsettings set org.gnome.shell enabled-extensions "['user-theme@gnome-shell-extensions.gcampax.github.com']"
        #gsettings set org.gnome.shell.extensions.user-theme name WhiteSur-Dark-nord
    fi
    
    gsettings set org.gnome.desktop.interface cursor-theme Sunity-cursors-white
    gsettings set org.gnome.desktop.interface icon-theme Nordzy-dark--light_panel
    gsettings set org.gnome.desktop.interface gtk-theme WhiteSur-Dark-nord

    prompt -s ">>>   Script finished   <<<"
    exit 0
else
    prompt -e ">>>   Invalid option!   <<< "
fi
