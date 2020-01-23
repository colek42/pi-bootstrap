Sealed Secrets



Nodes

172.4.20.2   Master RPi4
172.4.21.13   Worker RPi4
172.4.21.14   Worker RPi4
172.4.21.15   Worker RPi4


#Flash Ubuntu
xzcat /home/nkennedy/Downloads/ubuntu-19.10.1-preinstalled-server-arm64+raspi3.img.xz | dd of=/dev/sda bs=32M

sync

#Enable SSH

remount, touch ssh


#Install containerd

#Setup netplan
$ cd /etc/netplan/
$ ls
01-network-manager-all.yaml


xzcat /home/nkennedy/Downloads/ubuntu-19.10.1-preinstalled-server-arm64+raspi3.img.xz | sudo dd of=/dev/sda bs=32M && sync && touch /media/nkennedy/system-boot/ssh