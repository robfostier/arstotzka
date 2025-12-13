# metis - Network Attached Storage
Ubuntu 24.04.3 Live Server

Name : Technician
Server name : metis
username : tech
password : Sup1nf0 

cartes réseau :
VMnet8 (NAT)
VMnet10 (host-only) : 10.0.0.0/24

```bash
tech@metis:~$ sudo apt update
tech@metis:~$ sudo apt upgrade -y
```

## Installation XFCE

```bash
tech@metis:~$ sudo apt install xfce4 xfce4-goodies -y
tech@metis:~$ echo "exec startxfce4" >> .xinitrc
tech@metis:~$ echo "startx" >> .profile
tech@metis:~$ sudo apt remove lightdm -y
tech@metis:~$ reboot
```

## Configuration Host-only

```bash
tech@metis:~$ sudo nano /etc/netplan/50-cloud-init.yaml
```

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

```bash
tech@metis:~$ sudo netplan apply
```

## RAID 5

4 disques durs virtuels de 2GB chacun sont ajoutés sur le serveur à froid.

```bash
tech@metis:~$ sudo apt install mdadm -y
tech@metis:~$ sudo parted /dev/sdb mklabel gpt
tech@metis:~$ sudo parted /dev/sdc mklabel gpt
tech@metis:~$ sudo parted /dev/sdd mklabel gpt
tech@metis:~$ sudo parted /dev/sde mklabel gpt
tech@metis:~$ sudo mdadm --create --verbose /dev/md0 --level=5 --raid-devices=4 /dev/sdb /dev/sdc /dev/sdd /dev/sde
tech@metis:~$ sudo mkfs.ext4 /dev/md0
tech@metis:~$ sudo mdadm --detail --scan | sudo tee /etc/mdadm/mdadm.conf
tech@metis:~$ sudo update-initramfs -u
tech@metis:~$ sudo mkdir -p /srv/raid5
tech@metis:~$ sudo mount /dev/md0 /srv/raid5
tech@metis:~$ echo "/dev/md0 /srv/raid5 ext4 defaults 0 2" >> /etc/fstab
```

## NAS

```bash
tech@metis:~$ sudo apt install nfs-kernel-server -y
tech@metis:~$ sudo mkdir /srv/raid5/share
tech@metis:~$ sudo chown nobody:nogroup /srv/raid5/share
tech@metis:~$ sudo chmod 777 /srv/raid5/share
tech@metis:~$ sudo nano /etc/exports
```

```text
/srv/raid5/share 10.0.0.30(rw,sync,no_subtree_check)
```

```bash
tech@metis:~$ sudo exportfs -ra
tech@metis:~$ sudo systemctl restart nfs-kernel-server
```

## File Structure

```bash
tech@metis:/srv/raid5/share$ mkdir cases mail scripts 
tech@metis:/srv/raid5/share/cases$ mkdir pending accepted rejected
```

## Configuraton Active Directory

```bash
tech@metis:~$ sudo apt install realmd sssd adcli samba-common-bin krb5-user packagekit -y
tech@metis:~$ sudo nano /etc/hosts
```

```
10.0.0.10 hermes.grestin.local hermes
```

```bash
tech@metis:~$ sudo nano /etc/resolv.conf
```

```
nameserver 10.0.0.10
```

```bash
tech@metis:~$ kinit Administrator
tech@metis:~$ klist
tech@metis:~$ sudo realm join --user=Administrator GRESTIN.LOCAL
tech@metis:~$ sudo nano /etc/sssd/sssd.conf
```

```ini
[sssd]
domains = grestin.local
config_file_version = 2
services = nss, pam

[domain/grestin.local]
default_shell = /bin/bash
krb5_store_password_if_offline = True
cache_credentials = True
krb5_realm = GRESTIN.LOCAL
realmd_tags = manages-system joined-with-adcli
id_provider = ad
fallback_homedir = /home/%u%d
ad_domain = grestin.local
use_fully_qualified_names = True
ldap_id_mapping = True
access_provider = ad
auth_provider = ad

enumerate = True
```

```bash
tech@metis:~$ echo "tech@GRESTIN.LOCAL ALL=(ALL) ALL" >> /etc/sudoers.d/ad-tech
tech@metis:~$ echo "session required pam_mkhomedir.so skel=/etc/skel/ umask=0077" >> /etc/pam.d/common-session
tech@metis:~$ echo "session required pam_mkhomedir.so skel=/etc/skel/ umask=0077" >> /etc/pam.d/common-session-noninteractive
tech@metis:~$ sudo systemctl restart sssd
tech@metis:~$ sudo sss_cache -E
tech@metis:~$ su -t tech@grestin.local
```