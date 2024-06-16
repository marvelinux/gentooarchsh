#!/bin/bash
echo script must be run with internet connection on efi system
sleep 5
echo "checking if gentoo"
uname -rv > /uname.txt
if ! grep -q "gentoo" /uname.txt
then
echo not gentoo
rm /uname.txt
lsblk
echo "enter your main drive (for example /dev/sda1):"
read drive-name
echo "What do you need to do in cf disk"
echo 1G Linux partition
echo [your ram size] swap partition
echo "last partition Linux - for the system"
cfdisk {$drive-name}
echo "enter preffered Linux partition type:"
read partition-name
if "$drive-name" != "/dev/sda" && "$drive-name" != "/dev/sdd"
then
mkfs.fat -F 32 {$drive-name}p1
mkfs.{$partition-name} {$drive-name}p3
mkswap {$drive-name}p2
swapon {$drive-name}p2
mkdir --parents /mnt/gentoo/efi
mount {$drive-name}p3 /mnt/gentoo

else
mkfs.fat -F 32 {$drive-name}1
mkfs.{$partition-name} {$drive-name}3
mkswap {$drive-name}2
swapon {$drive-name}2
mkdir --parents /mnt/gentoo/efi
mount {$drive-name}3 /mnt/gentoo
fi
cd /mnt/gentoo
curl -O https://distfiles.gentoo.org/releases/amd64/autobuilds/current-stage3-amd64-desktop-openrc/stage3-amd64-desktop-openrc-20240609T164903Z.tar.xz
cp ~/script.sh /mnt/gentoo/script.sh
tar xpvf stage3-*.tar.xz --xattrs-include='*.*' --numeric-owner
mount --types proc /proc /mnt/gentoo/proc
mount --rbind /sys /mnt/gentoo/sys
mount --make-rslave /mnt/gentoo/sys
mount --rbind /dev /mnt/gentoo/dev
mount --make-rslave /mnt/gentoo/dev
mount --bind /run /mnt/gentoo/run
mount --make-slave /mnt/gentoo/run
echo DONE, chrooting
chroot /mnt/gentoo /bin/bash
else
echo gentoo
rm /uname.txt
mkdir /efi
echo "enter your first partition (for example: /dev/sda1)"
read first-partition
mount {%first-partition} /efi
emerge-webrsync
emerge --sync
emerge --info | grep ^USE >> /etc/portage/make.conf
echo change use flags and opts
sleep 5
nano /etc/portage/make.conf
echo ACCEPT-LICENCE="*.*" >> /etc/portage/make.conf
emerge --ask --verbose --update --deep --newuse @world
emerge --ask --pretend --depclean
echo is everything OK?
read isok
emerge --ask --depclean
echo your timezone
read timezone
echo "$timezone" > /etc/timezone
eselect locale list | less
echo your locale (num)
read locale
eselect locale set {$locale}
env-update && source /etc/profile && export PS1="(chroot) ${PS1}"
emerge --ask sys-kernel/linux-firmware
emerge --ask sys-firmware/sof-firmware
emerge --ask sys-firmware/intel-microcode
echo do rest yourself
fi
