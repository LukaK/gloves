### Description

Resources for bootstraping uefi arch workstation.

Setup:
- creates 800M boot partition, the rest is alocated to encrypted btrfs root partition.
- setups boot loaders and boot resources
- installs core packages and enables core services
- creates basic system configuration ( locale, hostname, ... )
- creates ansible user and adds public key for ssh access

### Usage

```
bash install_system.sh -d <disc>
```
