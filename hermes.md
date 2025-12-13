# hermes - Serveur DHCP + DNS
Ubuntu 24.04.3 Live Server

Name : Technician
Server name : hermes
username : tech
password : Sup1nf0 

cartes réseau :
VMnet10 (host-only) : 10.0.0.0/24

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

## Setup

```bash
tech@hermes:~$ sudo apt update
tech@hermes:~$ sudo apt upgrade -y
tech@hermes:~$ sudo nano /etc/hosts
```

```ini
127.0.0.1 localhost
10.0.0.10 hermes.grestin.local hermes
```

## Active Directory / DNS

```bash
tech@hermes:~$ sudo apt install samba krb5-user winbind smbclient bind9 bind9utils bind9-dnsutils -y
```

REALM : GRESTIN.LOCAL
KERBEROS SERVERS : hermes.grestin.local
ADMINISTRATIVE SERVERS: hermes.grestin.local

```bash
tech@hermes:~$ sudo systemctl stop samba-ad-dc smbd nmbd winbind
tech@hermes:~$ sudo mv /etc/samba/smb.conf /etc/samba/smb.conf.bak 2>/dev/null
tech@hermes:~$ sudo samba-tool domain provision --use-rfc2307 --realm=GRESTIN.LOCAL --domain=GRESTIN --server-role=dc --dns-backend=BIND9_DLZ --adminpass='Sup1nf0'
tech@hermes:~$ sudo nano /etc/bind/named.conf
```

```makefile
include "/var/lib/samba/bind-dns/named.conf";
```

```bash
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

tkey-gssapi-keytab "/var/lib/samba/bind-dns/dns.keytab";
```

```bash
tech@hermes:~$ sudo chown bind:bind /var/lib/samba/bind-dns/dns.keytab
tech@hermes:~$ sudo chmod 640 /var/lib/samba/bind-dns/dns.keytab
```

```bash
tech@hermes:~$ sudo systemctl disable --now systemd-resolved
tech@hermes:~$ sudo rm /etc/resolv.conf
tech@hermes:~$ echo "nameserver 10.0.0.10" | sudo tee /etc/resolv.conf
tech@hermes:~$ sudo systemctl restart bind9
tech@hermes:~$ sudo systemctl restart samba-ad-dc
```

## Kerberos

```bash
tech@hermes:~$ sudo nano /etc/krb5.conf
```

```ini
[libdefaults]
    default_realm = GRESTIN.LOCAL
    dns_lookup_realm = true
    dns_lookup_kdc = true

[realms]
    GRESTIN.LOCAL = {
        kdc = hermes.grestin.local
        admin_server = hermes.grestin.local
    }
```

## DHCP

```bash
tech@hermes:~$ sudo apt install isc-dhcp-server -y
tech@hermes:~$ sudo nano /etc/default/isc-dhcp-server
```

```bash
INTERFACESv4="ens33"
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
  option netbios-name-servers 10.0.0.10;
}
```

```bash
tech@hermes:~$ sudo systemctl restart isc-dhcp-server
tech@hermes:~$ sudo systemctl enable isc-dhcp-server
```

## DNS records

- ### A
  ```bash
  tech@hermes:~$ samba-tool dns add hermes.grestin.local grestin.local ares A 10.0.0.1
  tech@hermes:~$ samba-tool dns add hermes.grestin.local grestin.local metis A 10.0.0.20
  tech@hermes:~$ samba-tool dns add hermes.grestin.local grestin.local athena A 10.0.0.30
  ```

- ### MX
  ```bash
  tech@hermes:~$ samba-tool dns add hermes.grestin.local grestin.local @ MX "athena.grestin.local 10"
  ```

## Groupes et utilisateurs

```bash
tech@hermes:~$ sudo samba-tool user create tech Sup1nf0
tech@hermes:~$ sudo samba-tool user create IT Sup1nf0
tech@hermes:~$ sudo samba-tool group addmembers IT tech
tech@hermes:~$ sudo samba-tool user create inspector Sup1nf0
tech@hermes:~$ sudo samba-tool user create Inspectors Sup1nf0
tech@hermes:~$ sudo samba-tool group addmembers Inspectors inspector
tech@hermes:~$ sudo samba-tool computer create METIS
tech@hermes:~$ sudo samba-tool computer create ATHENA
tech@hermes:~$ sudo samba-tool computer create station-001
```