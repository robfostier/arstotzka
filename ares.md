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
tech@hermes:~$ sudo apt update
tech@hermes:~$ sudo apt upgrade -y
```

## Installation XFCE

```bash
tech@hermes:~$ sudo apt install xfce4 xfce4-goodies -y
tech@hermes:~$ echo "exec startxfce4" >> ~/.xinitrc
tech@hermes:~$ echo "startx" >> ~/.profile
```

## Configuration Host-only

```bash
tech@hermes:~$ sudo nano /etc/netplan/50-cloud-init.yaml
```

```yaml
ens37:
    dhcp4: false
    addresses: [10.0.0.1/24]
```

```bash
tech@hermes:~$ sudo netplan apply
```

