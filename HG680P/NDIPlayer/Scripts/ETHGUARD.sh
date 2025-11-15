#!/bin/bash
echo "INSTALL eth0guard - NDI eth0 guard "

# 1. Script
sudo tee /usr/local/bin/eth0guard > /dev/null << 'SCRIPT'
#!/bin/bash
INTERFACE="eth0"
LOG="/var/log/eth0guard.log"
MAX_RETRY=10			# Kisaran 1 menit
RETRY_DELAY=120
##Air10 - V4 Static IP
MONITORIP="10.10.104.250"
GATEWAY=$(ip route | grep default | awk '{print $3}' | head -n 1)

[[ ! -f "$LOG" ]] && touch "$LOG" && chmod 644 "$LOG"

[[ -z "$GATEWAY" ]] && $GATEWAY=$MONITORIP

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> $LOG; }
log "=== eth0-guard STARTED ==="
while true; do
    if ! ip link show $INTERFACE >/dev/null 2>&1; then
        log "ERROR: $INTERFACE tidak ditemukan! Tunggu..."
        sleep 5; continue
    fi

    if ! ping -c 3 -W 1 "$GATEWAY" > /dev/null 2>&1; then
	log "ping to gateway $GATEWAY is DOWN. ipdown ->ifup."
        ifdown $INTERFACE 2>/dev/null
	sleep 1
        ifup $INTERFACE 2>/dev/null
        sleep $RETRY_DELAY
    fi

    if ip link show $INTERFACE | grep -q "state DOWN"; then
        log "eth0 DOWN → mulai retry..."
        for ((i=1; i<=MAX_RETRY; i++)); do
            log "  Retry [$i|$MAX_RETRY]: down → up → ifup-ifdown"
            ifdown $INTERFACE 2>/dev/null
            sleep 1
            ifup $INTERFACE 2>/dev/null
            sleep $RETRY_DELAY
            if ip link show $INTERFACE | grep -q "state UP"; then
                log "eth0 UP! Koneksi berhasil dipulihkan."
                break
            fi
        done
        if [[ $i -gt $MAX_RETRY ]] && ! ip link show $INTERFACE | grep -q "state UP"; then
            log "CRITICAL: eth0 GAGAL UP setelah $MAX_RETRY retry!"
	    #/usr/bin/sync
            log "CRITICAL: SYNC BEFORE REBOOT!"
	    #/usr/sbin/reboot
        fi
    fi
    sleep 3
done
SCRIPT

sudo chmod +x /usr/local/bin/eth0guard

# 2. Service
sudo tee /etc/systemd/system/eth0guard.service > /dev/null << 'SERVICE'
[Unit]
Description=NDI Player - eth0 Auto Guard (Netplan)
After=network.target
Wants=network.target
[Service]
Type=simple
ExecStart=/usr/local/bin/eth0guard
Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal
KillMode=process
[Install]
WantedBy=multi-user.target
SERVICE

# 3. Aktifkan
sudo cp /dev/null /var/log/eth0guard.log
sudo systemctl daemon-reload
sudo systemctl enable eth0guard.service
sudo systemctl restart eth0guard.service

echo "SELESAI! Cek: systemctl status eth0guard.service"
echo "Log: tail -f /var/log/eth0guard.log"
