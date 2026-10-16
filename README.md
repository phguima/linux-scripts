# linux-scripts

A collection of shell scripts to set up and maintain Linux desktops (mostly Fedora, with GNOME or KDE Plasma).

## Scripts

| Script | What it does | Environment |
| --- | --- | --- |
| [`cleanup_old_kernels.sh`](cleanup_old_kernels.sh) | Removes old installed kernels, keeping only the latest one | Fedora (dnf) |
| [`convert-to-md.sh`](convert-to-md.sh) | Converts all PDFs in the parent directory to Markdown | `markitdown` |
| [`extensions-restore.sh`](extensions-restore.sh) | Restores GNOME Shell extension settings from backups | GNOME |
| [`fix-cedilla.sh`](fix-cedilla.sh) | Makes `'` + `c` produce `ç` instead of `ć` | X11/Wayland |
| [`install-vbox-ga.sh`](install-vbox-ga.sh) | Installs VirtualBox Guest Additions matching the host version | VirtualBox VM (dnf/yum/apt) |
| [`monitor60mhz.sh`](monitor60mhz.sh) / [`monitor144mhz.sh`](monitor144mhz.sh) | Switches the monitors' refresh rate to 60 Hz / 144 Hz | KDE Plasma |
| [`plasma-setup.sh`](plasma-setup.sh) | Applies the full KDE Plasma layout (theme, panels, widgets, KZones) | KDE Plasma 6 |
| [`tweaks-gnome-shell.sh`](tweaks-gnome-shell.sh) | GNOME font, window and theme tweaks | GNOME |
| [`user-backup.sh`](user-backup.sh) | Archives the personal folders into `~/<hostname>/` | — |

## Details

### cleanup_old_kernels.sh

```sh
sudo ./cleanup_old_kernels.sh
```

Uses `dnf repoquery --installonly --latest-limit=-1` to list the old kernels and asks for confirmation before removing them.

### convert-to-md.sh

```sh
pip install markitdown
./convert-to-md.sh
```

Searches for PDFs recursively in the script's **parent** directory and writes a `.md` next to each one. Skips PDFs whose `.md` is already newer.

### extensions-restore.sh

```sh
./extensions-restore.sh
```

Loads each `<extension>.config` from `~/Backups/Gnome/Configs/Extensions/` into `/org/gnome/shell/extensions/<extension>/` with `dconf load` (`impatience` goes to the `net/gfxmonk/` path).

### fix-cedilla.sh

```sh
./fix-cedilla.sh
```

Creates `~/.XCompose` from the system Compose file or, if it already exists, edits it in place (with a `.bak` backup). Replaces both the strings (`ć`/`Ć`) and the keysyms (`U0107`/`U0106`), so it also works in apps that read the keysym (e.g. Chromium on Wayland). Safe to run again. Log out and back in afterwards.

Based on [gnome-cedilla-fix](https://github.com/marcopaganini/gnome-cedilla-fix).

### install-vbox-ga.sh

Runs **inside the VM** and aborts if VirtualBox isn't detected.

```sh
sudo ./install-vbox-ga.sh                      # detects the host version and installs/updates
sudo ./install-vbox-ga.sh --force              # reinstalls even if the version already matches
sudo ./install-vbox-ga.sh --pkg                # uses the distro packages
sudo VBOX_VERSION=7.1.4 ./install-vbox-ga.sh   # forces a version (or VBOX_VERSION=latest)
```

- Detects the host version via SMBIOS, `dmidecode` or `VBoxControl`.
- Uses the inserted Guest Additions CD if the version matches; otherwise downloads the ISO from download.virtualbox.org.
- Removes the distro GA packages (they conflict with the ISO one) and installs the build dependencies (`kernel-devel`/`linux-headers`).
- Adds the user who invoked `sudo` to the `vboxsf` group.

### monitor60mhz.sh / monitor144mhz.sh

```sh
./monitor144mhz.sh
```

For each connected monitor, picks via `kscreen-doctor` the mode with the current resolution and the target rate (±1 Hz). Then restarts Ferdium (Flatpak), if it's running. Requires `python3`.

### plasma-setup.sh

```sh
./plasma-setup.sh
```

Requires a running Plasma 6 session. Steps:

1. **Font** — installs Roboto if missing (dnf/apt/pacman/zypper, asks for `sudo`).
2. **KDE Store assets** — opens the "Get New..." windows to manually install Advanced Modern Clock, Panel Colorizer, Ars Icons and KZones, and checks the installation before continuing.
3. **Layout** — backs up the configs to `~/.config/plasma-setup-backup-<date>/`, applies the Breeze Dark theme, icons (including custom app icons), fonts, wallpaper, 4 virtual desktops in 2 rows, KZones layouts, disables the accent popup when holding a key (plasma-keyboard, Plasma 6.7+, without logout), makes Dolphin open in the home folder, and rebuilds the panels (top and side) and the desktop widgets (clock and system monitors) on the primary screen. Restarts plasmashell and checks the result (up to 3 attempts).

Everything that gets applied lives in the `DEFINITIONS` section at the top of the script. The wallpaper is in `assets/wallpapers/` and is copied to `~/Pictures/wallpapers/` if it isn't there yet (so run the script from inside the cloned repository). Log out and back in at the end.

> **Pending test:** the first run in a fresh session, with Plasma's default panel (bottom, with tray). On Plasma 6.6 (AlmaLinux 10, Qt 6.10), removing a tray and creating another one crashes plasmashell; the script guards against this by creating the new panels before removing the old ones and restarting plasmashell before rebuilding the layout. To test without touching your layout: create a test user, log into it once with Plasma and run the script there.

### tweaks-gnome-shell.sh

```sh
./tweaks-gnome-shell.sh
```

Interactive menu:

1. **Before the theme** — Roboto Medium fonts, hinting/antialiasing, 0.88 text scaling, window buttons, center new windows, disables the `background-logo` extension.
2. **After the theme** — enables `user-theme` and applies the WhiteSur-Dark-nord (GTK), Nordzy (icons) and Sunity (cursor) themes.

### user-backup.sh

```sh
./user-backup.sh
```

Creates a `.tar.gz` in `~/<hostname>/` for each existing folder: `Backups`, `Documents`, `Downloads`, `Music`, `Pictures`, `Profiles`, `Videos` and `wks`.

> **Warning:** the `~/<hostname>/` folder is deleted and recreated on every run.
