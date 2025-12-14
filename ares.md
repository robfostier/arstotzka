# ares - Serveur Router + Firewall
Ubuntu 24.04.3 Live Server

Name : Technician
Server name : ares
username : tech
password : Sup1nf0 

Cartes réseau :
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
    addresses: [192.168.197.254/24]
    nameservers:
        addresses: [1.1.1.1, 8.8.8.8]
    routes:
        - to: 0.0.0.0/0
          via: 192.168.197.2
ens34:
    dhcp4: false
    addresses: [10.0.0.1/24]
```

```bash
tech@ares:~$ sudo netplan apply
```

## Routage IPv4

```bash
tech@ares:~$ sudo nano /etc/sysctl.conf
```

```text
net.ipv4.ip_forward=1
```

```bash
tech@ares:~$ sudo sysctl -p
```

## iptables

```bash
tech@ares:~$ sudo iptables -F
tech@ares:~$ sudo iptables -t nat -F
tech@ares:~$ sudo iptables -t mangle -F
tech@ares:~$ sudo iptables -t nat -A POSTROUTING -o ens33 -j MASQUERADE
tech@ares:~$ sudo iptables -A FORWARD -i ens34 -o ens33 -j ACCEPT
tech@ares:~$ sudo iptables -A FORWARD -i ens33 -o ens34 -m state --state ESTABLISHED,RELATED -j ACCEPT
tech@ares:~$ sudo iptables -A FORWARD -i ens33 -o ens34 -j ACCEPT
tech@ares:~$ sudo iptables -A FORWARD -i ens34 -o ens33 -m state --state ESTABLISHED,RELATED -j ACCEPT
tech@ares:~$ sudo apt install iptables-persistent -y
tech@ares:~$ sudo netfilter-persistent save
tech@ares:~$ sudo netfilter-persistent reload
```
