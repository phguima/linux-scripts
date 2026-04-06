#!/bin/sh
kscreen-doctor output.1.mode.2

if pgrep -f "org.ferdium.Ferdium" > /dev/null; then
    flatpak kill org.ferdium.Ferdium || true
    flatpak run org.ferdium.Ferdium --hidden &
fi