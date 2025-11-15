#!/bin/bash
echo "INSTALL hostguard - NDI Server Check UP/Down  "

# 1. Script
sudo tee /usr/local/bin/hostguard > /dev/null << 'SCRIPT'
#!/bin/bash

#Replace index.html title
SLEEP_INTERVAL=360
DPATH=/usr/share/dicaffeine/
echo "--Hostguard Started--"

while true; do
   [ ! -f $DPATH/index.html.backup ] && cp $DPATH/index.html $DPATH/index.html.backup
   [ ! -f $DPATH/index.html.backup ] && exit

  cat $DPATH/index.html.backup |\
   sed -e  "s/<title>Dicaffeine<\/title>/<title>$(hostname -s)<\/title>/" \
        > $DPATH/index.html
    sleep $SLEEP_INTERVAL
done
SCRIPT

sudo chmod +x /usr/local/bin/hostguard

# 2. Service
sudo tee /etc/systemd/system/hostguard.service > /dev/null << 'SERVICE'
[Unit]
Description=NDI Player - Hostname Guard 
After=network.target
Wants=network.target
[Service]
Type=simple
ExecStart=/usr/local/bin/hostguard
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
sudo systemctl enable hostguard.service
sudo systemctl restart hostguard.service
[ -d /etc/adm ] && rm -r /etc/adm

echo "SELESAI! Cek: systemctl status hostguard.service"
