#!/bin/sh

pacman --noconfirm --needed -S libnewt || { echo "Error at script start: Are you sure you're running this as the root user? Are you sure you have an internet connection?"; exit; }

whiptail --backtitle "Artix Installer" --title "DON'T BE A BRAINLET!" --yes-button "Continue" --no-button "Return..." --defaultno \
	--yesno "This is an Artix install script that is very rough around the edges.\\n\\nOnly run this script if you're a big-brane who doesn't mind deleting your entire drive.\\n\\nadd003" 0 0 || exit

comp=$(whiptail --backtitle "Artix Installer" --title "Hostname" --nocancel --output-fd 1 --inputbox "Enter a name for your computer." 0 0)

dpath=$(whiptail --backtitle "Artix Installer" --title "Diskpath" --output-fd 1 --menu "Choose one of:" 0 0 2 1 "/dev/sda" 2 "/dev/nvme0n1")

case "$dpath" in
	1) dpath=("/dev/sda" "/dev/sda") ;;
	2) dpath=("/dev/nvme0n1" "/dev/nvme0n1p") ;;
	*) echo "Error at parsing disk path?" || exit ;;
esac

initnum=$(whiptail --backtitle "Artix Installer" --title "Initsystem" --output-fd 1 --menu "Choose one of:" 0 0 4 1 "openrc" 2 "runit" 3 "s6" 4 "dinit")

case "$initnum" in
	1) sysinit=("openrc" "openrc") ;;
	2) sysinit=("runit" "runit") ;;
	3) sysinit=("s6-base" "s6") ;;
	4) sysinit=("dinit" "dinit") ;;
	*) sysinit=("runit" "runit") ;;
esac

echo "Europe/Berlin" > tz.tmp || tzselect > tz.tmp

whiptail --backtitle "Artix Installer" --title "Partition disk" --nocancel --inputbox "Enter partitionsize in gb, separated by space (swap & root)." 0 0 2>psize

IFS=' ' read -ra SIZE <<< "$(cat psize)"

re='^[0-9]+$'
if ! [ ${#SIZE[@]} -eq 2 ] || ! [[ ${SIZE[0]} =~ $re ]] || ! [[ ${SIZE[1]} =~ $re ]] ; then
	SIZE=(12 35);
fi

wipefs -a "${dpath[0]}" >/dev/null 2>&1 && cat <<EOF | fdisk -W always "${dpath[0]}"
g
n


+400M
t
1
n


+${SIZE[0]}G
t

19
n


+${SIZE[1]}G
n



w
EOF
partprobe

yes | mkfs.ext4 -L HOME "${dpath[1]}"4
yes | mkfs.ext4 -L ROOT "${dpath[1]}"3
yes | mkfs.fat -F 32 "${dpath[1]}"1
fatlabel "${dpath[1]}"1 BOOT
mkswap -L SWAP "${dpath[1]}"2
swapon "${dpath[1]}"2
mount "${dpath[1]}"3 /mnt
mkdir -p /mnt/boot/efi
mount "${dpath[1]}"1 /mnt/boot/efi
mkdir -p /mnt/home
mount "${dpath[1]}"4 /mnt/home

basestrap /mnt base base-devel linux linux-firmware intel-ucode efibootmgr grub\
	"${sysinit[0]}" elogind-"${sysinit[1]}" dhcpcd-"${sysinit[1]}" networkmanager-"${sysinit[1]}" openntpd-"${sysinit[1]}" openssh-"${sysinit[1]}"


fstabgen -U /mnt >> /mnt/etc/fstab
cat tz.tmp > /mnt/tzfinal.tmp
echo "${comp}" > /mnt/compname.tmp
curl https://gitlab.com/add003/artixinst/-/raw/main/chroot.sh > /mnt/chroot.sh && artix-chroot /mnt sh chroot.sh
