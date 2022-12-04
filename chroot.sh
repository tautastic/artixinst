#!/bin/sh

passwd

TZuser=$(cat tzfinal.tmp) && rm tzfinal.tmp
COMPname=$(cat compname.tmp) && rm compname.tmp

ln -sf /usr/share/zoneinfo/"$TZuser" /etc/localtime

hwclock --systohc

echo \
"127.0.0.1	localhost
::1		localhost
127.0.1.1	${COMPname}.localdomain	${COMPname}"\
> /etc/hosts

echo "${COMPname}" > /etc/hostname

echo "en_US.UTF-8 UTF-8" > /etc/locale.gen
echo "de_DE.UTF-8 UTF-8" >> /etc/locale.gen
echo "export LANG=en_US.UTF-8" > /etc/locale.conf
echo 'export LC_COLLATE="C"' >> /etc/locale.conf
echo "KEYMAP=us" > /etc/vconsole.conf
locale-gen

grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB && grub-mkconfig -o /boot/grub/grub.cfg

pacman --noconfirm --needed -S libnewt wget

larbs() { curl -O https://gitlab.com/add003/artixinst/-/raw/main/larbs.sh && sh larbs.sh ;}
whiptail --title "Install add03's Rice?" --yesno "This install script will easily let you access add003's Auto-Rice Boostrapping Script which automatically install a full Artix Linux dwm desktop environment.\n\nIf you would like to install this, select yes, otherwise select no.\n\nadd003" 0 0 && larbs
