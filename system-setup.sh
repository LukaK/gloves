#!/bin/bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
pushd $SCRIPT_DIR

# TODO: Add command line arguments and refactor
source ./environment.sh

PARTITION2="$(fdisk -l $DISK | tail -1 | awk '{print $1}')"

# TODO: Make one sed commands
# setup mkinitcpio
sed -i "/MODULES/s/()/(btrfs)/" /etc/mkinitcpio.conf
sed -i "/HOOKS/s/filesystems/encrypt filesystems/" /etc/mkinitcpio.conf
mkinitcpio -p linux

# setting root password
# TODO: Add read to this
echo root:$ROOT_PASSWORD | chpasswd
pacman -Sy sshd
systemctl enable sshd

# TODO: Add << EOF and create this without files
# configure bootloader
bootctl --path=/boot install
echo "timeout 5" >> /boot/loader/loader.conf
echo "default arch" >> /boot/loader/loader.conf
cp arch.conf /boot/loader/entries
sed -i "s/uuiddevice/$(blkid --output value ${PARTITION2} | head -n 1)/" /boot/loader/entries/arch.conf
sed -i "s/uuidroot/$(blkid --output value /dev/mapper/root | head -n 1)/" /boot/loader/entries/arch.conf
cp /boot/loader/entries/arch.conf /boot/loader/entries/arch-fallback.conf
sed -i "s/initramfs-linux.img/initramfs-linux-fallback.img/" /boot/loader/entries/arch-fallback.conf

popd
printf "\e[1;32mDone! Type exit, umount -R /mnt, reboot and run wingow-manager.sh.\e[0m"
