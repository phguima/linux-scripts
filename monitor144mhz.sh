#!/bin/sh
# Busca dinamicamente os modos de saída compatíveis com 144Hz
ARGS=$(python3 -c '
import sys, json, subprocess
try:
    data = json.loads(subprocess.check_output(["kscreen-doctor", "-j"]))
    target = 144.0
    args = []
    for out in data.get("outputs", []):
        if not out.get("connected") or not out.get("enabled"):
            continue
        cur_id = out.get("currentModeId")
        cur_mode = next((m for m in out.get("modes", []) if m.get("id") == cur_id), None)
        w = cur_mode["size"]["width"] if cur_mode else out.get("size", {}).get("width")
        h = cur_mode["size"]["height"] if cur_mode else out.get("size", {}).get("height")
        if not w or not h:
            continue
        
        # Procura por um modo com a mesma resolução e a taxa de atualização alvo (±1.0 Hz)
        best_mode = None
        for m in out.get("modes", []):
            if m["size"]["width"] == w and m["size"]["height"] == h:
                if abs(m["refreshRate"] - target) < 1.0:
                    best_mode = m
                    break
        if best_mode:
            args.append("output.{}.mode.{}".format(out["name"], best_mode["id"]))
    print(" ".join(args))
except Exception as e:
    sys.exit(1)
')

if [ -n "$ARGS" ]; then
    echo "Configurando monitores: $ARGS"
    kscreen-doctor $ARGS
else
    echo "Nenhum monitor compatível com 144Hz foi encontrado."
fi

if pgrep -f "org.ferdium.Ferdium" > /dev/null; then
    flatpak kill org.ferdium.Ferdium || true
    flatpak run org.ferdium.Ferdium --hidden &
fi