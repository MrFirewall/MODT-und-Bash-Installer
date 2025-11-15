#!/bin/bash
# install.sh
# Installiert benutzerdefinierte bash.bashrc und 99-custom-banner und deaktiviert alte motd-Dateien.

# Stellen Sie sicher, dass das Skript als Root ausgeführt wird
if [ "$EUID" -ne 0 ]; then
  echo "Bitte als Root (mit sudo) ausführen."
  exit 1
fi

REPO_URL="https://raw.githubusercontent.com/DeinBenutzername/DeinRepoName/main" # <<< BITTE ANPASSEN!
TEMP_DIR="/tmp/custom_config_setup"
MOTD_DIR="/etc/update-motd.d"

echo "--- Starte Installation der globalen Shell-Konfiguration ---"
mkdir -p $TEMP_DIR
cd $TEMP_DIR || { echo "Fehler: Konnte temporäres Verzeichnis nicht erstellen."; exit 1; }

# --- 1. Dateien herunterladen ---
echo "1. Lade Konfigurationsdateien herunter..."
wget -q --show-progress ${REPO_URL}/bash.bashrc
wget -q --show-progress ${REPO_URL}/99-custom-banner

if [ ! -f "bash.bashrc" ] || [ ! -f "99-custom-banner" ]; then
    echo "Fehler: Dateien konnten nicht heruntergeladen werden. Überprüfen Sie die REPO_URL."
    exit 1
fi

# --- 2. Deaktiviere/Entferne alte MOTD-Skripte ---
echo "2. Deaktiviere/Entferne alte MOTD-Skripte..."

# Entfernt alle Standard-Skripte (außer dem eigenen)
find "$MOTD_DIR" -type f ! -name "99-custom-banner" ! -name "README" -exec chmod -x {} \;
# Alternativ: Löschen, wenn Sie sicher sind: find "$MOTD_DIR" -type f ! -name "99-custom-banner" ! -name "README" -delete

# Deaktiviert das 10-header Skript, falls es existiert und gelöscht werden soll
if [ -f "$MOTD_DIR/10-header" ]; then
    chmod -x "$MOTD_DIR/10-header"
fi
# Optional: Entferne alle Standard-Skripte
# rm -f "$MOTD_DIR/"[0-9][0-9]-*

# --- 3. Installiere 99-custom-banner ---
echo "3. Installiere 99-custom-banner..."
cp -f 99-custom-banner "$MOTD_DIR/99-custom-banner"
chmod +x "$MOTD_DIR/99-custom-banner"
echo "   -> 99-custom-banner installiert und ausführbar gemacht."

# --- 4. Ersetze globale bash.bashrc ---
echo "4. Ersetze /etc/bash.bashrc..."
cp -f bash.bashrc /etc/bash.bashrc
echo "   -> /etc/bash.bashrc ersetzt."

# --- 5. Aufräumen ---
rm -rf $TEMP_DIR
echo "--- Installation erfolgreich abgeschlossen! ---"
echo "Bitte melden Sie sich neu an, um die Änderungen zu sehen."
