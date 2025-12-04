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
tech@metis:~$ sudo mkdir -p /srv/raid5
tech@metis:~$ sudo mount /dev/md0 /srv/raid5
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