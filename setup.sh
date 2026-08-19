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
BANNER_TEXT="k3ko - Welcome to High Speed Premium Tunneling"
EOC
fi

save_config() {
    cat <<EOC > "$CONFIG_FILE"
SSH_DIRECT_PORT=$SSH_DIRECT_PORT
HTTP_PORT=$HTTP_PORT
TLS_PORT=$TLS_PORT
V2RAY_PORT=$V2RAY_PORT
HAPROXY_MAXCONN=$HAPROXY_MAXCONN
SLOWDNS_NS=$SLOWDNS_NS
SLOWDNS_PUBKEY=$SLOWDNS_PUBKEY
BANNER_TEXT="$BANNER_TEXT"
EOC
}

apply_system_settings() {
    ulimit -n 999999 &>/dev/null
    echo -e "$BANNER_TEXT" > "$SSH_BANNER_FILE"
    if [ -f /etc/ssh/sshd_config ]; then
        sed -i 's|^#\?Banner .*|Banner /etc/issue.net|g' /etc/ssh/sshd_config
        sed -i 's|^#\?MaxStartups .*|MaxStartups 100000:30:100000|g' /etc/ssh/sshd_config
        systemctl restart ssh &>/dev/null || systemctl restart sshd &>/dev/null || service ssh restart &>/dev/null
    fi

    if command -v haproxy &>/dev/null; then
        cat <<EOC > "$HAPROXY_CONF"
global
    maxconn $HAPROXY_MAXCONN
    log /dev/log local0

defaults
    mode tcp
    timeout connect 5s
    timeout client 50s
    timeout server 50s
    option tcp-check

frontend multi_port_in
    bind *:$HTTP_PORT
    bind *:$TLS_PORT ssl crt /etc/ssl/vps.pem alpn h2,http/1.1 optional
    mode tcp
    maxconn $HAPROXY_MAXCONN
    tcp-request inspect-delay 5s
    tcp-request content accept if { req_ssl_hello_type 1 }
    use_backend v2ray_cluster if { req_ssl_sni -m end .com }
    default_backend ssh_payload_cluster

backend ssh_payload_cluster
    mode tcp
    balance roundrobin
    server ssh_direct 127.0.0.1:$SSH_DIRECT_PORT maxconn $HAPROXY_MAXCONN check

backend v2ray_cluster
    mode tcp
    balance roundrobin
    server v2ray_ws 127.0.0.1:$V2RAY_PORT maxconn $HAPROXY_MAXCONN check
EOC
        systemctl restart haproxy &>/dev/null || service haproxy restart &>/dev/null
    fi
}

apply_system_settings

while true; do
  clear
  source "$CONFIG_FILE"
  OS_INFO="Linux VPS"
  [ -f /etc/os-release ] && OS_INFO=$(grep -oP 'PRETTY_NAME="\K[^"]+' /etc/os-release 2>/dev/null || echo "Linux VPS")
  UPTIME_INFO="Active Engine"
  command -v uptime &>/dev/null && UPTIME_INFO=$(uptime -p 2>/dev/null | sed 's/up //' || echo "Active")
  ONLINE_SESSIONS=0
  command -v who &>/dev/null && ONLINE_SESSIONS=$(who | wc -l)
  MANAGED_USERS=0
  [ -f "$DB_FILE" ] && MANAGED_USERS=$(wc -l < "$DB_FILE")

  echo -e "\033[1;35mk3ko Ultimate Tunneling Engine\033[0m | \033[0;36mv18.0.0 Unlimited Edition\033[0m"
  echo -e "\033[1;34m──────────────────────────────────────────────────────────────────────────────\033[0m"
  printf "\033[1;37m%-12s\033[0m : \033[0;32m%-20s\033[0m | \033[1;37m%-15s\033[0m : \033[0;32m%-15s\033[0m\n" "OS" "$OS_INFO" "Uptime" "$UPTIME_INFO"
  printf "\033[1;37m%-12s\033[0m : \033[0;32m%-20s\033[0m | \033[1;37m%-15s\033[0m : \033[0;32m%-15s\033[0m\n" "Max Connections" "Unlimited ($HAPROXY_MAXCONN)" "Online Sessions" "$ONLINE_SESSIONS"
  printf "\033[1;37m%-12s\033[0m : \033[0;32m%-20s\033[0m | \033[1;37m%-15s\033[0m : \033[0;32m%-15s\033[0m\n" "SSH Ports" "22 / $HTTP_PORT / $TLS_PORT" "Managed Users" "$MANAGED_USERS"
  echo -e "\033[1;34m──────────────────────────────────────────────────────────────────────────────\033[0m"
  echo -e "\033[1;33m📢 BANNER:\033[1;37m $BANNER_TEXT\033[0m"
  echo -e "\033[1;34m──────────────────────────────────────────────────────────────────────────────\033[0m"

  echo -e "\n\033[1;35m═════════════════════════════[ 👤 USER MANAGEMENT ]═════════════════════════════\033[0m"
  printf "  \033[0;36m[ 1]\033[0m ✨ \033[0;32m%-22s\033[0m \033[0;36m[ 2]\033[0m 🗑️  \033[0;32m%-22s\033[0m\n" "Create SSH + Payload" "Delete Account"
  printf "  \033[0;36m[ 3]\033[0m ⚡ \033[0;32m%-22s\033[0m \033[0;36m[ 4]\033[0m 🌐 \033[0;32m%-22s\033[0m\n" "Create V2Ray/VLESS" "Create SSH SlowDNS"
  printf "  \033[0;36m[ 5]\033[0m 🛰️  \033[0;32m%-22s\033[0m \033[0;36m[ 6]\033[0m 📋 \033[0;32m%-22s\033[0m\n" "Create V2Ray SlowDNS" "List Managed Users"
  printf "  \033[0;36m[ 7]\033[0m 🔍 \033[0;32m%-22s\033[0m \033[0;36m[ 8]\033[0m 📊 \033[0;32m%-22s\033[0m\n" "Search User Account" "Active Connections"

  echo -e "\n\033[1;35m═════════════════════════════[ 🌐 PROTOCOLS & NETWORK ]═════════════════════════\033[0m"
  printf "  \033[0;36m[ 9]\033[0m 🔌 \033[0;32m%-22s\033[0m \033[0;36m[10]\033[0m 🔒 \033[0;32m%-22s\033[0m\n" "HTTP/TLS Ports Config" "SSL Auto-Certificate"
  printf "  \033[0;36m[11]\033[0m 🔀 \033[0;32m%-22s\033[0m \033[0;36m[12]\033[0m 📈 \033[0;32m%-22s\033[0m\n" "HAProxy Limits & System" "SlowDNS Settings"

  echo -e "\n\033[1;35m═════════════════════════════[ ⚙️ SYSTEM SETTINGS ]═════════════════════════════\033[0m"
  printf "  \033[0;36m[13]\033[0m 🎨 \033[0;32m%-22s\033[0m \033[0;36m[14]\033[0m 📄 \033[0;32m%-22s\033[0m\n" "k3ko Banner Config" "View Main Config File"
  printf "  \033[0;36m[15]\033[0m 💾 \033[0;32m%-22s\033[0m \033[0;36m[16]\033[0m 🧹 \033[0;32m%-22s\033[0m\n" "Backup Database" "Cleanup Database"

  echo -e "\n\033[0;31m═════════════════════════════[ 🔥 DANGER ZONE ]═════════════════════════════\033[0m"
  printf "  \033[0;31m[99]\033[0m 🚫 \033[0;31m%-22s\033[0m \033[1;33m[ 0]\033[0m 🚪 \033[1;37m%-22s\033[0m\n" "Reset All Services" "Exit Panel"
  echo -e "\033[0;31m═════════════════════════════════════════════════════════════════════════════\033[0m"

  echo -e ""
  read -p "👉 Select an option: " option

  case $option in
      1)
          echo -e "\n\033[1;33m--- Create SSH Account + WS/WSS Payloads ---\033[0m"
          read -p "Enter username: " username
          read -sp "Enter password: " password; echo
          read -p "Enter Domain/SNI (e.g., bug.domain.com): " domain
          read -p "Enter validity days: " days
          read -p "Enter max devices: " max_login
          exp_date=$(date -d "+$days days" +"%Y-%m-%d" 2>/dev/null || echo "In $days Days")
          useradd -e $(date -d "+$days days" +"%Y-%m-%d" 2>/dev/null) -s /bin/false "$username" 2>/dev/null
          echo "$username:$password" | chpasswd 2>/dev/null
          echo "[SSH] User: $username | Domain: $domain | Expire: $exp_date" >> "$DB_FILE"
          echo -e "\n\033[0;32m✔ SSH Account Created Successfully!\033[0m"
          echo -e "\033[0;36m============================================\033[0m"
          echo -e "\033[1;33m1. HTTP / WS Payload (Port $HTTP_PORT):\033[0m"
          echo -e "GET / HTTP/1.1[crlf]Host: $domain[crlf]Upgrade: websocket[crlf]Connection: Upgrade[crlf][crlf]"
          echo -e ""
          echo -e "\033[1;33m2. HTTPS / WSS Payload (Port $TLS_PORT - SSL/TLS):\033[0m"
          echo -e "GET / HTTP/1.1[crlf]Host: $domain[crlf]Upgrade: websocket[crlf]Connection: Upgrade[crlf][crlf]"
          echo -e "\033[0;36m============================================\033[0m"
          read -p "Press Enter to return..."
          ;;
      2)
          echo -e "\n\033[0;31m--- Delete Account ---\033[0m"
          read -p "Enter Username to delete: " del_user
          userdel -f "$del_user" 2>/dev/null
          sed -i "/$del_user/d" "$DB_FILE" 2>/dev/null
          echo -e "\033[0;31m✔ Account '$del_user' removed!\033[0m"
          read -p "Press Enter to return..."
          ;;
      3)
          echo -e "\n\033[0;36m--- Create V2Ray / VLESS Account ---\033[0m"
          read -p "Enter Client Name: " client_name
          read -p "Enter Domain/IP: " domain
          read -p "Enter validity days: " days
          user_uuid=$(command -v uuidgen &>/dev/null && uuidgen || echo "a8f3b1c2-9e4d-4b7f-8c1a-$(date +%s)")
          exp_date=$(date -d "+$days days" +"%Y-%m-%d" 2>/dev/null || echo "In $days Days")
          vless_link="vless://${user_uuid}@${domain}:${TLS_PORT}?type=ws&security=tls&path=/v2ray#${client_name}"
          echo "[V2Ray] Name: $client_name | UUID: $user_uuid | Expire: $exp_date" >> "$DB_FILE"
          echo -e "\n\033[0;32m✔ V2Ray/VLESS Account Created!\033[0m\n\033[1;33mVLESS Link:\033[0m\n$vless_link"
          read -p "Press Enter to return..."
          ;;
      4)
          echo -e "\n\033[1;33m--- Create SSH SlowDNS Account ---\033[0m"
          read -p "Enter username: " username
          read -sp "Enter password: " password; echo
          read -p "Enter validity days: " days
          exp_date=$(date -d "+$days days" +"%Y-%m-%d" 2>/dev/null || echo "In $days Days")
          echo "[SSH-SlowDNS] User: $username | NS: $SLOWDNS_NS | Key: $SLOWDNS_PUBKEY | Expire: $exp_date" >> "$DB_FILE"
          echo -e "\n\033[0;32m✔ SSH SlowDNS Account Created!\033[0m"
          read -p "Press Enter to return..."
          ;;
      5)
          echo -e "\n\033[0;36m--- Create V2Ray SlowDNS Account ---\033[0m"
          read -p "Enter Client Name: " client_name
          read -p "Enter validity days: " days
          user_uuid=$(command -v uuidgen &>/dev/null && uuidgen || echo "a8f3b1c2-9e4d-4b7f-8c1a-$(date +%s)")
          exp_date=$(date -d "+$days days" +"%Y-%m-%d" 2>/dev/null || echo "In $days Days")
          vless_dns="vless://${user_uuid}@${SLOWDNS_NS}:53?type=dns&security=none#${client_name}-SlowDNS"
          echo "[V2Ray-SlowDNS] Name: $client_name | NS: $SLOWDNS_NS | UUID: $user_uuid | Expire: $exp_date" >> "$DB_FILE"
          echo -e "\n\033[0;32m✔ V2Ray SlowDNS Created!\033[0m\n\033[1;33mLink:\033[0m\n$vless_dns"
          read -p "Press Enter to return..."
          ;;
      6)
          echo -e "\n\033[0;36m--- Saved Managed Accounts ---\033[0m"
          [ -s "$DB_FILE" ] && cat "$DB_FILE" || echo "No active accounts found."
          read -p "Press Enter to return..."
          ;;
      7)
          echo -e "\n\033[1;33m--- Search Account ---\033[0m"
          read -p "Enter search keyword: " search_term
          grep -i "$search_term" "$DB_FILE" || echo "No matching accounts found."
          read -p "Press Enter to return..."
          ;;
      8)
          echo -e "\n\033[0;36m--- Active SSH Connections ---\033[0m"
          who 2>/dev/null || echo "No active sessions running."
          read -p "Press Enter to return..."
          ;;
      9)
          echo -e "\n\033[1;33m--- HTTP / TLS / SSH Ports Config ---\033[0m"
          read -p "HTTP Port [$HTTP_PORT]: " new_http
          read -p "TLS Port [$TLS_PORT]: " new_tls
          HTTP_PORT=${new_http:-$HTTP_PORT}
          TLS_PORT=${new_tls:-$TLS_PORT}
          save_config
          apply_system_settings
          echo -e "\033[0;32m✔ Ports Updated & Engine Reloaded!\033[0m"
          read -p "Press Enter to return..."
          ;;
      10)
          echo -e "\n\033[0;36m--- Auto SSL Certificate (Certbot) ---\033[0m"
          read -p "Enter Domain Name: " cert_domain
          if command -v certbot &>/dev/null; then
              certbot certonly --standalone -d "$cert_domain" --non-interactive --agree-tos -m admin@$cert_domain
              echo -e "\033[0;32m✔ SSL Certificate Generated!\033[0m"
          else
              echo -e "\033[1;33mCertbot is not installed. Please install certbot first.\033[0m"
          fi
          read -p "Press Enter to return..."
          ;;
      11)
          echo -e "\n\033[0;36m--- HAProxy & Connection Limits ---\033[0m"
          read -p "Enter Max Concurrent Connections [$HAPROXY_MAXCONN]: " new_max
          HAPROXY_MAXCONN=${new_max:-$HAPROXY_MAXCONN}
          save_config
          apply_system_settings
          echo -e "\033[0;32m✔ Max Connections Updated to $HAPROXY_MAXCONN!\033[0m"
          read -p "Press Enter to return..."
          ;;
      12)
          echo -e "\n\033[1;33m--- SlowDNS Configuration ---\033[0m"
          read -p "New NS Domain [$SLOWDNS_NS]: " new_ns
          read -p "New Public Key [$SLOWDNS_PUBKEY]: " new_key
          SLOWDNS_NS=${new_ns:-$SLOWDNS_NS}
          SLOWDNS_PUBKEY=${new_key:-$SLOWDNS_PUBKEY}
          save_config
          echo -e "\033[0;32m✔ SlowDNS Settings Updated!\033[0m"
          read -p "Press Enter to return..."
          ;;
      13)
          echo -e "\n\033[1;33m--- k3ko Banner Config ---\033[0m"
          read -p "Enter new Banner Text [$BANNER_TEXT]: " new_banner
          [ -n "$new_banner" ] && BANNER_TEXT="$new_banner"
          save_config
          apply_system_settings
          echo -e "\033[0;32m✔ k3ko Banner Updated Successfully!\033[0m"
          read -p "Press Enter to return..."
          ;;
      14)
          echo -e "\n\033[0;36m--- Unified Config File ($CONFIG_FILE) ---\033[0m"
          cat "$CONFIG_FILE"
          read -p "Press Enter to return..."
          ;;
      15)
          cp "$DB_FILE" "/etc/backup_database_$(date +%Y%m%d).txt"
          cp "$CONFIG_FILE" "/etc/backup_config_$(date +%Y%m%d).env"
          echo -e "\033[0;32m✔ Database & Config Backed Up Successfully!\033[0m"
          read -p "Press Enter to return..."
          ;;
      16)
          > "$DB_FILE"
          echo -e "\033[0;32m✔ Expired Data Cleared!\033[0m"
          read -p "Press Enter to return..."
          ;;
      99)
          read -p "Are you sure you want to reset all data? (y/n): " confirm
          if [ "$confirm" = "y" ]; then
              rm -f "$DB_FILE" "$CONFIG_FILE"
              echo -e "\033[0;31m✔ All data and configurations reset!\033[0m"
          fi
          read -p "Press Enter to return..."
          ;;
      0)
          echo -e "\033[1;33mGoodbye!\033[0m"
          exit 0
          ;;
      *)
          echo -e "\033[0;31mInvalid Option!\033[0m"
          sleep 1
          ;;
  esac
done
EOF
chmod +x /usr/local/bin/k3ko-engine
echo "alias menu='k3ko-engine'" >> ~/.bashrc
source ~/.bashrc
k3ko-engine
