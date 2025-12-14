# pLPIC2 - Glory to Arstotzka

Robinson Fostier, Anthony Guarin

---

## Objectifs du projet

L’objectif de ce projet est de concevoir et déployer une infrastructure informatique sécurisée sous Linux.

Plus précisément, le projet nécessite de :
- Permettre aux immigrants de déposer leurs candidatures sous forme d’archives sur un serveur de fichiers externe
- Vérifier automatiquement la conformité des archives déposées (structure, formats, nommage, critères gouvernementaux)
- Supprimer ou rejeter les fichiers non conformes via un script de tri automatisé
- Transférer les dossiers valides vers un serveur de fichiers interne sécurisé
- Assurer la haute disponibilité des données grâce à un système de stockage tolérant aux pannes
- Notifier les inspecteurs par courrier électronique interne de l’arrivée de nouveaux dossiers
- Fournir aux inspecteurs des outils simples pour :
    - Consulter les dossiers
    - Accepter ou refuser un immigrant
    - Classer les dossiers dans les répertoires appropriés
    - Rechercher un immigrant par numéro d’identification et vérifier son statut

La mise en place de cette infrastructure nécessite la création de plusieurs serveurs spécialisés et d'au moins un poste client inspecteur.

---

## Infrastructure

![Diagramme de l'infrastructure](diagramme_infrastructure.png)

Nous avons décidé de déployer nos serveurs sur deux réseaux distincts :
- `10.0.0.0/24` : Mis en place sur VMWare via une carte réseau en Host-Only, ce réseau contient tous les équipements et services internes.
- `192.168.197.0/24` : Mis en place sur VMware via une carte réseau NAT, ce réseau simule une DMZ pour protéger le réseau interne en controllant le trafic entrant et sortant.

Le routage entre les deux réseaux est sous la responsabilité du serveur Ares. Ce serveur possède deux interfaces :
- `192.168.197.254`
- `10.0.0.1`

Le trafic sortant du réseau interne transite par ce serveur, qui le route vers la passerelle NAT en `192.168.197.2`.

Un second serveur est mis en place sur la DMZ, le serveur de téléchargement de fichiers externe (nommé Zeus). Ce serveur permet aux immigrants de déposer leurs candidatures. Les candidatures valides sont ensuite envoyés en SFTP vers le réseau interne par SSH. Il communique avec la DMZ via l'addresse `192.168.197.10`.

Sur le réseau interne, trois serveurs supplémentaires sont mis en place :
- Hermes `10.0.0.10` : Ce serveur possède trois rôles distincts. Il est contrôleur du domaine grestin.local, ainsi que DNS et DHCP sur le réseau interne.
- Metis `10.0.0.20` : Ce serveur de stockage fournit le NAS du réseau interne. 4 disque durs y sont montés, en RAID5. La partition est paramétrée en NFS, et est partagée aux ordinateurs du domaine. Le partage stocke les dossiers d'immigrants et les boîtes mail du service mail interne.
Le serveur Zeus peut communiquer via SSH avec Metis.
- Athena `10.0.0.30` : Ce serveur distribue les services métiers de notre réseau. Il fournit un service mail et une base de donnée mySQL.

Un poste client station-001 est également mis en place sur le serveur interne. Il récupère une addresse IP dynamique via le serveur Hermes. Les inspecteurs du domaine travaillant sur ce poste peuvent accéder à leurs mails et traiter les dossiers en attente.

---

## Déploiements

*Ce chapitre détaille nos déploiements. Toutes les configurations sont disponibles dans le dossier `/cfg/` du projet. Un fichier Markdown est également disponible pour chaque équipement, où sont recensées les commandes utilisées pour mettre en place ces configurations.*

### ares - Serveur Router + Firewall

Nous définissons l'adressage IPv4 du serveur.
Deux interfaces sont paramétrées comme ceci :

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

L'interface `ens33` correspond à la carte réseau VMnat. Le choix de l'addresse statique est arbitraire. La connection Internet se fait via la passerelle NAT en `192.168.197.2`.
L'interface `ens34` correspond à la carte réseau Host-Only. Nous attribuons arbitrairement l'IP statique `10.0.0.1` car ce serveur fera office de router sur le réseau.

- #### Routage IPv4

Après avoir configuré l'addressage du serveur, nous pouvons lui attribuer le rôle de router, en lui permettant de rediriger les paquets qui ne lui sont pas directement addressés, à l'aide de sa table MAC. La table MAC est gérée automatiquement par le kernel.
Cela se fait en modifiant le fichier `/etc/sysctl.conf`, avec cette instruction :

```text
net.ipv4.ip_forward=1
```

- #### Règles iptables

Les règles suivantes permettent de mettre en place la redirection du trafic réseau entre le réseau interne et le réseau externe via le routeur, en utilisant la traduction d’adresses (NAT).

- Activation du NAT

```bash
tech@ares:~$ sudo iptables -t nat -A POSTROUTING -o ens33 -j MASQUERADE
```

Cette règle permet de masquer les adresses IP du réseau interne lors de la sortie vers Internet.
Tous les paquets sortants via l’interface ens33 auront leur adresse source remplacée par celle du routeur, ce qui permet aux machines internes d’accéder à Internet sans être directement exposées.

- Autorisation du trafic sortant depuis le réseau interne

```bash
tech@ares:~$ sudo iptables -A FORWARD -i ens34 -o ens33 -j ACCEPT
```

Cette règle autorise le transfert des paquets du réseau interne vers Internet.
Elle permet aux postes internes (inspecteurs, serveurs internes) d’initier des connexions vers l’extérieur.

- Autorisation des réponses aux connexions établies

```bash
tech@ares:~$ sudo iptables -A FORWARD -i ens33 -o ens34 -m state --state ESTABLISHED,RELATED -j ACCEPT
```

Cette règle autorise uniquement les paquets de réponse provenant d’Internet vers le réseau interne, à condition qu’ils fassent partie d’une connexion déjà établie ou liée à une connexion existante.
Cela empêche toute connexion entrante non sollicitée.

- Autorisation du trafic entrant supplémentaire

```bash
tech@ares:~$ sudo iptables -A FORWARD -i ens33 -o ens34 -j ACCEPT
```

Cette règle permet le transfert du trafic depuis l’interface externe vers l’interface interne.
Elle est utilisée pour le transfert de dossiers de Zeus à Metis en SFTP, mais doit être contrôlée pour des raisons de sécurité.

- Autorisation des retours de connexions internes

```bash
tech@ares:~$ sudo iptables -A FORWARD -i ens34 -o ens33 -m state --state ESTABLISHED,RELATED -j ACCEPT
```

Cette règle autorise le trafic retour du réseau interne vers Internet dans le cadre de connexions déjà établies, garantissant la continuité des échanges réseau.

- #### Squid

Un service Squid est mis en place une fois la totalité des équipements du réseau interne configurés, pour filtrer le trafic entrant. Seuls les services du gouvernement et le serveur Zeus sont autorisés à communiquer avec le réseau interne.

---

### hermes - Serveur AD + DNS + DHCP

Nous définissons l'adressage IPv4 du serveur.

```yaml
ens33:
    dhcp4: false
    addresses: [10.0.0.10/24]
    routes:
        - to: 0.0.0.0/0
          via: 10.0.0.1
    nameservers:
        addresses: [10.0.0.10]
```

L'interface `ens33` correspond à la carte réseau Host-Only. Nous attribuons arbitrairement l'IP statique `10.0.0.10` car ce serveur fournira les services AD, DNS et DHCP. Il nous semblait cohérent de lui fournir une addresse basse.
Nous indiquons l'addresse IP de Ares en passerelle, et sa propre addresse IP en DNS.

Le fichier `/etc/hosts` est configuré comme ceci :

```ini
127.0.0.1 localhost
10.0.0.10 hermes.grestin.local hermes
```

- #### Active Directory / DNS

Nous configurons le rôle de contrôleur de domaine et de DNS. Pour l'AD, nous installons samba, krb5 et smbclient. Pour le DNS, nous installons bind9, bind9utils, bind9-dnsutils et winbind.

Le domaine est configuré ainsi :
- REALM : GRESTIN.LOCAL
- KERBEROS SERVERS : hermes.grestin.local
- ADMINISTRATIVE SERVERS: hermes.grestin.local

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
