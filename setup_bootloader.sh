#!/usr/bin/env bash


# TODO: Change this so that it is idempotent
function update_initramfs {
    echo "Updating initramfs"
    sed -i -e "/MODULES/s/()/(btrfs)/" -e "/HOOKS/s/filesystems/encrypt filesystems/" /etc/mkinitcpio.conf
    mkinitcpio -p linux
}

function set_root_password {
    echo "Setting root password"
    chpasswd root
}

function setup_sshd {
    echo "Installing ssh daemon"
    pacman -Sy openssh

    echo "Enabling sshd"
    systemctl enable --now sshd
}

function setup_bootloader {

    local disc="$1"
    local partition="$(fdisk -l $disc | tail -1 | awk '{print $1}')"
    local uuiddevice="$(blkid --output value ${partition} | head -n 1)/"
    local uuidroot="$(blkid --output value /dev/mapper/root | head -n 1)/"

    echo "Installing systemd bootloader"
    bootctl --path=/boot install

    echo "Configuring bootloader with following information"
    echo "partition: $partition"
    echo "uuiddevice: $uuiddevice"
    echo "uuidroot: $uuidroot"

    # TODO: Check indentation
    echo >> /boot/loader/loader.conf << EOF
        timeout 5
        default arch
    EOF

    echo > /boot/loader/entries/arch.conf << EOF
        title Arch Linux
        linux /vmlinuz-linux
        initrd /initramfs-linux.img
        options cryptdevice=UUID=${uuiddevice}:root root=UUID=${uuidroot} rootflags=subvol=@ rw
    EOF

    echo > /boot/loader/entries/arch-fallback.conf << EOF
        title Arch Linux
        linux /vmlinuz-linux
        initrd /initramfs-linux-fallback.img
        options cryptdevice=UUID=$uuiddevice:root root=UUID=$uuidroot rootflags=subvol=@ rw
    EOF

}

function main {

    # exit 1 on any one failed command
    set -e
    set -o pipefail

    uset -v disc

    while getopts 'u:d:h' opt; do
        case "$opt" in
            d)
                declare -r disc="$OPTARG"
                ;;

            ?|h)
                echo "Usage: $(basename $0) -d disc [-h]"
                exit 1
                ;;
        esac
    done

    shift "$(($OPTIND -1))"

    if [ -z "$disc" ]; then
        echo "Missing -d argument"
        exit 1
    fi

    echo "System setup started"

    update_initramfs

    set_root_password

    setup_sshd

    setup_bootloader "$disc"

    echo "System setup completed successfully"
}

main()
