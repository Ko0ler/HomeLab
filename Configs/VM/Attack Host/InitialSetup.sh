#!/bin/bash

# --- Configuration Variables ---
# Modify these as needed before running
LOCAL_TARGET_IP="10.10.3.3"
LOCAL_TARGET_PORT="8080"
ONLINE_TARGET_IP=$TARGET
ONLINE_TARGET_PORT="80"

# --- System Update and Base Tools ---
echo -e "\n[+] UPDATING SYSTEM \n"
sudo apt update && sudo apt upgrade -y && echo -e "\n[+] UPDATE DONE \n"

echo -e "\n[+] INSTALLING ESSENTIAL TOOLS \n"
sudo apt install -y open-vm-tools-desktop zsh gedit build-essential \
    openvpn tmux tree locate btop curlie nmap curl netcat-openbsd git \
    python3-pip python3-venv
echo -e "\n[+] INSTALLATION DONE \n"

# --- ZSH Configuration ---
# This block checks if the setup already exists to prevent duplicate appends
if ! grep -q "########## CUSTOM SETUP ##\n" ~/.zshrc; then
    echo -e "\n[+] CONFIGURING .ZSHRC \n"
    sudo cat << 'EOF' >> ~/.zshrc

########## CUSTOM SETUP ##########

# TARGET DEFINITIONS
# Local Target
ipo=$LOCAL_TARGET_IP
po=$LOCAL_TARGET_PORT
ipho=http://$ipo
iphso=https://$ipo
lipo=$(hostname -I|cut -d ' ' -f1)
lpo=4444

# Online Target
ip=$ONLINE_TARGET_IP
p=$ONLINE_TARGET_PORT
iph=http://$ip
iphs=https://$ip
lip=$(hostname -I|cut -d ' ' -f2)
lp=4444

# ALIASES: Navigation & System
alias lls='ls -alhi'
alias t='tree -L 1'
alias tt='tree -L 2'
alias cl='clear'
alias rr='find . ! -name Data.txt -exec rm -rf {} +'
alias sc='source ~/.zshrc'
alias ssc='sc; clear'

# ALIASES: Networking
alias h='hostname -I'
alias p='ping 8.8.8.8 -c 2'
alias pp='ping $ip -c 2'
alias ppp="ip a; echo; ii; echo '\n>>> INTERNET'; p; echo '\n>>> LOCAL TARGET'; ppo; echo '\n>>> ONLINE TARGET'; pp"
alias nn='ss -o | grep -i "established"'
alias nnl='ss -tulpn'
alias nnc='ss -pno'
alias tp="nc -vz $ip"
alias tpo="nc -vz $ipo"
alias ppo='ping $ipo -c 2'

# ALIASES: Target Info
alias ii='echo -e "\nLOCAL TARGET\n\ntarget (ipo) : $ipo\ntarget-http (ipho) : $ipho\nport (po) : $po\nattacker ip (lipo) : $lipo\nattacker port (lpo) : $lpo\n\nONLINE TARGET\n\ntarget (ip) : $ip\ntarget-http (iph) : $iph\nport (p) : $p\nattacker ip (lip) : $lip\nattacker port (lp) : $lp\n"'

# PATHS
# Adjust these to your actual mount points
ws='/mnt/hgfs/Share-Pentest Lab'
shp='/mnt/hgfs/Share-Pentest Lab/shares'
shv='/mnt/hgfs/Share-VM/'
local='/mnt/hgfs/Share-Pentest Lab/Tests/Local'
tools='/mnt/hgfs/Share-Pentest Lab/Tools'
machine='/mnt/hgfs/Share-Pentest Lab/Tests/HTB/lab/machine'
module='/mnt/hgfs/Share-Pentest Lab/Tests/HTB/modules'

#-------------------------------------------------------------------------------
# FUNCTIONS
#-------------------------------------------------------------------------------

# Search binaries by name
sr() {
    if [ -z "$1" ]; then
        echo "Usage: sr <keyword>"
        return 1
    fi

    echo "===== /usr/bin ====="
    ls -alhi /usr/bin | grep -i "$1"
    echo
    echo "===== /usr/local/bin ====="
    ls -alhi /usr/local/bin | grep -i "$1"
    echo
    echo "===== /opt/tools ====="
    ls -alhi /opt/tools | grep -i "$1"
}

# Continuous port scanner for target monitoring
checkTarget() {
    local IP PORT TIME
    if [ $# -eq 3 ]; then
        IP=$1
        PORT=$2
        TIME=$3
    else
        printf '[Usage]\n%s IP PORT TIME\n[+] Example : %s [TARGET_IP] [PORT] 20\n[+] Using defaults: %s %s 20\n' \
            "$funcstack[1]" "$funcstack[1]" "$ip" "$p"
        IP=${ip:?"ip not set"}
        PORT=${p:?"p not set"}
        TIME=20
    fi

    echo -e "\n[+] Testing $IP:$PORT every $TIME seconds..."
    while true; do
        echo
        date
        nc -vz "$IP" "$PORT"
        sleep "$TIME"
    done
}

# Quick nmap scan
TargetScan() {
    echo -e "\n[+] Nmap Scan (-sS -sV -T4)\n"
	sudo nmap -sS -sV --disable-arp-ping --source-port 53 -T4 -v -oN nmap-tcp-1 $ip
	echo -e "\n[+] Nmap Scan (-sS -A -T4)\n"
	sudo nmap -sS -A --disable-arp-ping --source-port 53 -T4 -v -oN nmap-tcp-2 $ip
}

# Quick web can
WebSacn() {
	echo -e "\n[+] Web footprint (WAF and techno used)\n"
	wafw00f $iph:$p|tee wafcheck-1
	echo -e "\n"
	whatweb $ip:$p|tee whatweb-1
	echo -e "\n"
}

########## END CUSTOM SETUP ##########
EOF
    source ~/.zshrc
    echo -e "\n[+] .ZSHRC UPDATED \n"
else
    echo -e "\n[+] .ZSHRC ALREADY CONFIGURED \n"
fi

# --- TMUX Configuration ---
if ! grep -q "set -g prefix C-space" ~/.tmux.conf; then
    echo -e "\n[+] CONFIGURING .TMUX.CONF \n"
    sudo cat << 'EOF' >> ~/.tmux.conf

unbind r
bind r source-file ~/.tmux.conf \; display \"Config reloaded.\"

# Control
set -g prefix C-space
set -g mouse on

# History
set-option -g history-limit 50000

# Numbering
set -g base-index 1
setw -g pane-base-index 1

# Panes
bind x split-window -v
bind y split-window -h

bind-key h select-pane -L
bind-key j select-pane -D
bind-key k select-pane -U
bind-key l select-pane -R
EOF
    echo -e "\n[+] .TMUX.CONF UPDATED \n"
fi

echo -e "\n[+] FINALIZING SETUP\n"
sudo updatedb &>/dev/null
source ~/.zshrc
echo -e "
#-------------------------------------------------------------------------------
# SETUP COMPLETE
#-------------------------------------------------------------------------------
"
