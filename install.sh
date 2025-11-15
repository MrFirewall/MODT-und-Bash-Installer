#!/bin/bash
#
# MODT & BASH Global Installer Script by MrFirewall
# Dieses Skript installiert die benutzerdefinierten MOTD- und Bash-Einstellungen
# und entfernt alle Standard-MOTD-Dateien, um eine saubere Anzeige zu gewährleisten.

# Stellen Sie sicher, dass das Skript als Root ausgeführt wird
if [ "$EUID" -ne 0 ]; then
  echo "Bitte führen Sie dieses Skript als Root aus."
  exit 1
fi

echo "================================================="
echo "=== Globale MOTD & BASH Installation gestartet ==="
echo "================================================="

# --- 1. GLOBALE VARIABLEN UND ZIELPFADE ---
TARGET_BASHRC="/etc/bash.bashrc"
TARGET_MOTD_DIR="/etc/update-motd.d"
TARGET_BANNER="$TARGET_MOTD_DIR/99-custom-banner"

# --- 2. DEAKTIVIERUNG ALTER MOTD-DATEIEN ---

echo "[INFO] Deaktiviere und entferne alte MOTD-Dateien..."
# Entfernt alle Standard-MOTD-Dateien (typischerweise 10-header, 20-disk, etc.)
# behält aber die 99-custom-banner oder Dateien mit höherer Nummer, die noch da sind
find "$TARGET_MOTD_DIR" -type f -not -name "README" -not -name "99-custom-banner" -exec rm -f {} \;
echo "[INFO] Vorhandene Standard-Banner entfernt."

# --- 3. ERSTELLUNG DER NEUEN BASH.BASHRC ---

echo "[INFO] Erstelle die globale BASH.BASHRC ($TARGET_BASHRC)..."
cat > "$TARGET_BASHRC" << 'EOF'
# System-wide .bashrc file for interactive bash(1) shells.

# To enable the settings / commands in this file for login shells as well,
# this file has to be sourced in /etc/profile.

# If not running interactively, don't do anything
[ -z "$PS1" ] && return

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "${debian_chroot:-}" ] && [ [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# #############################################################
# # MODIFIZIERTE GLOBALE BASH-KONFIGURATION START (FINAL) #
# #############################################################

# --- 1. ANSI-Farbcodes ---
GREEN='\[\033[0;32m\]'
LIGHT_GREEN='\[\033[1;32m\]'
BLUE='\[\033[0;34m\]'
CYAN='\[\033[0;36m\]'
LIGHT_CYAN='\[\033[1;36m\]' 
YELLOW='\[\033[0;33m\]'
NC='\[\033[0m\]' # No Color

# --- 2. DYNAMISCHER PROMPT (PS1) ---

# Funktion zum Abrufen des Git-Branch (wird beibehalten, falls benötigt)
parse_git_branch() {
  git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/ (\1)/'
}

# PROMPT_COMMAND: Setzt nur den Fenstertitel
PROMPT_COMMAND='
  # Setzt den Fenstertitel im Terminal
  if [[ "$TERM" =~ ^(xterm|rxvt) ]]; then
      echo -ne "\033]0;${USER}@${HOSTNAME}: ${PWD}\007"
  fi
'

# Einzeilige PS1 mit klarer Trennung und Pfeil:
# Format: [ user@host ] /path/to/directory >>> 
PS1="${LIGHT_GREEN}[ ${CYAN}\u@\h${LIGHT_GREEN} ]${NC} ${LIGHT_CYAN}\w${NC} ${YELLOW}>>>${NC} "


# --- 3. GLOBALE ALIASE ---
# Aktiviert Farben für 'ls'
alias ls='ls --color=auto' 
alias user="su -ls /bin/bash"
alias v="ls -lA"
# preserve 'mc' CWD upon F10 exit
alias mc='fn(){ local f=$(mktemp);$(which mc) -P $f "$@";[[ -s $f ]] && cd $(cat $f);rm $f;};fn'


# --- 4. BASH COMPLETION ---
# enable bash completion in interactive shells
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi

# #############################################################
# # MODIFIZIERTE GLOBALE BASH-KONFIGURATION ENDE #
# #############################################################


# if the command-not-found package is installed, use it (Originalcode)
if [ -x /usr/lib/command-not-found -o -x /usr/share/command-not-found/command-not-found ]; then
	function command_not_found_handle {
	    # check because c-n-f could've been removed in the meantime
            if [ -x /usr/lib/command-not-found ]; then
		/usr/lib/command-not-found -- "$1"
                    return $?
            elif [ -x /usr/share/command-not-found/command-not-found ]; then
		/usr/share/command-not-found/command-not-found -- "$1"
                    return $?
		else
		    printf "%s: command not found\n" "$1" >&2
		    return 127
		fi
	}
fi
EOF
echo "[ERFOLG] Neue $TARGET_BASHRC erstellt."

# --- 4. ERSTELLUNG DER NEUEN 99-CUSTOM-BANNER ---

echo "[INFO] Erstelle den $TARGET_BANNER..."
cat > "$TARGET_BANNER" << 'EOF'
#!/bin/sh
#
# /etc/update-motd.d/99-custom-banner
# Stabile Version mit System-Status und Mount-Check.

# 1. Globale Infos
HOSTNAME=$(hostname)
IP_ADDRESS=$(hostname -I | awk '{print $1}')
OS_VERSION=$(grep PRETTY_NAME /etc/os-release | cut -d'"' -f2)

# --- DYNAMISCHE SYSTEM-INFOS ---
UPTIME=$(uptime -p | sed 's/up //')
CPU_CORES=$(nproc)
CPU_LOAD=$(uptime | awk -F'load average: ' '{print $2}' | cut -d, -f1) # 1-min Load

# RAM-Berechnung in GB (formatiert auf 1 Nachkommastelle)
RAM_USED_GB=$(free -m | awk 'NR==2{printf "%.1f", $3/1024}') 
RAM_TOTAL_GB=$(free -m | awk 'NR==2{printf "%.1f", $2/1024}') 
RAM_PERCENT=$(free -m | awk 'NR==2{printf "%.0f%%", $3*100/$2 }')

# --- ANPASSBARE VARIABLEN ---
SERVICE_NAME="$(echo "$HOSTNAME" | sed -e 's/-/ /g' -e 's/\b\(.\)/\u\1/g' | sed 's/Lxc/LXC/g' | sed 's/Vm/VM/g')"
DEIN_NAME="MrFirewall"

# 2. ANSI-Farbcodes
CYAN="\033[1;36m"
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
RED="\033[1;31m"
BLUE="\033[1;34m"
NC="\033[0m" # Reset

# --- DYNAMISCHE MOUNT-STATUS PRÜFUNG ---

check_mount_status() {
    MOUNT_POINT="$1"
    FS_TYPE="$2"
    
    # Prüft, ob der Mountpoint verbunden und zugreifbar ist
    if mountpoint -q "$MOUNT_POINT" && find "$MOUNT_POINT" -maxdepth 0 -exec test -r {} \; 2>/dev/null; then
        STATUS_COLOR="$GREEN"
        STATUS_TEXT="STABIL ✅"
    else
        STATUS_COLOR="$RED"
        STATUS_TEXT="DEFEKT ❌ (PRÜFEN SIE HOST/NETZWERK)"
    fi
    
    # Korrigierte Ausgabe für saubere Farben
    printf " %s [%s]: %b%s%b\n" "$MOUNT_POINT" "$FS_TYPE" "$STATUS_COLOR" "$STATUS_TEXT" "$NC"
}

# 3. Hauptbanner ausgeben
printf "\n${CYAN}====================================================${NC}\n"
printf " ✨ ${BLUE}%s ${NC} | 🧑‍💻 Statusbericht bereitgestellt von: ${YELLOW}%s${NC}\n" "$SERVICE_NAME" "$DEIN_NAME"
printf "${CYAN}====================================================${NC}\n"

# 4. Allgemeine Systeminformationen
printf " 🏠 Hostname: ${GREEN}%s${NC} | 💡 IP-Adresse: ${GREEN}%s${NC}\n" "$HOSTNAME" "$IP_ADDRESS"
printf " 🖥️ OS-Version: ${GREEN}%s${NC}\n" "$OS_VERSION"

# 5. Dynamische Performance-Infos (ZWEISPALTIG)
printf "\n--- ${CYAN}SYSTEM PERFORMANCE STATUS ${NC} ---\n"
printf " %-20s %b%-18s%b\n" "⏳ Uptime:" "$GREEN" "$UPTIME" "$NC"

# KORRIGIERTE RAM-AUSGABE IN GB
printf " %-20s %b%s GB%b (%s)\n" "🧠 RAM Used:" "$YELLOW" "$RAM_USED_GB" "$NC" "$RAM_PERCENT" 
printf " %-20s %b%s GB%b\n" "🧠 RAM Total:" "$YELLOW" "$RAM_TOTAL_GB" "$NC"

printf " %-20s %s Kerne\n" "⚡ CPU Cores:" "$CPU_CORES"
printf " %-20s %b%s%b\n" "🔥 CPU Load (1min):" "$YELLOW" "$CPU_LOAD" "$NC"


# 6. Dynamische Mounts abrufen und Status ausgeben
printf "\n--- ${CYAN}KRITISCHER SPEICHER STATUS ${NC} ---\n"

grep -E 'nfs|cifs|smb|virtiofs' /proc/mounts | while read LINE ; do
    MOUNT_POINT=$(echo "$LINE" | awk '{print $2}')
    FS_TYPE=$(echo "$LINE" | awk '{print $3}')

    case "$MOUNT_POINT" in
        /mnt/*)
            check_mount_status "$MOUNT_POINT" "$FS_TYPE"
            ;;
        *)
            ;;
    esac
done

printf "${CYAN}====================================================${NC}\n"
printf "\n"
EOF

chmod +x "$TARGET_BANNER"
echo "[ERFOLG] $TARGET_BANNER erstellt und ausführbar gemacht."

echo "================================================="
echo "=== Installation abgeschlossen! ==="
echo "Bitte melden Sie sich neu an, um die Änderungen zu sehen."
echo "================================================="
