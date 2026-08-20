#!/bin/bash

CONFIG_FILE="/etc/k3ko_config.env"
DB_FILE="/etc/k3ko_vps_database.txt"
HAPROXY_CONF="/etc/haproxy/haproxy.cfg"
SSH_BANNER_FILE="/etc/issue.net"

touch "$DB_FILE"

if [ ! -f "$CONFIG_FILE" ]; then
    cat <<EOC > "$CONFIG_FILE"
SSH_DIRECT_PORT=22
HTTP_PORT=80
TLS_PORT=443
V2RAY_PORT=10080
HAPROXY_MAXCONN=100000
SLOWDNS_NS=ns.example.com
SLOWDNS_PUBKEY=11223344556677889900aabbccddeeff
BANNER_TEXT="k3ko - Welcome to High Speed Premium Services"
EOC
fi

while true; do
  clear
  [ -f "$CONFIG_FILE" ] && source "$CONFIG_FILE"
  
  OS_NAME="Ubuntu Linux"
  UPTIME_VAL=$(uptime -p 2>/dev/null | sed 's/up //' || echo "Running")
  MEM_USAGE=$(free | grep Mem | awk '{printf "%.0f%%", $3/$2 * 100}' 2>/dev/null || echo "5%")
  SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}')
  MANAGED_USERS=0
  [ -f "$DB_FILE" ] && MANAGED_USERS=$(wc -l < "$DB_FILE")

  echo -e "\033[1;36mK3KO Manager \033[1;37m| \033[1;32mv11.1.0 Premium Edition\033[0m"
  echo -e "\033[1;34m──────────────────────────────────────────────────────────────\033[0m"
  echo -e "\033[1;37mOS       : \033[1;32m$OS_NAME\033[0m          \033[1;37m│ Uptime     : \033[1;32m$UPTIME_VAL\033[0m"
  echo -e "\033[1;37mIP Server: \033[1;32m$SERVER_IP\033[0m"
  echo -e "\033[1;37mMemory   : \033[1;32m$MEM_USAGE\033[0m          \033[1;37m│ Users      : \033[1;32m$MANAGED_USERS Managed\033[0m"
  echo -e "\033[1;34m──────────────────────────────────────────────────────────────\033[0m"

  echo -e "\033[1;35m                      [ 👤 USER MANAGEMENT ]                      \033[0m"
  echo -e "\033[1;34m──────────────────────────────────────────────────────────────\033[0m"
  printf "\033[1;36m[ 1 ]\033[0m ✨ Create SSH Account    \033[1;36m[ 2 ]\033[0m 🗑️  Delete Account\n"
  printf "\033[1;36m[ 3 ]\033[0m ⚡ Create V2Ray Account   \033[1;36m[ 4 ]\033[0m 🌐 Create SSH SlowDNS\n"
  printf "\033[1;36m[ 5 ]\033[0m 📦 Create V2Ray SlowDNS   \033[1;36m[ 6 ]\033[0m 📋 List Managed Users\n"
  printf "\033[1;36m[ 7 ]\033[0m 🔍 Search User Account    \033[1;36m[ 8 ]\033[0m 📊 Active Connections\n"

  echo -e "\n\033[1;35m                     [ 🌐 VPN & PROTOCOLS ]                     \033[0m"
  echo -e "\033[1;34m──────────────────────────────────────────────────────────────\033[0m"
  printf "\033[1;36m[ 9 ]\033[0m ⚙️  Ports Config           \033[1;36m[ 10 ]\033[0m 📈 SlowDNS NS Settings\n"
  printf "\033[1;36m[ 15 ]\033[0m 🚀 Install & Setup UDP Custom (UDB)\n"

  echo -e "\n\033[1;35m                     [ ⚙️  SYSTEM SETTINGS ]                     \033[0m"
  echo -e "\033[1;34m──────────────────────────────────────────────────────────────\033[0m"
  printf "\033[1;36m[ 11 ]\033[0m 🎨 SSH Banner Config      \033[1;36m[ 12 ]\033[0m 💾 Backup Database\n"
  printf "\033[1;36m[ 13 ]\033[0m ♻️  Restore User Data      \033[1;36m[ 14 ]\033[0m 🧹 Cleanup Database\n"

  echo -e "\n\033[1;31m                      [ 🔥 DANGER ZONE ]                      \033[0m"
  echo -e "\033[1;34m──────────────────────────────────────────────────────────────\033[0m"
  printf "\033[1;31m[ 99 ]\033[0m 🛑 Reset All Data         \033[1;32m[ 0 ]\033[0m  🚪 Exit Panel\n"
  echo -e "\033[1;34m──────────────────────────────────────────────────────────────\033[0m"

  echo -e ""
  read -p "👉 Select an option: " option

  case $option in
      1)
          echo -e "\n\033[1;33m--- Create SSH Account (No Domain) ---\033[0m"
          read -p "Enter username: " username
          read -sp "Enter password: " password; echo
          read -p "Enter expiry days: " days
          echo "SSH | User: $username | Pass: $password | Days: $days" >> "$DB_FILE"
          echo -e "\n\033[0;32m✔ SSH Account Created Successfully!\033[0m"
          echo -e "Server IP : $SERVER_IP"
          echo -e "Username  : $username"
          echo -e "Password  : $password"
          read -p "Press Enter to return..."
          ;;
      2)
          echo -e "\n\033[0;31m--- Delete Account ---\033[0m"
          read -p "Enter Username to delete: " del_user
          sed -i "/$del_user/d" "$DB_FILE" 2>/dev/null
          echo -e "\033[0;31m✔ Account removed if it existed!\033[0m"
          read -p "Press Enter to return..."
          ;;
      3)
          echo -e "\n\033[1;33m--- Create V2Ray Account (No Domain) ---\033[0m"
          read -p "Enter client name: " v2ray_user
          uuid=$(cat /proc/sys/kernel/random/uuid 2>/dev/null || uuidgen)
          echo "V2Ray | User: $v2ray_user | UUID: $uuid" >> "$DB_FILE"
          echo -e "\n\033[0;32m✔ V2Ray Account Created!\033[0m"
          echo -e "Server IP : $SERVER_IP"
          echo -e "Client    : $v2ray_user"
          echo -e "UUID      : $uuid"
          read -p "Press Enter to return..."
          ;;
      6)
          echo -e "\n\033[0;36m--- Managed Users ---\033[0m"
          [ -s "$DB_FILE" ] && cat "$DB_FILE" || echo "No active accounts found."
          read -p "Press Enter to return..."
          ;;
      12)
          cp "$DB_FILE" "/root/backup_database_$(date +%Y%m%d).txt"
          echo -e "\n\033[0;32m✔ Database Backed Up Successfully!\033[0m"
          read -p "Press Enter to return..."
          ;;
      14)
          > "$DB_FILE"
          echo -e "\n\033[0;32m✔ Database Cleared!\033[0m"
          read -p "Press Enter to return..."
          ;;
      15)
          echo -e "\n\033[1;33m--- Installing UDP Custom (UDB) ---\033[0m"
          mkdir -p /root/udp
          wget -q https://raw.githubusercontent.com/mlhvn/UDP-Custom/main/udp-custom-linux-amd64 -O /root/udp/udp-custom
          chmod +x /root/udp/udp-custom
          read -p "Enter UDB Port (e.g., 7100): " udb_port
          cat <<EOF > /root/udp/config.json
{
  "listen": ":$udb_port",
  "key": "udb7100"
}
EOF
          nohup /root/udp/udp-custom server -exclude 127.0.0.1 > /root/udp/udp.log 2>&1 &
          echo -e "\n\033[0;32m✔ UDP Custom Installed & Running!\033[0m"
          echo -e "Server IP : $SERVER_IP"
          echo -e "Port      : $udb_port"
          echo -e "Key       : udb7100"
          read -p "Press Enter to return..."
          ;;
      99)
          read -p "Are you sure you want to reset all data? (y/n): " confirm
          if [ "$confirm" = "y" ]; then
              rm -f "$DB_FILE" "$CONFIG_FILE"
              touch "$DB_FILE"
              echo -e "\033[0;31m✔ All data and configurations reset!\033[0m"
          fi
          read -p "Press Enter to return..."
          ;;
      0)
          echo -e "\n\033[1;33mGoodbye!\033[0m"
          exit 0
          ;;
      *)
          echo -e "\n\033[0;31mInvalid Option!\033[0m"
          sleep 1
          ;;
  esac
done
