# zeus - External File Upload Server
Ubuntu 24.04.3 Live Server

Name : Technician
Server name : zeus
username : tech
password : Sup1nf0 

cartes réseau :
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
tech@zeus:~$ mkdir -p /srv/sftp/immigrant/scripts
```

```bash
#!/bin/bash
UPLOAD_DIR="/srv/sftp/immigrant/uploads"
VALID_DIR="/srv/sftp/immigrant/valid"
INVALID_DIR="/srv/sftp/immigrant/invalid"

for archive in "$UPLOAD_DIR"/*.zip; do
    [ -e "$archive" ] || continue

    ID=$(basename "$archive" .zip)
    TMPDIR=$(mktemp -d)
    unzip -q "$archive" -d "$TMPDIR"

    if ! ls "$TMPDIR"/*.txt >/dev/null 2>&1; then
        mv "$archive" "$INVALID_DIR"
        echo "[REJECT] $ID : can't find .txt"
        rm -r "$TMPDIR"
        continue
    fi

    if ! ls "$TMPDIR"/*.pdf >/dev/null 2>&1; then
        mv "$archive" "$INVALID_DIR"
        echo "[REJECT] $ID : can't find .pdf"
        rm -r "$TMPDIR"
        continue
    fi

    mv "$archive" "$VALID_DIR"
    echo "[OK] $ID : valid archive"

    rm -r "$TMPDIR"
done
```

```bash
#!/bin/bash
VALID_DIR="/srv/sftp/immigrant/valid"
INTERNAL_SERVER="tech@grestin.local@10.0.0.20"
INTERNAL_PATH="/srv/cases/pending"

for file in "$VALID_DIR"/*.zip; do
    [ -e "$file" ] || continue

    scp "$file" "$INTERNAL_SERVER:$INTERNAL_PATH"

    echo "New case : $(basename "$file")" \
    | mail -s "New case" inspector@grestin.local

    rm "$file"
    echo "[TRANSFER] $(basename "$file") transfered to internal server."
done
```

