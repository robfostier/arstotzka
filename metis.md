# metis - Network Attached Storage
Ubuntu 24.04.3 Live Server

Name : Technician
Server name : metis
username : tech
password : Sup1nf0 

cartes réseau :
VMnet8 (NAT)
VMnet10 (host-only) : 10.0.0.0/24

```bash
tech@metis:~$ sudo apt update
tech@metis:~$ sudo apt upgrade -y
```

## Installation XFCE

```bash
tech@metis:~$ sudo apt install xfce4 xfce4-goodies -y
tech@metis:~$ echo "exec startxfce4" >> .xinitrc
tech@metis:~$ echo "startx" >> .profile
tech@metis:~$ sudo apt remove lightdm -y
tech@metis:~$ reboot
```

## Configuration Host-only

```bash
tech@metis:~$ sudo nano /etc/netplan/50-cloud-init.yaml
```

```yaml
ens33:
    dhcp4: false
    addresses: [10.0.0.20/24]
    routes:
        - to: 0.0.0.0/0
          via: 10.0.0.1
    nameservers:
        addresses: [10.0.0.10]
```

```bash
tech@metis:~$ sudo netplan apply
```

## NAS

```bash
tech@metis:~$ sudo apt install nfs-kernel-server -y
tech@metis:~$ sudo mkdir -p /srv/nas_share
tech@metis:~$ sudo chown nobody:nogroup /srv/nas_share
tech@metis:~$ sudo chmod 777 /srv/nas_share
tech@metis:~$ sudo nano /etc/exports
```

```text
/srv/nas_share 10.0.0.30(rw,sync,no_subtree_check)
```

```bash
tech@metis:~$ sudo exportfs -ra
tech@metis:~$ sudo systemctl restart nfs-kernel-server
```