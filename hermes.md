# hermes - Serveur DHCP + DNS
Ubuntu 24.04.3 Live Server

Your name : Technician
Your servers name : hermes
username : tech
password : Sup1nf0 

cartes réseau :
VMnet10 (host-only) : 10.0.0.0/24

```bash
tech@hermes:~$ sudo apt update
tech@hermes:~$ sudo apt upgrade -y
```

## Installation XFCE

```bash
tech@hermes:~$ sudo apt install xfce4 xfce4-goodies -y
tech@hermes:~$ echo "exec startxfce4" >> .xinitrc
tech@hermes:~$ echo "startx" >> .profile
tech@hermes:~$ sudo apt remove lightdm -y
tech@hermes:~$ reboot
```

## Configuration Host-only

```bash
tech@hermes:~$ sudo nano /etc/netplan/50-cloud-init.yaml
```

```yaml
ens37:
    dhcp4: false
    addresses: [10.0.0.10/24]
    routes:
        - to: 0.0.0.0/0
          via: 10.0.0.1
    nameservers:
        addresses: [10.0.0.10]
```

```bash
tech@hermes:~$ sudo netplan apply
```

## DHCP

```bash
tech@hermes:~$ sudo apt install isc-dhcp-server -y
tech@hermes:~$ sudo nano /etc/default/isc-dhcp-server
```

```bash
INTERFACESv4="ens37"
```

```bash
tech@hermes:~$ sudo nano /etc/dhcp/dhcpd.conf
```

```pqsql
default-lease-time 600;
max-lease-time 7200;

subnet 10.0.0.0 netmask 255.255.255.0 {
  range 10.0.0.100 10.0.0.200;
  option routers 10.0.0.1;
  option domain-name-servers 10.0.0.10;
  option domain-name "grestin.local";
}
```

```bash
tech@hermes:~$ sudo systemctl restart isc-dhcp-server
tech@hermes:~$ sudo systemctl enable isc-dhcp-server
```

## DNS

```bash
tech@hermes:~$ sudo apt install bind9 -y
tech@hermes:~$ sudo nano /etc/bind/named.conf.options
```

```text
recursion yes;
allow-recursion { 10.0.0.0/24; };

allow-query { any; };
dnssec-validation auto;

listen-on { 10.0.0.10; };

forwarders {
	1.1.1.1;
	8.8.8.8;
};
```

```bash
tech@hermes:~$ sudo nano /etc/bind/named.conf.local
```

```text
zone "grestin.local" {
	type master;
	file "/etc/bind/db.grestin.local";
};
```

```bash
tech@hermes:~$ sudo cp /etc/bind/db.local /etc/bind/db.grestin.local 
tech@hermes:~$ sudo nano /etc/bind/db.grestin.local
```

```text
$TTL	604800
@	IN	SOA	hermes.grestin.local. root.grestin.local. (
			      1		; Serial
			 604800		; Refresh
			  86400		; Retry
			2419200		; Expire
			 604800 )	; Negative Cache TTL
;
@	IN	NS	hermes.grestin.local.
ares	IN	A	10.0.0.1
hermes	IN	A	10.0.0.10
metis	IN	A	10.0.0.20
athena	IN	A	10.0.0.30
```