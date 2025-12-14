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

## Squid

```bash
tech@ares:~$ sudo apt install squid -y
tech@ares:~$ sudo nano /etc/squid/squid.conf
```

```conf
http_port 3128

acl localnet src 10.0.0.0/24
acl dmz src 192.168.197.0/24

acl zeus dst 192.168.197.10

acl gov_dns dst 1.1.1.1
acl gov_dns dst 8.8.8.8

acl gov_sites dstdomain .gov

http_access allow localnet zeus
http_access allow localnet gov_dns
http_access allow localnet gov_sites
http_access allow localhost
http_access deny all

cache deny all

access_log /var/log/squid/access.log
cache_log /var/log/squid/cache.log
```

```bash
tech@ares:~$ sudo systemctl restart squid
tech@ares:~$ sudo systemctl enable squid
tech@ares:~$ sudo iptables -A INPUT -s 10.0.0.0/24 -p tcp --dport 3128 -j ACCEPT
tech@ares:~$ sudo iptables -A INPUT -p tcp --dport 3128 -s 192.168.197.0/24 -j DROP
```