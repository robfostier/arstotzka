# athena - Internal Server
Ubuntu 24.04.3 Live Server

Name : Technician
Server name : athena
username : tech
password : Sup1nf0 

Carte réseau :
VMnet10 (host-only) : 10.0.0.0/24

```bash
tech@athena:~$ sudo apt update
tech@athena:~$ sudo apt upgrade -y
```

## Configuration Host-only

```bash
tech@athena:~$ sudo nano /etc/netplan/50-cloud-init.yaml
```

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

```bash
tech@athena:~$ sudo netplan apply
```

## Configuration Active Directory

```bash
tech@athena:~$ sudo nano /etc/hosts
```

```
127.0.0.1 localhost
10.0.0.10 hermes.grestin.local hermes
10.0.0.30 athena.grestin.local athena
```

```bash
tech@athena:~$ sudo nano /etc/resolv.conf
```

```
nameserver 10.0.0.10
```

```bash
tech@athena:~$ sudo apt install realmd sssd adcli samba-common-bin krb5-user packagekit -y
tech@athena:~$ kinit Administrator
tech@athena:~$ klist
tech@athena:~$ sudo realm join --user=Administrator GRESTIN.LOCAL
tech@athena:~$ sudo nano /etc/pam.d/common-session
```

```text
session required        pam_mkhomedir.so skel=/etc/skel/ umask=0077  
```

```bash
tech@athena:~$ sudo systemctl restart sssd
tech@athena:~$ sudo echo "tech@grestin.local ALL=(ALL) ALL" >> /etc/sudoers.d/tech-ad
tech@athena:~$ sudo chmod 440 /etc/sudoers.d/tech-ad
tech@athena:~$ su - tech@grestin.local
```

## Mount NAS

```bash
tech@grestin.local@athena:~$ sudo apt install nfs-common -y
tech@grestin.local@athena:~$ sudo mkdir -p /mnt/nas
tech@grestin.local@athena:~$ sudo nano /etc/fstab
```

```text
10.0.0.20:/srv/raid5/share /mnt/nas nfs defaults,_netdev 0 0
```

```bash
tech@grestin.local@athena:~$ systemctl daemon-reload
tech@grestin.local@athena:~$ sudo mount -a
```

## Mail Server

- ### Dovecot
    ```bash
    tech@grestin.local@athena:~$ sudo apt install dovecot-core dovecot-imapd dovecot-lmtpd -y
    tech@grestin.local@athena:~$ sudo nano /etc/dovecot/conf.d/10-auth.conf
    ```

    ```ini
    disable_plaintext_auth = no
    auth_mechanisms = plain login
    !include auth-system.conf.ext
    ```

    ```bash
    tech@grestin.local@athena:~$ sudo nano /etc/dovecot/conf.d/auth-system.conf.ext
    ```

    ```ini
    passdb {
        args = login
    }
    ```

    ```bash
    tech@grestin.local@athena:~$ sudo nano /etc/dovecot/conf.d/10-mail.conf
    ```

    ```ini
    mail_location = maildir:/mnt/nas/mail/%n/Maildir
    ```

    Sur le serveur metis :
    ```bash
    tech@grestin.local@metis:/srv/raid5/share/mail$ sudo mkdir -p tech@grestin.local/Maildir/{cur,new,tmp,.Sent,.Trash,.Drafts}
    tech@grestin.local@metis:/srv/raid5/share/mail/tech@grestin.local$ sudo chown -R 1991401104:1991400513 Maildir/
    tech@grestin.local@metis:/srv/raid5/share/mail/tech@grestin.local$ sudo chmod -R 700 Maildir/
    ```

    ```bash
    tech@grestin.local@athena:~$ sudo systemctl restart dovecot
    tech@grestin.local@athena:~$ telnet localhost 143
    >> a login tech@grestin.local Sup1nf0
    >> a select INBOX
    ```


- ### Postfix

    ```bash
    tech@athena:~$ sudo apt install postfix mailutils -y 
    ```

    ```bash
    tech@athena:~$ sudo nano /etc/postfix/main.cf
    ```

    ```ini
    smtpd_banner = $myhostname internal mail server
    biff = no

    append_dot_domain = no
    readme_directory = no
    compatibility_level = 3.6

    smtpd_use_tls = no
    smtp_use_tls = no

    smtpd_relay_restrictions = permit_mynetworks reject_unauth_destination

    myhostname = athena.grestin.local
    mydomain = grestin.local
    myorigin = /etc/mailname
    mydestination = $myhostname, $mydomain, localhost.$mydomain, localhost
    mynetworks = 127.0.0.0/8 10.0.0.0/24

    inet_interfaces = all
    inet_protocols = ipv4

    home_mailbox = /mnt/nas/mail/%n/Maildir/
    smtpd_helo_required = yes
    ```

    ```bash
    tech@athena:~$ sudo systemctl restart postfix
    ```


