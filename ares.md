# hermes - Serveur DHCP + DNS
Ubuntu 24.04.3 Live Server

Your name : Technician
Your servers name : ares
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
ens37:
    dhcp4: false
    addresses: [10.0.0.1/24]
```

```bash
tech@ares:~$ sudo netplan apply
```

## Firewall
