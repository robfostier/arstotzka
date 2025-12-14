# zeus - External File Upload Server
Ubuntu 24.04.3 Live Server

Name : Technician
Server name : zeus
username : tech
password : Sup1nf0 

Carte réseau :
VMnet8 (NAT)

```bash
tech@zeus:~$ sudo apt update
tech@zeus:~$ sudo apt upgrade -y
```

## Configuration NAT

```bash
tech@zeus:~$ sudo nano /etc/netplan/50-cloud-init.yaml
```

```yaml
ens33:
    dhcp4: false
    addresses: [192.168.197.10/24]
    nameservers:
        addresses: [1.1.1.1, 8.8.8.8]
    routes:
        - to: 0.0.0.0/0
          via: 192.168.197.2
        - to: 10.0.0.0/24
          via: 192.168.197.254
```

```bash
tech@zeus:~$ sudo netplan apply
```

## SFTP

```bash
tech@zeus:~$ sudo apt install openssh-server unzip -y
tech@zeus:~$ sudo systemctl enable ssh
tech@zeus:~$ sudo systemctl start ssh
tech@zeus:~$ sudo adduser immigrant --shell /bin/false --home /srv/sftp/immigrant
tech@zeus:~$ sudo mkdir -p /srv/sftp/immigrant/uploads
tech@zeus:~$ sudo chown root:root /srv/sftp/immigrant
tech@zeus:~$ sudo chmod 755 /srv/sftp/immigrant
tech@zeus:~$ sudo chown immigrant:immigrant /srv/sftp/immigrant/uploads
tech@zeus:~$ sudo nano /etc/ssh/sshd_config
```

``` ini
Include /etc/ssh/sshd_config.d/*.conf

KbdInteractiveAuthentication no

UsePAM yes

X11Forwarding yes
PrintMotd no

AcceptEnv LANG LC_*

Subsystem   sftp    /usr/lib/openssh/sftp-server

Match User immigrant
    ChrootDirectory /srv/sftp/immigrant
    ForceCommand internal-sftp
    AllowTcpForwarding no
    X11Forwarding no
```

```bash
tech@zeus:~$ sudo systemctl restart ssh
```

## Scripts

```bash
tech@zeus:~$ mkdir -p /srv/scripts
```

### - Cleanup

```bash
tech@zeus:~$ sudo nano /srv/scripts/cleanup.sh
```

```bash
#!/bin/bash
set -euo pipefail

UPLOAD_DIR="/srv/sftp/immigrant/uploads"
VALID_DIR="/srv/sftp/immigrant/valid"
INVALID_DIR="/srv/sftp/immigrant/invalid"
LOG="/var/log/cleanup.log"

mkdir -p "$VALID_DIR" "$INVALID_DIR"
touch "$LOG"

for archive in "$UPLOAD_DIR"/*.zip; do
    [ -e "$archive" ] || exit 0

    ID=$(basename "$archive" .zip)
    TMPDIR=$(mktemp -d)

    if ! unzip -qq "$archive" -d "$TMPDIR"; then
        echo "[REJECT] $ID : unzip failed" | tee -a "$LOG"
        mv "$archive" "$INVALID_DIR"
        rm -rf "$TMPDIR"
        continue
    fi

    # File presence check
    TXT=$(find "$TMPDIR" -type f -name "*.txt")
    PDFS=$(find "$TMPDIR" -type f -name "*.pdf")

    if [ -z "$TXT" ]; then
        echo "[REJECT] $ID : missing .txt" | tee -a "$LOG"
        mv "$archive" "$INVALID_DIR"
        rm -rf "$TMPDIR"
        continue
    fi

    if [ -z "$PDFS" ]; then
        echo "[REJECT] $ID : missing .pdf" | tee -a "$LOG"
        mv "$archive" "$INVALID_DIR"
        rm -rf "$TMPDIR"
        continue
    fi

    # ID check
    if ! find "$TMPDIR" -type f ! -name "*$ID*" | grep -q .; then
        mv "$archive" "$VALID_DIR"
        echo "[OK] $ID : archive valid" | tee -a "$LOG"
    else
        echo "[REJECT] $ID : ID mismatch in filenames" | tee -a "$LOG"
        mv "$archive" "$INVALID_DIR"
    fi

    rm -rf "$TMPDIR"
done
```

```bash
tech@zeus:~$ sudo nano /etc/systemd/system/cleanup.service
```

```ini
[Unit]
Description=Immigrant archive cleanup

[Service]
Type=oneshot
ExecStart=/srv/scripts/cleanup.sh
```

```bash
tech@zeus:~$ sudo nano /etc/systemd/system/cleanup.timer
```

```ini
[Unit]
Description=Run cleanup every 2 minutes

[Timer]
OnBootSec=2min
OnUnitActiveSec=2min

[Install]
WantedBy=timers.target
```

### - Transfer

```bash
tech@zeus:~$ sudo nano /srv/scripts/transfer.sh
```

```bash
#!/bin/bash
set -euo pipefail

VALID_DIR="/srv/sftp/immigrant/valid"
INTERNAL_USER="tech"
INTERNAL_HOST="10.0.0.20"
INTERNAL_PATH="/srv/raid5/share/cases/pending"
LOG="/var/log/transfer.log"

touch "$LOG"

for file in "$VALID_DIR"/*.zip; do
    [ -e "$file" ] || exit 0

    BASENAME=$(basename "$file")

    if scp "$file" "$INTERNAL_USER@$INTERNAL_HOST:$INTERNAL_PATH/"; then
        echo "[TRANSFER] $BASENAME transferred" | tee -a "$LOG"

        echo "New immigration case received: $BASENAME" \
        | mail -s "New case pending validation" inspector@grestin.local

        rm -f "$file"
    else
        echo "[ERROR] Failed to transfer $BASENAME" | tee -a "$LOG"
    fi
done
```

```bash
tech@zeus:~$ sudo nano /etc/systemd/system/transfer.service
```

```ini
[Unit]
Description=Transfer valid archives to internal server
After=cleanup.service

[Service]
Type=oneshot
ExecStart=/srv/scripts/transfer.sh
```

```bash
tech@zeus:~$ sudo nano /etc/systemd/system/transfer.timer
```

```ini
[Unit]
Description=Run transfer every 2 minutes

[Timer]
OnBootSec=3min
OnUnitActiveSec=2min

[Install]
WantedBy=timers.target
```

### - Configuration timers

```bash
tech@zeus:~$ sudo chmod +x /srv/scripts/*.sh
tech@zeus:~$ sudo systemctl daemon-reload
tech@zeus:~$ sudo systemctl enable --now cleanup.timer transfer.timer
```

