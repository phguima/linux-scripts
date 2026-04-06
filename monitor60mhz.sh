#!/bin/sh
# 1. Altera para 60Hz (ou 144Hz no outro script)
kscreen-doctor output.1.mode.2

# 2. Pequeno delay para o KWin e o driver de vídeo estabilizarem
sleep 1.5

# 3. Fecha o Ferdium se estiver aberto (o '|| true' evita mensagens de erro)
flatpak kill org.ferdium.Ferdium || true

# 4. Abre o Ferdium novamente em background e minimizado
flatpak run org.ferdium.Ferdium --hidden &
