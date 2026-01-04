#/bin/bash

extensions_config_dir="${HOME}/Backups/Gnome/Configs/Extensions/"

if [ ! -d "$extensions_config_dir" ]; then
  echo "Os arquivos de configuração das extensões não foram encontrados!"
  exit 1
fi

cd "$extensions_config_dir" || exit 1

for file in *.config; do
  # Remove a extensão .config do nome do arquivo
  filename="${file%.config}"
  
  # Verifica se o nome do arquivo é "impatience"
  if [ "$filename" == "impatience" ]; then
   # Utiliza o nome do arquivo modificado no caminho específico
    dconf load /org/gnome/shell/extensions/net/gfxmonk/"$filename"/ < "$file"
  else
    # Utiliza o nome do arquivo modificado no caminho padrão
    dconf load /org/gnome/shell/extensions/"$filename"/ < "$file"
  fi
done
