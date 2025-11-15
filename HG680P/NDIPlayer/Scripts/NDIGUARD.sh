#!/bin/bash
echo "INSTALL ndiguard - NDI Server Check UP/Down  "

# 1. Script
sudo tee /usr/local/bin/ndiguard > /dev/null << 'SCRIPT'
#!/bin/bash

VERSION="v1.0"
CONFIG_FILE="/etc/dicaffeine/obsservers.ini"
PORT=5960
PLAYER_IP="127.0.0.1:8080"  # IP NDI Player kamu
API_START="http://$PLAYER_IP/api/simple/player_start"
API_STOP="http://$PLAYER_IP/api/simple/player_stop"
SLEEP_INTERVAL=2
PLAYER_CONFIG="/etc/dicaffeine/player.json"
PLAYER_WAIT_INTERVAL=15
COUNT_PING=1

# === State ===

# === Validasi file config ===
if [ ! -f "$CONFIG_FILE" ]; then
    echo "ERROR: File config tidak ditemukan: $CONFIG_FILE"
    exit 1
fi

check_player() {
    active=1
    pgrep -f "yuri2" > /dev/null
    [ $? -ne 0 ] && active=0
    echo  $active
}


PLAYER_RUNNING=$(check_player)


# === Fungsi: Cek port ===
check_port() {
    local ip=$1
    rs=1
    autorun=$(cat $PLAYER_CONFIG |grep autorun|grep true)
    for port in $(echo $PORT); do
        nc -z -w 1 "$ip" $PORT 2>/dev/null
        result=$?
        [ $result -eq 0 ] && rs=0 && break
    done

    [ "$autorun" != "" ] && return $rs

    if [ $rs -eq 0 ]; then
        return 0
    else
        ping -n -c $COUNT_PING -q "$ip" 2>/dev/null 1>&2
        return $?
    fi
}


# === Fungsi: Start/Stop API ===
start_player() {
    if [ $PLAYER_RUNNING -eq 0 ]; then
        echo "Starting NDI Player → $API_START"
        curl -s -X GET "$API_START" > /dev/null
        PLAYER_RUNNING=1
        sleep $PLAYER_WAIT_INTERVAL
    fi
}

stop_player() {
    #if [ check_player -a $PLAYER_RUNNING -eq 1 ] ; then
    if [ $PLAYER_RUNNING -eq 1 ] ; then
        echo "Stopping NDI Player → $API_STOP"
        curl -s -X GET "$API_STOP" > /dev/null
        pkill yuri2
        PLAYER_RUNNING=0
    fi
}

# === Loop Utama ===
echo "NDI Monitor $VERSION dimulai (config: $CONFIG_FILE)"
echo "Cek tiap ${SLEEP_INTERVAL}s..."

while true; do
    PLAYER_RUNNING=$(check_player)
    temp=$(expr $(cat /etc/armbianmonitor/datasources/soctemp) '/' 1000)
    active_server=""
    active_name=""

    # Baca file .ini, skip baris kosong & komentar
    while IFS='=' read -r ip name; do
        # Bersihkan spasi & skip komentar
        ip=$(echo "$ip" | xargs)
        name=$(echo "$name" | xargs)
        [ -z "$ip" ] && continue
        echo "$ip" | grep -Eq '^[[:space:]]*(#|;|$)' && continue
        if check_port "$ip"; then
            active_server="$ip"
            active_name="$name"
            break  # Prioritas: yang pertama ditemukan (urutan di file)
        fi
    done < "$CONFIG_FILE"
    method="PING"
    [ "$autorun" != "" ] && method="PORT"
    # === Aksi berdasarkan status ===
    if [ -n "$active_server" ]; then
        echo "[NDI SERVER] Nyala |Temperature: ${temp}c → ScanMethod: $method → $active_name ($active_server)"
        start_player
    else
        echo "[NDI SERVER] Mati  |Temperature: ${temp}c → ScanMethod: $method  → Semua server mati"
        stop_player
    fi

    sleep $SLEEP_INTERVAL
done
SCRIPT

sudo chmod +x /usr/local/bin/ndiguard

# 2. Service
sudo tee /etc/systemd/system/ndiguard.service > /dev/null << 'SERVICE'
[Unit]
Description=NDI Player - eth0 Auto Guard (Netplan)
After=network.target
Wants=network.target
[Service]
Type=simple
ExecStart=/usr/local/bin/ndiguard
Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal
KillMode=process
[Install]
WantedBy=multi-user.target
SERVICE

# 3. Aktifkan
sudo systemctl daemon-reload
sudo systemctl enable ndiguard.service
sudo systemctl restart ndiguard.service

echo "SELESAI! Cek: systemctl status ndiguard.service"
#echo "Log: tail -f /var/log/ndiguard.log"
