#!/bin/bash


# change directory to scripts directory
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
pushd $SCRIPT_DIR

# source environment variables
source ./environment.sh

# partition the disk
echo "Partitioning the disk $DISK..."
sgdisk -n 1:0:+800M -t 1:ef00 -n 2:801M $DISK

PARTITION1="$(fdisk -l $DISK | tail -2 | head -1 | awk '{print $1}')"
PARTITION2="$(fdisk -l $DISK | tail -1 | awk '{print $1}')"

# format the disks
echo "Formatting the disk..."
mkfs.fat -F32 "${PARTITION1}"
cryptsetup --cipher aes-xts-plain64 --hash sha512 --use-random --verify-passphrase luksFormat "${PARTITION2}"
cryptsetup luksOpen "${PARTITION2}" root
mkfs.btrfs /dev/mapper/root

# create subvolumes
echo "Creating btrfs subvolumes..."
mount /dev/mapper/root /mnt
pushd /mnt
btrfs subvolume create @
btrfs subvolume create @home
popd
umount /mnt

# mount subvolumes
echo "Mounting partitions to /mnt..."
mount -o noatime,space_cache=v2,compress=zstd,ssd,discard=async,subvol=@ /dev/mapper/root /mnt
mkdir /mnt/{boot,home}
mount -o noatime,space_cache=v2,compress=zstd,ssd,discard=async,subvol=@home /dev/mapper/root /mnt/home
mount "${PARTITION1}" /mnt/boot

# base system
echo "Pacstraping the system..."
UCODE_PACKAGE="intel-ucode"
if [ $PROCESSOR_TYPE == 'AMD' ]; then
    UCODE_PACKAGE="amd-ucode"
fi
pacstrap /mnt base linux linux-firmware git vim $UCODE_PACKAGE
genfstab -U /mnt >> /mnt/etc/fstab

# copy directory for easy access
cp -r /root/pinguine /mnt

printf "\e[1;32mDone! Use arch-chroot /mnt and run system-setup.sh\e[0m"
