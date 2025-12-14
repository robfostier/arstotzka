# File Upload Server (DMZ)

Ouvrir port TCP et permettre dépot de dossiers. (nc, scp, ftp)

Archive (.tar, .gz, .bz2, .zip) :
  - .txt
  - .pdf

définir liste de critères à respecter, sinon automatiquement clean up archives. Transférer les archives valides au stockage interne (ftp)

# Network Attached Storage (RAID, stockage interne)

```
├──cases/ 
|   ├── pending/
|   ├── rejected/
|   └── accepted/
└──scripts/
```

# Internal Server

## Mail Server

## DB mySQL

TABLE CASES
id_alien	nom_fichier		status		date		comment		id_inspector
465-1173	465-1173.zip		waiting	   	2025-01-20	NULL		123-0001

TABLE ALIENS
id_alien	last_name	first_name	 is_allowed	home_country	height	weight	birth_date
465-1173	viktor          naraskaya        false		Antegria	167	75	27/08/1932

TABLE INSPECTORS ?
id_inspector
123-0001

## Mounted NAS (NFS, SMB)

# DHCP / DNS

Plage dynamique 100-200

# Firewall

Fait la liaison entre DMZ et réseau interne
Proxy Squid installé pour filtrer sites
-> LAN interne ne peut sortir que via proxy filtrant

# Addressage
## LAN : 10.0.0.0/24 (VMnet10 Host-only)
  .1 : Firewall
  .10  : DHCP + DNS
  .20 : NAS
  .30 : Serveur Interne
  Range DHCP 100-199 : Clients (postes inspecteurs)

## LAN : 192.168.197.0/24 (VMnet8 NAT)
  .1 : Firewall
  .10 : File Upload Server
