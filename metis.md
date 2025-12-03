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
tech@ares:~$ sudo apt update
tech@ares:~$ sudo apt upgrade -y
```

## Installation XFCE

```bash
tech@ares:~$ sudo apt install xfce4 xfce4-goodies -y
tech@ares:~$ echo "exec startxfce4" >> .xinitrc
tech@ares:~$ echo "startx" >> .profile
tech@ares:~$ sudo apt remove lightdm -y
tech@ares:~$ reboot
```

## Configuration Host-only

```bash
tech@ares:~$ sudo nano /etc/netplan/50-cloud-init.yaml
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
tech@ares:~$ sudo netplan apply
```

## NAS