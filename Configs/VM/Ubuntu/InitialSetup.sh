#!/bin/bash
set -euo pipefail

mkdir -p ~/ko0ler && cd ~/ko0ler 
# --- System Update and Base Tools ---
echo -e "\n[+] UPDATING SYSTEM \n"
sudo apt update && sudo apt upgrade -y && echo -e "\n[+] UPDATE DONE \n"

echo -e "\n[+] INSTALLING ESSENTIAL TOOLS \n"
sudo apt install -y open-vm-tools-desktop build-essential gedit net-tools netcat-openbsd btop plocate tree docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin 
echo -e "\n[+] INSTALLATION DONE \n"

# --- BASH Configuration ---
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

alias dvwa='sudo docker run -d --name dvwa_app -p 8080:80 vulnerables/web-dvwa'
alias bwapp='sudo docker run -d --name bwapp_app -p 8070:80 raesene/bwapp'
alias httpb='sudo docker run -d --name httpbin_app -p 8060:80 kennethreitz/httpbin'
alias wpsql='sudo docker compose -f ~/wordpress/docker-compose.yml up -d'
alias fullweb='dvwa && bwapp && httpb && wpsql'

alias dp='sudo docker ps'
alias dpp='sudo docker ps -aq'
alias dr='sudo docker run -d -p'
alias dsf='sudo docker stop wordpress_app wordpress_db mailpit_app httpbin_app bwapp_app dvwa_app'
alias drf='sudo docker rm wordpress_app wordpress_db mailpit_app httpbin_app bwapp_app dvwa_app'
alias dsa='sudo docker stop $(dpp)'
alias dra='dsa && sudo docker rm $(dpp)'

#alias rr='find . ! -name Data.txt -exec rm -rf {} +'
alias cl='clear'

alias sc='source ~/.bashrc'
alias spp='sc;echo;pp'
alias ssc='sc;cl'
alias sp='ssc;ppp'

#Path

ws='/mnt/hgfs/Share-Pentest Lab'
shp='/mnt/hgfs/Share-Pentest Lab/shares'
shv='/mnt/hgfs/Share-VM/'

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

# I use an external keyboard and the LED feature is not properly set on the Ubuntu VM
# So here's the fix! Run like this: kb &
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

########## END CUSTOM SETUP ##########
}
EOF
    echo -e "\n[+] BASHRC UPDATED \n"
else
    echo -e "\n[+] BASHRC ALREADY CONFIGURED \n"
fi

echo -e "\n[+] UPDATING FILE NAME DATABASE\n"
shopt -s expand_aliases
sudo updatedb &>/dev/null

echo -e "\n[+] GETTING VULNERABLE CONTAINERS \nLatest DVWA, bWAPP, httpbin, Mailpit and Wordpress\n"

sudo docker pull vulnerables/web-dvwa
sudo docker pull raesene/bwapp
sudo docker pull kennethreitz/httpbin
sudo docker pull axllent/mailpit:latest
sudo docker pull wordpress:latest

echo -e "\n[+] SETTING VULNERABLE WEBSERVER \nLatest Wordpress, MySQL 8.0 and latest Mailpit"

mkdir -p ~/wordpress && cd ~/wordpress
[ -f .env ] && echo -e "\n> File '.env' already exists" || { umask 077; cat > .env << ENV_EOF
MYSQL_ROOT_PASSWORD=$(openssl rand -hex 16)
MYSQL_DATABASE=wordpress
MYSQL_USER=wordpress_user
MYSQL_PASSWORD=$(openssl rand -hex 16)
WORDPRESS_PORT=8050
WP_ADMIN_USER=admin
WP_ADMIN_PASSWORD=$(openssl rand -hex 12)
MAILPIT_UI_PORT=8025
MAILPIT_SMTP_PORT=1025
MP_MAX_MESSAGES=5000
MP_SMTP_AUTH_ACCEPT_ANY=1
MP_SMTP_AUTH_ALLOW_INSECURE=1
ENV_EOF

echo -e "\n> Created '.env' file"
}

[ -f docker-compose.yml ] && echo -e "\n> File 'docker-compose.yml' already exists\n" || { cat > docker-compose.yml << 'YML_EOF'
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

  mailpit:
    image: axllent/mailpit:latest
    container_name: mailpit_app
    restart: unless-stopped
    ports:
      - "127.0.0.1:${MAILPIT_UI_PORT:-8025}:8025"
      - "127.0.0.1:${MAILPIT_SMTP_PORT:-1025}:1025"
    environment:
      MP_MAX_MESSAGES: ${MP_MAX_MESSAGES:-5000}
      MP_DATABASE: /data/mailpit.db
      MP_SMTP_AUTH_ACCEPT_ANY: ${MP_SMTP_AUTH_ACCEPT_ANY:-1}
      MP_SMTP_AUTH_ALLOW_INSECURE: ${MP_SMTP_AUTH_ALLOW_INSECURE:-1}
    volumes:
      - mailpit_data:/data
    networks:
      - wordpress_net

volumes:
  db_data:
  wp_data:
  mailpit_data:

networks:
  wordpress_net:
    driver: bridge
YML_EOF

echo -e "\n> Created 'docker-compose.yml' file\n"
}

echo -e "\n[+] BOOTSTRAPPING WORDPRESS & WP MAIL SMTP \n"

CONFIGURED=true

# Initiate Wordpress from Docker compose
if [ -f ~/wordpress/docker-compose.yml ]; then
    echo -e "> Removing existing data to avoid conflicts..."
    sudo docker compose -f ~/wordpress/docker-compose.yml down -v
fi
sudo docker compose -f ~/wordpress/docker-compose.yml up -d
echo -e "\n> Waiting for WordPress container to become ready..."
WP_READY=false
for i in {1..90}; do
    if sudo docker exec wordpress_app \
        test -f /var/www/html/wp-includes/version.php 2>/dev/null; then
        WP_READY=true
        break
    fi
    sleep 2
done
if [ "$WP_READY" != true ]; then
    CONFIGURED=false; echo -e \n"[!] WordPress failed to become ready within 180 seconds\n"
else
    echo -e "WordPress container is ready!\n"
fi

echo -e "> Installing WP-CLI inside the container if not already present..."
{ sudo docker exec wordpress_app bash -c "
    if [ ! -f /usr/local/bin/wp ]; then
        curl -fsSL \
        https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
        -o /tmp/wp-cli.phar
        chmod +x /tmp/wp-cli.phar
        mv /tmp/wp-cli.phar /usr/local/bin/wp
    fi
" && echo -e "Done\n"; } || { CONFIGURED=false; echo -e "\n[!] An error occured!\n"; }

echo -e "> Running WordPress core installation (skips if already installed)"
{ sudo docker exec -u www-data wordpress_app bash -c "
    if ! wp core is-installed 2>/dev/null; then
        wp core install \
        --url='http://10.10.3.3:8050' \
        --title='Ko0ler Lab - Wordpress' \
        --admin_user='admin' \
        --admin_password='Ch@nge_tHis_str0ng_ro0T_pasSWorD' \
        --admin_email='admin@kooler.local' \
        --skip-email
    fi
"; } || { CONFIGURED=false; echo -e "\n[!] An error occurred!"; }

echo -e "\n> Installing WP Mail SMTP and pre-configure Mailpit\n"
{ sudo docker exec -u www-data wordpress_app bash -c "
    export WP_CLI_CACHE_DIR=/tmp/wp-cli-cache
    wp plugin install wp-mail-smtp --activate
    wp option update wp_mail_smtp '{
        \"mail\": {
        \"from_email\": \"wordpress@kooler.local\",
        \"from_name\": \"Ko0ler Lab - Wordpress\",
        \"mailer\": \"smtp\",
        \"return_path\": false,
        \"from_email_force\": true,
        \"from_name_force\": true
        },
        \"smtp\": {
        \"host\": \"mailpit\",
        \"port\": 1025,
        \"encryption\": \"none\",
        \"autotls\": false,
        \"auth\": false,
        \"user\": \"\",
        \"pass\": \"\"
        }
    }' --format=json
" && echo -e "Done\n"; } || { CONFIGURED=false; echo -e "\n[!] An error occured!"; }

[ "$CONFIGURED" != true ] && echo -e "\n> WordPress and WP Mail SMTP configuration failed. Some errors occured!\n" || echo -e "\n> WordPress and WP Mail SMTP configured\n"

echo -e "\n[+] REMOVING CREATED CONTAINERS AND CLEAN UP\n"
{
sudo docker stop wordpress_app wordpress_db mailpit_app
sudo docker rm wordpress_app wordpress_db mailpit_app
echo -e "\nDone"
} || { echo -e "\n[!] An error occurred!\n"; }

echo -e "

---------------------------------------
 SETUP COMPLETED... HAPPY HACKING !!!
---------------------------------------

> Run the following command to reload the environment and create new vulnerable containers (deletes currently running ones)

----
{ source ~/.bashrc && { dsf; drf; } 2>/dev/null; fullweb && echo && dp && echo && nnl; } || { echo -e '\\\n[!] An error occurred!'; }
----

"
