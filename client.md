# Station-001 - Client
Ubuntu 24.04.3 Desktop

Name : Inspector
Desktop name : station-001
username : inspector
password : Sup1nf0 

Carte réseau :
VMnet10 (host-only) : 10.0.0.0/24

Log into Active Directory :
Domain : grestin.local
Domain join user : inspector
Password : Sup1nf0

```bash
inspector@station-001:~$ sudo echo "tech@grestin.local ALL=(ALL) ALL" >> /etc/sudoers.d/tech-ad
inspector@station-001:~$ sudo chmod 440 /etc/sudoers.d/tech-ad
inspector@station-001:~$ su - tech@grestin.local
tech@grestin.local@station-001:~$ sudo apt update
tech@grestin.local@station-001:~$ sudo apt upgrade -y
tech@grestin.local@station-001:~$ sudo apt install open-vm-tools -y
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