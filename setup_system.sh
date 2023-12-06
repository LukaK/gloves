#!/usr/bin/env bash

function setup_and_mount_filesystems {

    local disc="$1"

    echo "Partitioning the disk $disc"
    sgdisk -n 1:0:+800M -t 1:ef00 -n 2:801M $disc

    local partition_1="$(fdisk -l $disc | tail -2 | head -1 | awk '{print $1}')"
    local partition_2="$(fdisk -l $disc | tail -1 | awk '{print $1}')"

    # format the disks
    echo "Formatting boot partition: ${partition_1}"
    mkfs.fat -F32 "${partition_1}"

    echo "Encrypting root partition: ${partition_2}"
    cryptsetup --cipher aes-xts-plain64 --hash sha512 --use-random --verify-passphrase luksFormat "${partition_2}"
    cryptsetup luksOpen "${partition_2}" root

    echo "Formatting root partition"
    mkfs.btrfs /dev/mapper/root

    # create subvolumes
    echo "Creating btrfs subvolumes"
    mount /dev/mapper/root /mnt
    pushd /mnt && btrfs subvolume create @ && btrfs subvolume create @home && popd
    umount /mnt

    echo "Mounting partitions"

    mount -o noatime,space_cache=v2,compress=zstd,ssd,discard=async,subvol=@ /dev/mapper/root /mnt
    mkdir /mnt/{boot,home}
    mount -o noatime,space_cache=v2,compress=zstd,ssd,discard=async,subvol=@home /dev/mapper/root /mnt/home
    mount "${partition_1}" /mnt/boot

}

function bootstrap_system {

    echo "Bootstraping the system"

    local ucode_package="intel-ucode"
    if [ "$(lscpu | grep 'AMD')" ];
    then
        ucode_package="amd-ucode"
    fi
    echo "Processor package selected: ${ucode_package}"

    pacstrap /mnt base linux linux-firmware git vim $ucode_package
    genfstab -U /mnt >> /mnt/etc/fstab
}


# TODO: Add chroot to this shell with exec
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

    setup_and_mount_filesystems ${disc}

    bootstrap_system

}

main()
