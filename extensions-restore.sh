#!/bin/bash

extensions_config_dir="${HOME}/Backups/Gnome/Configs/Extensions/"

if [ ! -d "$extensions_config_dir" ]; then
  echo "The extension configuration files were not found!"
  exit 1
fi

cd "$extensions_config_dir" || exit 1

for file in *.config; do
  # Strips the .config extension from the file name
  filename="${file%.config}"
  
  # Checks whether the file name is "impatience"
  if [ "$filename" == "impatience" ]; then
   # Uses the stripped file name in the specific path
    dconf load /org/gnome/shell/extensions/net/gfxmonk/"$filename"/ < "$file"
  else
    # Uses the stripped file name in the default path
    dconf load /org/gnome/shell/extensions/"$filename"/ < "$file"
  fi
done
