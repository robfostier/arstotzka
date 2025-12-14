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

L'interface `ens33` correspond à la carte réseau NAT. Le choix de l'addresse statique est arbitraire. La connection Internet se fait via la passerelle NAT en `192.168.197.2`.
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

Un service Squid est mis en place une fois la totalité des équipements du réseau interne configurés, pour filtrer le trafic entrant. Seuls les services du gouvernement et le serveur Zeus sont autorisés à communiquer avec le réseau interne, réduisant ainsi la surface d'attaque.

Les règles d'accès sont mises en places :
- `http_access allow localnet zeus` : Autorise le réseau interne vers Zeus
- `http_access allow localnet gov_dns` : Autorise les DNS gouvernementaux
- `http_access allow localnet gov_sites` : Autorise les sites gouvernementaux
- `http_access allow localhost` : Autorise localhost
- `http_access deny all` : Bloque tout le reste

On ajoute également deux règles aux iptables :
- `iptables -A INPUT -s 10.0.0.0/24 -p tcp --dport 3128 -j ACCEPT` : autorise les machines du réseau interne (10.0.0.0/24) à se connecter au proxy Squid sur Ares (port 3128).
- `iptables -A INPUT -p tcp --dport 3128 -s 192.168.197.0/24 -j DROP` : bloque toute tentative de connexion au proxy Squid (port 3128) provenant du réseau DMZ.

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
- ADMINISTRATIVE SERVERS : hermes.grestin.local

Le DNS est configuré pour permettre la recursion uniquement aux équipements du réseau interne. Cela permet d'empêcher les équipements externes d'accéder aux services DNS de ce serveur. Les requêtes DNS que ce serveur ne sait pas résoudre sont forwardées aux DNS publics `1.1.1.1` et `8.8.8.8`.

Le fichier `/etc/krb5.conf` est configuré ainsi :

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

Les DNS records sont également configurés, en prévision de la mise en place des différents services :

- A
  ```bash
  tech@hermes:~$ samba-tool dns add hermes.grestin.local grestin.local ares A 10.0.0.1
  tech@hermes:~$ samba-tool dns add hermes.grestin.local grestin.local metis A 10.0.0.20
  tech@hermes:~$ samba-tool dns add hermes.grestin.local grestin.local athena A 10.0.0.30
  ```

- MX
  ```bash
  tech@hermes:~$ samba-tool dns add hermes.grestin.local grestin.local @ MX "athena.grestin.local 10"
  ```

- #### DHCP

Nous configurons le service DHCP du serveur, en installant isc-dhcp-server.
Les paramètres du DHCP sont configurés dans le fichier `/etc/dhcp/dhcpd.conf`.

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

Nous définissons une plage de 100 addresses dynamiques, qui devrait convenir pour le nombre de stations d'inspecteurs. Le service DHCP distribue également les informations DNS.

- #### Groupes et utilisateurs du domaine

Nous créons deux utilisateurs et deux groupes sur le domaine :
1. tech@grestin.local, dans le groupe IT
2. inspector@grestin.local, dans le groupe Inspectors

Cela nous permet de mutualiser les utilisateurs du domaine pour permettre aux inspecteurs d'accéder à leurs boites mails sur n'importe quelle station, et cela facilite également la gestion des permissions d'accès au partage NAS notamment.

---

### metis - Network Attached Storage

Nous définissons l'adressage IPv4 du serveur.

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

L'interface `ens33` correspond à la carte réseau Host-Only. Nous attribuons arbitrairement l'IP statique `10.0.0.20`.
Nous indiquons l'addresse IP de Ares en passerelle, et l'adresse IP de Hermes en DNS.

Le serveur rejoint le domaine, grâce à l'installation et à la configuration des services realmd, sssd, adcli, samba-common-bin, krb5-user et packagekit.
L'utilisateur `tech@grestin.local` est ajoutée à la liste des sudoers du serveur.

- #### RAID 5

4 disques durs virtuels de 2GB chacun sont ajoutés sur le serveur à froid.
Nous installons mdadm pour monter les disques en une partition RAID5.

La partition est montée sur le dossier `/srv/raid5`.

Les informations du montage sont inscrites dans `/etc/fstab` pour que la partition soit automatiquement montées après chaque redémarrage du serveur :

```ini
/dev/md0 /srv/raid5 ext4 defaults 0 2
```

- #### NAS

Nous mettons en place le service de partage NAS, en installant nfs-kernel-server. Nous avons choisi NFS par simplicité car tous les équipements du réseau fonctionnent sur Linux.

Un dossier `share/` est créé sur `/srv/raid5/`. Le partage est paramétré dans le fichier `/etc/exports` :

```ini
/srv/raid5/share 10.0.0.30(rw,sync,no_subtree_check)
```

- #### Contenu du partage

Le partage est structuré ainsi :

```
├──cases/ 
|   ├── pending/
|   ├── rejected/
|   └── accepted/
├──mail/
|  ├── tech@grestin.local/Maildir/{cur,new,tmp}
|  └── inspector@grestin.local/Maildir/{cur,new,tmp}
└──scripts/
   └── inspector-tools/
```

Cela nous permet de mutualiser trois types de données sur le réseau : les candidatures traitées ou en attente de traitement, les boites mails des utilisateurs du domaine, et les scripts utilisés par les inspecteurs.

- #### SSH

Nous installons openssh-server sur le serveur afin de permettre la communication SSH avec le serveur de téléchargement de fichiers externe. Les candidatures peuvent ainsi être ajoutées via SFTP par SSH dans le dossier `/srv/raid5/share/cases/pending`.

---

### athena - Internal Server

Nous définissons l'adressage IPv4 du serveur.

```yaml
ens33:
    dhcp4: false
    addresses: [10.0.0.30/24]
    routes:
        - to: 0.0.0.0/0
          via: 10.0.0.1
    nameservers:
        addresses: [10.0.0.10]
```

L'interface `ens33` correspond à la carte réseau Host-Only. Nous attribuons arbitrairement l'IP statique `10.0.0.30`.
Nous indiquons l'addresse IP de Ares en passerelle, et l'adresse IP de Hermes en DNS.

Le serveur rejoint le domaine, grâce à l'installation et à la configuration des services realmd, sssd, adcli, samba-common-bin, krb5-user et packagekit.
L'utilisateur `tech@grestin.local` est ajoutée à la liste des sudoers du serveur.

- #### Montage du NAS

Nous installons nfs-common pour monter le NAS sur le serveur.
La configuration du montage est définie dans le fichier `/etc/fstab`.

```ini
10.0.0.20:/srv/raid5/share /mnt/nas nfs defaults,_netdev 0 0
```

- #### Mail Server

Ce serveur distribue le service mail pour le réseau interne.
Pour la gestion de boîtes mails, nous installons et paramétrons les services dovecot-core, dovecot-imapd et dovecot-lmtpd.

Dans le fichier `/etc/dovecot/conf.d/10-mail.conf`, nous paramétrons les boîtes mails pour qu'elles soient créées sur le partage NAS :

```ini
mail_location = maildir:/mnt/nas/mail/%n/Maildir
```

L'accès aux boîtes mails se fait par telnet :

```
tech@grestin.local@athena:~$ telnet localhost 143
>> a login tech@grestin.local Sup1nf0
>> a select INBOX
```

Nous installons également les services postfix et mailutils, qui sont chargés de transporter les mails jusqu'aux boîtes.
Nous avons décidé de ne pas utiliser les services TLS de Postfix par simplicité. Le reste du paramétrage est classique.

---

### zeus - External File Upload Server

Ce serveur est configuré sur la DMZ par sécurité car les immigrants peuvent y déposer des fichiers, donc nous avons choisi de l'isoler du réseau interne.

Nous définissons l'adressage IPv4 du serveur.

```yaml
ens33:
    dhcp4: false
    addresses: [192.168.197.10/24]
    nameservers:
        addresses: [1.1.1.1, 8.8.8.8]
    routes:
        - to: 0.0.0.0/0
          via: 192.168.197.2
        - to: 10.0.0.0/24
          via: 192.168.197.254
```

L'interface `ens33` correspond à la carte réseau NAT. Nous attribuons arbitrairement l'IP statique `192.168.197.10`.
Nous indiquons deux passerelles :
- vers Internet : `192.168.197.2`, la passerelle du NAT
- vers le réseau interne  `10.0.0.0/24`: `192.168.197.254`, l'interface connectée à la DMZ du serveur Ares. Le trafic envoyé sur ce serveur est ensuite routé vers les équipements du réseau interne.

- #### SFTP

Nous installons openssh-server pour permettre le transfert de fichier en SFTP vers le serveur NAS du réseau interne.

Un compte utilisateur immigrant est créé sur le serveur, avec des droits minimum. Les candidatures déposées par les immigrants se font dans le dossier `srv/sftp/immigrant/uploads`.

Le paramétrage du SFTP par SSH se fait dans le fichier `/etc/ssh/sshd_config` :

``` ini
Match User immigrant
    ChrootDirectory /srv/sftp/immigrant
    ForceCommand internal-sftp
    AllowTcpForwarding no
    X11Forwarding no
```

- #### Scripts

*Les scripts présentés ici sont disponibles dans le dossier `/cfg/zeus/srv/scripts` du projet.*

Deux scripts bash sont créés sur le serveur, à l'addresse `/srv/scripts` :
- `cleanup.sh` : ce script utilise le service unzip, préalablement installé, pour dézipper les archives déposées par les immigrants et vérifier leurs contenus. Si l'archive traitée contient un fichier .txt et un fichier .pdf, le script vérifie avec la commande `grep` que l'ID de l'immigrant est bien renseigné. Si c'est le cas, l'archive est déplacée dans le dossier `srv/sftp/immigrant/valid` et prête à être transférée vers le réseau interne. Sinon, elle est déplacée dans le dossier `srv/sftp/immigrant/invalid`.
- `transfer.sh`: ce script parcourt l'ensemble des archives dans le dossier `srv/sftp/immigrant/valid`, et les transfère avec la commande `scp` vers le NAS, dans le dossier `/srv/raid5/share/cases/pending`. À chaque archive transmise, un mail est envoyé à `inspector@grestin.local`. Enfin, l'archive est supprimée.

Pour chacun de ces scripts, une règle d'automatisation est paramétrée sur un timer de deux minutes, grâce aux fichiers `cleanup.service`, `cleanup.timer`, `transfer.service` et `transfer.timer` à l'addresse `/etc/systemd/system/`.

---

### station-001 - Client

Les clients utilisent Ubuntu 24.04.3 Desktop.
L'addressage IP se fait dynamiquement, via les services de Hermes. 

Le serveur rejoint le domaine, grâce à l'installation et à la configuration des services realmd, sssd, adcli, samba-common-bin, krb5-user et packagekit.
Le join du domaine se fait avec l'utilisateur `inspector@grestin.local`.

- #### Montage du NAS

Nous installons nfs-common pour monter le NAS sur le client.
La configuration du montage est définie dans le fichier `/etc/fstab`.

```ini
10.0.0.20:/srv/raid5/share /mnt/nas nfs defaults,_netdev 0 0
```

- #### Scripts

*Les scripts présentés ici sont disponibles dans le dossier `/cfg/metis/srv/raid5/share/scripts/inspector-tools` du projet.*

Les scripts utilisés par les inspecteurs sont créés sur le partage NAS, dans le dossier `/scripts/inspector-tools`.

Pour la classification des candidatures, un script est créé :
- `case.sh` : ce script s'utilise avec la commande `./case.sh <accept|reject> <case.zip> <ID>`. Le fichier zip ciblé est automatiquement déplacé de `/cases/pending/` vers `/cases/accepted/` ou `/cases/rejected/`. Un log est ajouté au fichier `/mnt/nas/cases/cases.log`.

Un script est également créé pour vérifier dans la base de donnée du serveur Athena si un ID d'immigrant est autorisé à rentrer dans le pays.
- `search.sh` : ce script s'utilise avec la commande `./search.sh <ID>`. Il parcourt les logs `/mnt/nas/cases/cases.log`, et cherche une candidature rejetée avec un ID correspondant. On considère que tout immigrant rejeté une fois est rejeté pour toujours, donc si le script trouve le même ID dans les logs de rejet on peut définir que l'immigrant est interdit de territoire. 

- #### Proxy Squid

Nous définissons un proxy aux addresses `http://10.0.0.1:3128` et `https://10.0.0.1:3128`. Ces addresses correspondent aux ports de Squid sur le Firewall. Ainsi, seuls les sites du gouvernement peuvent être consultés depuis le poste client.



