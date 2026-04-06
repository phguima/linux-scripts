#!/bin/sh
kscreen-doctor output.1.mode.2
#sleep 0.2
flatpak kill org.ferdium.Ferdium || true
flatpak run org.ferdium.Ferdium --hidden &