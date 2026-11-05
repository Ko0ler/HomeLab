#!/bin/bash

# --- System Update and Base Tools ---
echo -e "\n[+] UPDATING SYSTEM \n"
sudo apt update && sudo apt upgrade -y && echo -e "\n[+] UPDATE DONE \n"

echo -e "\n[+] INSTALLING ESSENTIAL TOOLS \n"
sudo apt install -y open-vm-tools-desktop build-essential docker gedit net-tools btop
echo -e "\n[+] INSTALLATION DONE \n"

# --- BASH Configuration ---
# This block checks if the setup already exists to prevent duplicate appends
if ! grep -q "########## CUSTOM SETUP ##\n" ~/.bashrc; then
    echo -e "\n[+] CONFIGURING .BASHRC \n"
    sudo cat << 'EOF' >> ~/.bashrc

########## CUSTOM SETUP ##########

# IP
lip=$(hostname -I|cut -d ' ' -f1)
# PORT
lp=8080
# URL
iph=http://$ip
iphs=https://$ip

# LOCAL ATTACKER
ip=192.168.160.130
p=4444

# ALIAS

alias ii='echo -e "\nLOCAL IP\nIP (lip) : $lip\nport (lp) : $lp\nhttp (iph) : $iph\nhttps (iphs) : $iphs\n\nLOCAL ATTACKER\nIP (ip) : $ip\nport (p) : $p"'

alias lls='ls -alhi'
alias t='tree -L 1'
alias tt='tree -L 2'

alias h='hostname -I'
alias p='ping 8.8.8.8 -c 2'
alias pp='ping $ip -c 2'
alias pn='ping $ip -n'
alias ppp="ip a;echo;ii;echo '\n>>> INTERNET';p;echo '\n>>> LOCAL ATTACKER';pp;echo"
alias nn='netstat -o|grep -i 'established''
alias nnl='netstat -tlpo'
alias nnc='netstat -pno'
alias tp="nc -vz $ip"
alias tpo="nc -vz $ipo"

alias dp='sudo docker ps'
alias dpp='sudo docker ps -aq'
alias dvwa='sudo docker run -d -p 8080:80 vulnerables/web-dvwa'
alias bwapp='sudo docker run -d -p 8070:80 raesene/bwapp'
alias httpb='sudo docker run -d -p 8060:80 kennethreitz/httpbin'
alias dr='sudo docker run -d -p'
alias ds='sudo docker stop'
alias drm='sudo docker rm -f'
alias dsa='sudo docker stop $(sudo docker ps -aq)'
alias dra='sudo docker rm $(sudo docker ps -aq)'

alias rr='find . ! -name Data.txt -exec rm -rf {} +'
alias cl='clear'

alias sc='source ~/.bashrc'
alias spp='sc;echo;pp'k
alias ssc='sc;cl'
alias sp='ssc;ppp'

#Path

ws='/mnt/hgfs/Share-Pentest Lab'
shp='/mnt/hgfs/Share-Pentest Lab/shares'
shv='/mnt/hgfs/Share-VM/'

#FUNCTION

dppa() {
    for i in $(sudo docker ps -aq); do 
        sudo docker start "$i"
    done
}

sr() {
    if [ -z "$1" ]; then
        echo "Usage: sr <keyword>"
        return 1
    fi

    echo "===== /usr/bin ====="
    ls -alhi /usr/bin | grep -i "$1"

    echo
    echo "===== /usr/sbin ====="
    ls -alhi /usr/sbin | grep -i "$1"
}

checkState() {
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

kb() {
    while true; do
        # Find the current path dynamically, regardless of the number changing
        DEVICE_PATH=$(ls -d /sys/class/leds/input*::scrolllock 2>/dev/null | grep -v 'input3::')
    
        if [ -n "$DEVICE_PATH" ]; then
            # Read current state; if it's 0, force it to 1
            CURRENT_STATE=$(cat "$DEVICE_PATH/brightness")
            if [ "$CURRENT_STATE" -eq 0 ]; then
                echo 1 | sudo tee "$DEVICE_PATH/brightness" > /dev/null
            fi
        fi
        # Sleep briefly to save CPU resources while reacting fast to Caps Lock presses
        sleep 0.5
    done
}

#export PROMPT='-%F{10}[%D{%m/%d/%Y} %*]-%F{214}%n%F{196}@%m%f-%F{33}%~%f $ '
EOF
    source ~/.bashrc
    echo -e "\n[+] .BASHRC UPDATED \n"
else
    echo -e "\n[+] .BASHRC ALREADY CONFIGURED \n"
fi

echo -e "\n[+] FINALIZING SETUP\n"
sudo updatedb &>/dev/null
source ~/.bashrc

echo -e "\n[+] GETTING VULNERABLE CONTAINERS \n"

sudo docker pull vulnerables/web-dvwa
sudo docker pull raesene/bwapp
sudo docker pull kennethreitz/httpbin
dvwa;bwapp;httpb && sudo updatedb;echo;dp;echo;nnl

echo -e "
#-------------------------------------------------------------------------------
# SETUP COMPLETE
#-------------------------------------------------------------------------------
"
