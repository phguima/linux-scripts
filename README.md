# linux-scripts

Coleção de scripts shell para configurar e manter desktops Linux (principalmente Fedora, com GNOME ou KDE Plasma).

## Scripts

| Script | O que faz | Ambiente |
| --- | --- | --- |
| [`cleanup_old_kernels.sh`](cleanup_old_kernels.sh) | Remove os kernels antigos instalados, mantendo só o mais recente | Fedora (dnf) |
| [`convert-to-md.sh`](convert-to-md.sh) | Converte todos os PDFs do diretório pai para Markdown | `markitdown` |
| [`extensions-restore.sh`](extensions-restore.sh) | Restaura as configurações das extensões do GNOME Shell a partir de backups | GNOME |
| [`fix-cedilla.sh`](fix-cedilla.sh) | Faz `'` + `c` gerar `ç` em vez de `ć` | X11/Wayland |
| [`install-vbox-ga.sh`](install-vbox-ga.sh) | Instala o VirtualBox Guest Additions na mesma versão do host | VM VirtualBox (dnf/yum/apt) |
| [`monitor60mhz.sh`](monitor60mhz.sh) / [`monitor144mhz.sh`](monitor144mhz.sh) | Muda a taxa de atualização dos monitores para 60 Hz / 144 Hz | KDE Plasma |
| [`plasma-setup.sh`](plasma-setup.sh) | Aplica o layout completo do KDE Plasma (tema, painéis, widgets, KZones) | KDE Plasma 6 |
| [`tweaks-gnome-shell.sh`](tweaks-gnome-shell.sh) | Ajustes de fontes, janelas e temas do GNOME | GNOME |
| [`user-backup.sh`](user-backup.sh) | Compacta as pastas pessoais em `~/<hostname>/` | — |

## Detalhes

### cleanup_old_kernels.sh

```sh
sudo ./cleanup_old_kernels.sh
```

Usa `dnf repoquery --installonly --latest-limit=-1` para listar os kernels antigos e pede confirmação antes de removê-los.

### convert-to-md.sh

```sh
pip install markitdown
./convert-to-md.sh
```

Procura PDFs recursivamente no diretório **pai** do script e gera um `.md` ao lado de cada um. Pula os PDFs cujo `.md` já está mais recente.

### extensions-restore.sh

```sh
./extensions-restore.sh
```

Carrega com `dconf load` cada `<extensão>.config` de `~/Backups/Gnome/Configs/Extensions/` em `/org/gnome/shell/extensions/<extensão>/` (`impatience` vai para o caminho `net/gfxmonk/`).

### fix-cedilla.sh

```sh
./fix-cedilla.sh
```

Cria `~/.XCompose` a partir do arquivo Compose do sistema ou, se ele já existir, edita no lugar (com backup `.bak`). Troca tanto as strings (`ć`/`Ć`) quanto os keysyms (`U0107`/`U0106`), para funcionar também em apps que leem o keysym (ex.: Chromium no Wayland). Pode ser rodado de novo sem efeito. Faça logout/login depois.

Baseado em [gnome-cedilla-fix](https://github.com/marcopaganini/gnome-cedilla-fix).

### install-vbox-ga.sh

Roda **dentro da VM** e aborta se não detectar VirtualBox.

```sh
sudo ./install-vbox-ga.sh                      # detecta a versão do host e instala/atualiza
sudo ./install-vbox-ga.sh --force              # reinstala mesmo se a versão já bater
sudo ./install-vbox-ga.sh --pkg                # usa os pacotes da distro
sudo VBOX_VERSION=7.1.4 ./install-vbox-ga.sh   # força uma versão (ou VBOX_VERSION=latest)
```

- Detecta a versão do host via SMBIOS, `dmidecode` ou `VBoxControl`.
- Usa o CD de Guest Additions inserido se a versão bater; senão baixa o ISO de download.virtualbox.org.
- Remove os pacotes de GA da distro (conflitam com o do ISO) e instala as dependências de compilação (`kernel-devel`/`linux-headers`).
- Adiciona o usuário que chamou o `sudo` ao grupo `vboxsf`.

### monitor60mhz.sh / monitor144mhz.sh

```sh
./monitor144mhz.sh
```

Para cada monitor conectado, escolhe via `kscreen-doctor` o modo com a resolução atual e a taxa alvo (±1 Hz). Depois reinicia o Ferdium (Flatpak), se estiver aberto. Requer `python3`.

### plasma-setup.sh

```sh
./plasma-setup.sh
```

Precisa de uma sessão Plasma 6 em execução. Etapas:

1. **Fonte** — instala o Roboto se faltar (dnf/apt/pacman/zypper, pede `sudo`).
2. **Assets da KDE Store** — abre as janelas "Obter novos..." para instalar manualmente Advanced Modern Clock, Panel Colorizer, Ars Icons e KZones, e verifica a instalação antes de continuar.
3. **Layout** — faz backup das configs em `~/.config/plasma-setup-backup-<data>/`, aplica tema Breeze Dark, ícones, fontes, wallpaper, 4 áreas de trabalho, layouts do KZones, recria os painéis (superior e lateral) e os widgets da área de trabalho (relógio e monitores do sistema). Reinicia o plasmashell e confere o resultado (até 3 tentativas).

Tudo o que é aplicado fica na seção `DEFINIÇÕES` no topo do script. O wallpaper só é usado se existir em `~/Pictures/wallpapers/wallpaper_16.jpeg`. Faça logout/login no final.

### tweaks-gnome-shell.sh

```sh
./tweaks-gnome-shell.sh
```

Menu interativo:

1. **Antes do tema** — fontes Roboto Medium, hinting/antialiasing, escala de texto 0.88, botões de janela, centralizar novas janelas, desativa a extensão `background-logo`.
2. **Depois do tema** — ativa `user-theme` e aplica os temas WhiteSur-Dark-nord (GTK), Nordzy (ícones) e Sunity (cursor).

### user-backup.sh

```sh
./user-backup.sh
```

Gera um `.tar.gz` em `~/<hostname>/` para cada pasta existente: `Backups`, `Documents`, `Downloads`, `Music`, `Pictures`, `Profiles`, `Videos` e `wks`.

> **Atenção:** a pasta `~/<hostname>/` é apagada e recriada a cada execução.
