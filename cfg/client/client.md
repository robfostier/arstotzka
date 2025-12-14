# Station-001 - Client
Ubuntu 24.04.3 Desktop

Name : Technician
Desktop name : station-001
username : tech
password : Sup1nf0 

Carte réseau :
VMnet10 (host-only) : 10.0.0.0/24

```bash
tech@station-001:~$ sudo apt update
tech@station-001:~$ sudo apt upgrade -y
tech@station-001:~$ sudo apt install open-vm-tools -y
```

## Configuration Active Directory

```bash
tech@station-001:~$ sudo nano /etc/hosts
```

```
127.0.0.1 localhost
10.0.0.10 hermes.grestin.local hermes
```

```bash
tech@station-001:~$ sudo nano /etc/resolv.conf
```

```
nameserver 10.0.0.10
```

```bash
tech@station-001:~$ sudo apt install realmd sssd adcli samba-common-bin krb5-user packagekit -y
tech@station-001:~$ kinit Administrator
tech@station-001:~$ klist
tech@station-001:~$ sudo realm join --user=Administrator GRESTIN.LOCAL
tech@station-001:~$ sudo nano /etc/pam.d/common-session
```

```text
session required        pam_mkhomedir.so skel=/etc/skel/ umask=0077  
```

```bash
tech@station-001:~$ sudo systemctl restart sssd
```

## Mount NAS

```bash
tech@grestin.local@station-001:~$ sudo apt install nfs-common -y
tech@grestin.local@station-001:~$ sudo mkdir -p /mnt/nas
tech@grestin.local@station-001:~$ sudo nano /etc/fstab
```

```text
10.0.0.20:/srv/raid5/share /mnt/nas nfs defaults,_netdev 0 0
```

```bash
tech@grestin.local@station-001:~$ systemctl daemon-reload
tech@grestin.local@station-001:~$ sudo mount -a
```

## Scripts

```bash
tech@grestin.local@station-001:~$ sudo nano /mnt/nas/scripts/inspector-tools/case.sh"
```

```bash
#!/bin/bash

ACTION="$1"
CASE="$2"
ID="$3"
BASE="/mnt/nas/cases"
LOG="$BASE/cases.log"

if [ -z "$ACTION" ] || [ -z "$CASE" ] || [ -z "$ID" ]; then
  echo "Usage: ./case.sh <accept|reject> <case.zip> <ID>"
  exit 1
fi

case "$ACTION" in
  accept)
    DEST="accepted"
    STATUS="ACCEPTED"
    ;;
  reject)
    DEST="rejected"
    STATUS="REJECTED"
    ;;
  *)
    echo "Usage: ./case.sh <accept|reject> <case.zip> <ID>"
    exit 1
    ;;
esac

mv "$BASE/pending/$CASE" "$BASE/$DEST/" || {
  echo "Error: cannot move $CASE"
  exit 1
}

echo "$(date) $STATUS , ID $ID $CASE by $USER" >> "$LOG"

echo "$(date) $STATUS , ID $ID $CASE by $USER"
exit 0
```

```bash
tech@grestin.local@station-001:~$ sudo nano /mnt/nas/scripts/inspector-tools/search.sh"
```

```bash
#!/bin/bash

ID="$1"
LOG="/mnt/nas/cases/cases.log"

if [ -z "$ID" ]; then
  echo "Usage: ./search.sh <ID>"
  exit 1
fi

if grep -q "REJECTED , ID $ID" "$LOG"; then
  echo "DENIED"
  exit 0
fi

echo "AUTHORIZED"
exit 0
```

```bash
tech@grestin.local@station-001:~$ su - inspector@grestin.local
inspector@grestin.local@station-001:~$ nano ~/.bashrc
```

```bash
export PATH=$PATH:/mnt/nas/scripts/inspector-tools
```

```bash
inspector@grestin.local@station-001:~$ source ~/.bashrc
```