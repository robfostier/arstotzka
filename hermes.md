# hermes - Serveur DHCP + DNS
Ubuntu 24.04.3 Live Server

User : Technician
server : hermes
username : tech
password : Sup1nf0 

cartes réseau :
VMnet8 (NAT)
VMnet10 (host-only) : 10.0.0.0/24

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
option domain-name "example.org";
option domain-name-servers ns1.example.org, ns2.example.org;

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

