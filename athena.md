# athena - Internal Server
Ubuntu 24.04.3 Live Server

Name : Technician
Server name : athena
username : tech
password : Sup1nf0 

cartes réseau :
VMnet8 (NAT)
VMnet10 (host-only) : 10.0.0.0/24

```bash
tech@athena:~$ sudo apt update
tech@athena:~$ sudo apt upgrade -y
```

## Installation XFCE

```bash
tech@athena:~$ sudo apt install xfce4 xfce4-goodies -y
tech@athena:~$ echo "exec startxfce4" >> .xinitrc
tech@athena:~$ echo "startx" >> .profile
tech@athena:~$ sudo apt remove lightdm -y
tech@athena:~$ reboot
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

## Mount NAS

```bash
tech@athena:~$ sudo apt install nfs-common -y
tech@athena:~$ sudo mkdir -p /mnt/nas
tech@athena:~$ sudo mount 10.0.0.20:/srv/raid5/share /mnt/nas
tech@athena:~$ sudo nano /etc/fstab
```
```text
10.0.0.20:/srv/raid5/share /mnt/nas nfs defaults,_netdev 0 0
```

## Mail Server

```bash
tech@athena:~$ sudo apt install postfix dovecot-core dovecot-imapd -y
```

- ### Postfix

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

    home_mailbox = /mnt/nas/share/mail/{$user}/Maildir/
    smtpd_helo_required = yes
    ```

    ```bash
    tech@athena:~$ sudo systemctl restart postfix
    ```

- ### Dovecot

    ```bash
    tech@athena:~$ sudo nano /etc/dovecot/dovecot.conf
    ```

    ```ini
    !include_try /usr/share/dovecot/protocols.d/*.protocol
    dict { 
    }
    !include conf.d/*.conf !include_try local.conf

    protocols = imap
    disable_plaintext_auth = no
    mail_location = maildir:/mnt/nas/share/mail/%u/Maildir
    ```

    ```bash
    tech@athena:~$ sudo systemctl restart dovecot
    ```

- ### Maildir

    ```bash
    tech@metis:~$ sudo mkdir -p /srv/raid5/share/mail/tech/Maildir/{cur,new,tmp}
    tech@metis:~$ sudo mkdir -p /srv/raid5/share/mail/tech/Maildir/.Drafts
    tech@metis:~$ sudo mkdir -p /srv/raid5/share/mail/tech/Maildir/.Sent
    tech@metis:~$ sudo mkdir -p /srv/raid5/share/mail/tech/Maildir/.Trash
    tech@metis:~$ sudo chown -R tech:tech sudo mkdir -p /srv/raid5/share/mail/tech/Maildir/
    tech@metis:~$ sudo chmod -R 700 sudo mkdir -p /srv/raid5/share/mail/tech/Maildir/
    ```

    ```bash
    tech@athena:~$ #Test de la boite mail
    tech@athena:~$ sudo apt install mailutils -y
    tech@athena:~$ echo "test body" | mail -s "test subject" tech
    tech@athena:~$ telnet localhost 143
    ```
    
    ```telnet
    Trying 127.0.0.1...
    Connected to localhost.
    Escape character is '^]'.
    * OK [CAPABILITY IMAP4rev1 SASL-IR LOGIN-REFERRALS ID ENABLE IDLE LITERAL+ STARTTLS AUTH=PLAIN] Dovecot (Ubuntu) ready.
    a login tech Sup1nf0
    a select INBOX
    a fetch 1 body[]
    ```