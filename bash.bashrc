# System-wide .bashrc file for interactive bash(1) shells.

# To enable the settings / commands in this file for login shells as well,
# this file has to be sourced in /etc/profile.

# If not running interactively, don't do anything
[ -z "$PS1" ] && return

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# set variable identifying the chroot you work in (used in the prompt below)
# KORREKTUR: Die Klammern des 'if'-Statements wurden repariert.
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# #############################################################
# # MODIFIZIERTE GLOBALE BASH-KONFIGURATION START (FINAL) #
# #############################################################

# --- 1. ANSI-Farbcodes ---
BLUE='\[\033[0;34m\]'
CYAN='\[\033[1;36m\]'
GREEN='\[\033[0;32m\]'
YELLOW='\[\033[0;33m\]'
LIGHT_CYAN='\[\033[1;36m\]' 
LIGHT_GREEN='\[\033[1;32m\]'
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
