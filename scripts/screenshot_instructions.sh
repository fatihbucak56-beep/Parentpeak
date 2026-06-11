#!/usr/bin/env bash
# Anleitung: starte einen Android-Emulator und führe diese Befehle aus, um Screenshots zu erstellen
# Beispiel: emulator -avd Pixel_5_API_30
# 1) flutter run -d emulator-5554
# 2) adb exec-out screencap -p > screen_home.png
# 3) Öffne die App, navigiere zu gewünschtem Screen und wiederhole den Befehl

echo "Screenshots werden in aktuellem Verzeichnis gespeichert: screen_*.png"

# Hinweis: Auf Windows nutze 'adb.exe exec-out screencap -p > screen.png' in Powershell
