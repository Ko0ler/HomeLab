#!/bin/bash
set -euo pipefail

mkdir -p ~/ko0ler && cd ~/ko0ler 
# --- System Update and Base Tools ---
echo -e "\n[+] UPDATING SYSTEM \n"
sudo apt update && sudo apt upgrade -y && echo -e "\n[+] UPDATE DONE \n"

echo -e "\n[+] INSTALLING ESSENTIAL TOOLS \n"
sudo apt install -y open-vm-tools-desktop build-essential docker.io docker-compose-v2 gedit net-tools netcat-openbsd btop plocate tree 
echo -e "\n[+] INSTALLATION DONE \n"

# --- BASH Configuration ---
# This block checks if the setup already exists to prevent duplicate appends
if ! grep -q "# CUSTOM SETUP #" ~/.bashrc; then
    echo -e "\n[+] CONFIGURING .BASHRC \n"
    cat << 'EOF' >> ~/.bashrc

########## CUSTOM SETUP ##########

# IP
lip=$(hostname -I|cut -d ' ' -f1)
# PORT
lp=8080

# LOCAL ATTACKER
ip=192.168.160.130
po=4444
iph=http://$ip
iphs=https://$ip

# ALIAS

alias ii='echo -e "\nLOCAL IP\nIP (lip) : $lip\nport (lp) : $lp\n\nLOCAL ATTACKER\nIP (ip) : $ip\nport (po) : $po\nhttp (iph) : $iph\nhttps (iphs) : $iphs\n"'

alias lls='ls -alhi'
alias t='tree -L 1'
alias tt='tree -L 2'

alias h='hostname -I'
alias p='ping 8.8.8.8 -c 2'
alias pp='ping $ip -c 2'
alias pn='ping $ip -n'
alias ppp="ip a;echo;ii;echo -e '\n>>> INTERNET';p;echo -e '\n>>> LOCAL ATTACKER';pp;echo"
alias nn='netstat -o|grep -i "established"'
alias nnl='netstat -tlpo'
alias nnc='netstat -pno'
alias tp='nc -vz $ip'

alias dp='sudo docker ps'
alias dpp='sudo docker ps -aq'
alias dvwa='sudo docker run -d -p 8080:80 vulnerables/web-dvwa'
alias bwapp='sudo docker run -d -p 8070:80 raesene/bwapp'
alias httpb='sudo docker run -d -p 8060:80 kennethreitz/httpbin'
alias wpsql='sudo docker compose -f ~/wordpress/docker-compose.yml up -d'
alias dr='sudo docker run -d -p'
alias ds='sudo docker stop'
alias drm='sudo docker rm -f'
alias dsa='sudo docker stop $(sudo docker ps -aq)'
alias dra='sudo docker rm $(sudo docker ps -aq)'

#alias rr='find . ! -name Data.txt -exec rm -rf {} +'
alias cl='clear'

alias sc='source ~/.bashrc'
alias spp='sc;echo;pp'
alias ssc='sc;cl'
alias sp='ssc;ppp'

#Path

#ws='/mnt/hgfs/Share-Pentest Lab'
#shp='/mnt/hgfs/Share-Pentest Lab/shares'
#shv='/mnt/hgfs/Share-VM/'

# FUNCTIONS

# Start already created containers
dppa() {
    for i in $(sudo docker ps -aq); do 
        sudo docker start "$i"
    done
}

# Search for binaries in default folders using keyword
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

# Periodic check of the availability of a service on a target host
checkState() {
    local IP PORT TIME
    if [ $# -eq 3 ]; then
        IP=$1
        PORT=$2
        TIME=$3
    else
        printf '[Usage]\n%s IP PORT TIME\n[+] Example : %s [TARGET_IP] [PORT] 20\n[+] Using defaults: %s %s 20\n' \
            "${FUNCNAME[0]}" "${FUNCNAME[0]}" "$ip" "$po"
        IP=${ip:?"ip not set"}
        PORT=${po:?"p not set"}
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

# I use and external keyboard and the LED feature is not properly set on the Ubuntu VM
# So here's the fix! Run like this : kb &
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
EOF
    source ~/.bashrc
    echo -e "\n[+] .BASHRC UPDATED \n"
else
    echo -e "\n[+] .BASHRC ALREADY CONFIGURED \n"
fi

echo -e "\n[+] FINALIZING SETUP\n"
shopt -s expand_aliases
sudo updatedb &>/dev/null
source ~/.bashrc

echo -e "\n[+] GETTING VULNERABLE CONTAINERS \n"

sudo docker pull vulnerables/web-dvwa
sudo docker pull raesene/bwapp
sudo docker pull kennethreitz/httpbin

echo -e "\n[+] SETTING VULNERABLE WEBSERVER \nLatest Wordpress and MySQL 8.0\n"

mkdir -p ~/wordpress && cd ~/wordpress
[ -f .env ] || { umask 077; cat > .env << 'ENV_EOF'
MYSQL_ROOT_PASSWORD=Ch@nge_tHis_str0ng_ro0T_pasSWorD
MYSQL_DATABASE=wordpress
MYSQL_USER=wordpress_user
MYSQL_PASSWORD=chaNGe_thIs_StroNg_db_p@ssword
WORDPRESS_PORT=8050
ENV_EOF
}

chmod 600 .env
[ -f docker-compose.yml ] || cat > docker-compose.yml << 'YML_EOF'
services:
  db:
    image: mysql:8.0
    container_name: wordpress_db
    restart: unless-stopped
    environment:
      MYSQL_ROOT_PASSWORD: ${MYSQL_ROOT_PASSWORD}
      MYSQL_DATABASE: ${MYSQL_DATABASE}
      MYSQL_USER: ${MYSQL_USER}
      MYSQL_PASSWORD: ${MYSQL_PASSWORD}
    volumes:
      - db_data:/var/lib/mysql
    networks:
      - wordpress_net
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost", "-u", "root", "-p${MYSQL_ROOT_PASSWORD}"]
      interval: 10s
      timeout: 5s
      retries: 5

  wordpress:
    image: wordpress:latest
    container_name: wordpress_app
    restart: unless-stopped
    depends_on:
      db:
        condition: service_healthy
    ports:
      - "${WORDPRESS_PORT:-8050}:80"
    environment:
      WORDPRESS_DB_HOST: db:3306
      WORDPRESS_DB_USER: ${MYSQL_USER}
      WORDPRESS_DB_PASSWORD: ${MYSQL_PASSWORD}
      WORDPRESS_DB_NAME: ${MYSQL_DATABASE}
    volumes:
      - wp_data:/var/www/html
    networks:
      - wordpress_net

volumes:
  db_data:
  wp_data:

networks:
  wordpress_net:
    driver: bridge
YML_EOF

echo -e "> Run this to start containers : dvwa;bwapp;httpb;wpsql && sudo updatedb;echo;dp;echo;nnl"

echo -e "
#-------------------------------------------------------------------------------
# SETUP COMPLETE
#-------------------------------------------------------------------------------
"
