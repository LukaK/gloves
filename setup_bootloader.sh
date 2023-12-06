#!/usr/bin/env bash


function update_initramfs {
    echo "Updating initramfs"
    sed -i -e "/MODULES/s/()/(btrfs)/" -e "/HOOKS/s/block filesystems/block encrypt filesystems/" /etc/mkinitcpio.conf

    # NOTE: Issue with failing return code when everything is ok
    mkinitcpio -p linux || true
}

function set_root_password {
    echo "Updating root password"
    IFS= read -rs -p "Enter password:" password
    echo "root:$password" | chpasswd
}


function setup_bootloader {

    local disc="$1"
    local partition="$(fdisk -l $disc | tail -1 | awk '{print $1}')"
    local uuiddevice="$(blkid --output value ${partition} | head -n 1)"
    local uuidroot="$(blkid --output value /dev/mapper/root | head -n 1)"

    echo "Installing systemd bootloader"
    bootctl --path=/boot install

    echo "Configuring bootloader with following information"
    echo "partition: $partition"
    echo "uuiddevice: $uuiddevice"
    echo "uuidroot: $uuidroot"

    # update loader configuration
    printf "timeout 5\ndefault arch\n" > /boot/loader/loader.conf

    local arch_configuration="
        title Arch Linux
        linux /vmlinuz-linux
        initrd /initramfs-linux.img
        options cryptdevice=UUID=$uuiddevice:root root=UUID=$uuidroot rootflags=subvol=@ rw
    "
    echo "$arch_configuration" | sed -e '/^[[:space:]]*$/d' -e 's/^[[:space:]]*//' > /boot/loader/entries/arch.conf

    local arch_configuration="
        title Arch Linux Fallback
        linux /vmlinuz-linux
        initrd /initramfs-linux-fallback.img
        options cryptdevice=UUID=$uuiddevice:root root=UUID=$uuidroot rootflags=subvol=@ rw
    "
    echo "$arch_configuration" | sed -e '/^[[:space:]]*$/d' -e 's/^[[:space:]]*//' > /boot/loader/entries/arch-fallback.conf
}

function main {

    # exit 1 on any one failed command
    set -e
    set -o pipefail

    unset -v disc

    while getopts 'd:h' opt; do
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

    update_initramfs

    set_root_password

    setup_bootloader "$disc"
}

main "$@"
