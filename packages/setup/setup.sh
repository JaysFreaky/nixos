#!/usr/bin/env bash

set -e
BLUE="#00FFFF"
GREEN="#00FF00"
PINK="#FF00FF"
PURPLE="#8000FF"
RED="#FF0000"
YELLOW="#FFFF00"
WHITE="#FFFFFF"
export GUM_CHOOSE_CURSOR_FOREGROUND="$BLUE"
export GUM_CONFIRM_PROMPT_FOREGROUND="$RED"
export GUM_INPUT_PROMPT_FOREGROUND="$BLUE"
export GUM_SPIN_SPINNER="points"
export GUM_SPIN_SPINNER_FOREGROUND="$PURPLE"

if [[ $EUID -gt 0 ]]; then
  gum style --foreground="$YELLOW" "Error! This script requires root privileges. Please re-run as root."
  exit 1
fi
clear

# Get RAM size
RAM_SIZE=$(grep 'MemTotal' /proc/meminfo | cut -d':' -f2 | sed 's/ //g' | sed 's/kB//g' | numfmt --to=iec | sed 's/M//g')
# Round up to nearest integer
RAM_SIZE=$(printf %0.f "$RAM_SIZE")

# Show disks and their sizes
gum style --foreground="$GREEN" "Eligible disks and their stats:"
DISK_HEADER="$(lsblk -o name,size,mountpoints | grep 'NAME')"
gum style --foreground="$WHITE" "$DISK_HEADER"
lsblk -o name,size,mountpoints | grep 'nvme[0-9]n[0-9]\|sd[a-z]\|vd[a-z]\|hd[a-z]'
printf '\n'

# Put system disks into array
mapfile -t DISKS < <(find "/dev/" -regex '/dev/nvme[0-9]n[0-9]\|/dev/sd[a-z]\|/dev/vd[a-z]\|/dev/hd[a-z]')
if (( ${#DISKS[@]} == 0 )); then
  gum style --foreground="$YELLOW" "No disk devices were found! Quitting..." >&2
  exit 1
fi

# Prompt for disk from array
gum style --foreground="$PINK" "Select a disk to be formatted for installation:"
while true; do
  DISK=$(gum choose "${DISKS[@]}")
  if [ -z "$DISK" ]; then
    gum style --foreground="$RED" "A disk must be selected!" && printf '\n'
  else
    gum confirm "Are you sure you want to use $DISK?" --default=false && break || printf '\n'
  fi;
done
printf '\n'

# Prompt for swap location
gum style --foreground="$PINK" "If enabled, swap will be setup to match the amount of system RAM (""$RAM_SIZE""GB)"
while true; do
  SWAP_TYPE=$(gum choose "File" "Partition" "None")
  if [ -z "$SWAP_TYPE" ]; then
    gum style --foreground="$RED" "A swap type must be selected!" && printf '\n'
  else
    break
  fi;
done
printf '\n'

# Prompt for username
while true; do
  NIX_USER=$(gum input --placeholder="username" --prompt="What username is defined in NixOS? ")
  if [ -z "$NIX_USER" ]; then
    gum style --foreground="$RED" "Username cannot be blank!" && printf '\n'
  else
    break
  fi;
done

# Prompt for user password
while true; do
  NIX_PASS=$(gum input --password --placeholder="password" --prompt="What password would you like to assign to $NIX_USER? ")
  NIX_PASS2=$(gum input --password --placeholder="password" --prompt="Re-enter user password for verification: ")
  if [[ -z "$NIX_PASS" || -z "$NIX_PASS2" ]]; then
    gum confirm "Are you sure you don't want to set a user password?" --default=false && break
  elif [[ "$NIX_PASS" = "$NIX_PASS2" ]]; then
    break
  else
    gum style --foreground="$RED" "Passwords do not match! Please try again!" && printf '\n'
  fi;
done

# Prompt for GRUB password
gum style --background="$PINK" --foreground="$YELLOW" "The GRUB bootloader password will now be setup."
gum style --foreground="$WHITE" "If any action other than booting is performed, a password will be required before allowing access."
gum style --foreground="$WHITE" "Systemd is the default bootloader, but if GRUB is later enabled, it's ready to go with this."
printf '\n'
while true; do
  GRUB_PASS=$(gum input --password --placeholder="password" --prompt="What password would you like to assign to the GRUB bootloader? ")
  GRUB_PASS2=$(gum input --password --placeholder="password" --prompt="Re-enter GRUB password for verification: ")
  if [[ -z "$GRUB_PASS" || -z "$GRUB_PASS2" ]]; then
    gum style --foreground="$RED" "Password cannot be blank!" && printf '\n'
  elif [[ "$GRUB_PASS" = "$GRUB_PASS2" ]]; then
    break
  else
    gum style --foreground="$RED" "Passwords do not match! Please try again!" && printf '\n'
  fi;
done

# Prompt for cryptkey password
gum style --background="$PINK" --foreground="$YELLOW" "The first of two partition encryption passwords will now be setup."
gum style --foreground="$WHITE" "First, cryptkey, will be used at every boot to unlock the system partitions."
printf '\n'
while true; do
  CRYPTKEY_PASS=$(gum input --password --placeholder="cryptkey" --prompt="What will your cryptkey password be? ")
  CRYPTKEY_PASS2=$(gum input --password --placeholder="cryptkey" --prompt="Re-enter cryptkey password for verification: ")
  if [[ -z "$CRYPTKEY_PASS" || -z "$CRYPTKEY_PASS2" ]]; then
    gum style --foreground="$RED" "Password cannot be blank!" && printf '\n'
  elif [[ "$CRYPTKEY_PASS" = "$CRYPTKEY_PASS2" ]]; then
    break
  else
    gum style --foreground="$RED" "Passwords do not match! Please try again!" && printf '\n'
  fi;
done

# Prompt for cryptroot password
gum style --background="$PINK" --foreground="$YELLOW" "The second of two partition encryption passwords will now be setup."
gum style --foreground="$WHITE" "Second, cryptroot, will be an emergency backup password. (cryptkey partition gets corrupted, chroot, etc)"
gum style --foreground="$YELLOW" "This password should be different from the first. Be sure to document it somewhere safe!"
gum style --foreground="$WHITE" "Here are some generated diceware passwords using 6, 5, and 4 rolls, respectively."
echo "" > /tmp/dice.txt
{
  diceware | awk '{print "- " $0}'
  diceware -n 5 | awk '{print "- " $0}'
  diceware -n 4 | awk '{print "- " $0}'
} >> /tmp/dice.txt
gum format < /tmp/dice.txt
echo "" > /tmp/dice.txt
printf '\n'
while true; do
  CRYPTROOT_PASS=$(gum input --password --placeholder="cryptroot" --prompt="What will your cryptroot password be? ")
  CRYPTROOT_PASS2=$(gum input --password --placeholder="cryptroot" --prompt="Re-enter cryptroot password for verification: ")
  if [[ -z "$CRYPTROOT_PASS" || -z "$CRYPTROOT_PASS2" ]]; then
    gum style --foreground="$RED" "Password cannot be blank!" && printf '\n'
  elif [[ "$CRYPTROOT_PASS" = "$CRYPTROOT_PASS2" ]]; then
    break
  else
    gum style --foreground="$RED" "Passwords do not match! Please try again!" && printf '\n'
  fi;
done

# Prompt to start formatting
gum confirm "Are you ready to proceed with formatting?" --default=false || (echo "Quitting..." && exit 1)
printf '\n'


# Wipe disk / create GPT table
gum spin --show-output --title "Wiping disk..." -- wipefs --all --force "$DISK"
gum spin --show-output --title "Updating partition layout..." -- partprobe "$DISK" || true
gum spin --show-output --title "Creating partition table..." -- parted --align=opt --script "$DISK" mklabel gpt

# Create / format 1GiB EFI partition
gum spin --show-output --title "Creating boot partition..." -- parted --align=opt --script "$DISK" \
  mkpart "boot" fat32 0% 1024MiB \
  set 1 esp on
gum spin --show-output --title "Formatting boot partition..." -- mkfs.vfat -F 32 /dev/disk/by-partlabel/boot

# Create 32MiB key partition
gum spin --show-output --title "Creating LUKS key partition..." -- parted --align=opt --script "$DISK" mkpart "cryptkey" 1024MiB 1056MiB

# Create (optional) swap and/or root partition(s)
# Add 1056 for the 1024MiB boot/32MiB LUKS partitions
SWAP_SIZE=$((RAM_SIZE * 1024 + 1056))
if [ "$SWAP_TYPE" == 'Partition' ]; then
  gum spin --show-output --title "Creating LUKS swap & root partitions..." -- parted --align=opt --script "$DISK" \
    mkpart "cryptswap" linux-swap 1056MiB "$SWAP_SIZE"MiB \
    set 3 swap on \
    mkpart "cryptroot" btrfs "$SWAP_SIZE"MiB 90%
else
  gum spin --show-output --title "Creating LUKS root partition..." -- parted --align=opt --script "$DISK" mkpart "cryptroot" btrfs 1056MiB 90%
fi

# Create 10% reserved partition for SSD health - never mounted
gum spin --show-output --title "Creating reserved partition..." -- parted --align=opt --script "$DISK" mkpart "reserved" 90% 100%


# Encrypt key partition
gum spin --show-output --title "Encrypting key partition..." -- echo -n "$CRYPTKEY_PASS" | cryptsetup --batch-mode luksFormat /dev/disk/by-partlabel/cryptkey
# Maps partition to /dev/mapper/cryptkey
gum spin --show-output --title "Unlocking key partition..." -- echo -n "$CRYPTKEY_PASS" | cryptsetup --batch-mode luksOpen /dev/disk/by-partlabel/cryptkey cryptkey
# Stop the flake shell from halting upon dd write error
set +e
# Create random key
gum spin --title "Setting key partition as keyfile..." -- dd if=/dev/urandom of=/dev/mapper/cryptkey bs=1024 status=progress
# Resume error halting
set -e

# Encrypt (optional) swap partition
if [ "$SWAP_TYPE" == 'Partition' ]; then
  gum spin --show-output --title "Encrypting swap partition using key partition..." -- cryptsetup --batch-mode --key-file=/dev/mapper/cryptkey --keyfile-size=8192 luksFormat /dev/disk/by-partlabel/cryptswap
  # Maps partition to /dev/mapper/cryptswap
  gum spin --show-output --title "Unlocking swap partition..." -- cryptsetup --batch-mode --key-file=/dev/mapper/cryptkey --keyfile-size=8192 luksOpen /dev/disk/by-partlabel/cryptswap cryptswap
fi

# Encrypt root partition
gum spin --show-output --title "Encrypting root partition..." -- echo -n  "$CRYPTROOT_PASS" | cryptsetup --batch-mode luksFormat /dev/disk/by-partlabel/cryptroot
gum spin --show-output --title "Adding key partition as keyfile to root partition..." -- echo -n  "$CRYPTROOT_PASS" | cryptsetup --batch-mode --new-keyfile-size=8192 luksAddKey /dev/disk/by-partlabel/cryptroot /dev/mapper/cryptkey
# Maps partition to /dev/mapper/cryptroot
gum spin --show-output --title "Unlocking root partition..." -- cryptsetup --batch-mode --allow-discards --key-file=/dev/mapper/cryptkey --keyfile-size=8192 luksOpen /dev/disk/by-partlabel/cryptroot cryptroot
printf '\n'


# Format root partition
# 2nd formatting command has too much output, but doesn't display "Formatting..." because output is disabled, so display text prior to command running
gum spin --title "Formatting root partition..." -- sleep 1
gum spin --title "Formatting root partition..." -- mkfs.btrfs --label "nixos-fs" /dev/mapper/cryptroot
mkdir -p /mnt
gum spin --show-output --title "Mounting root partition for subvolume creation..." -- mount -t btrfs /dev/mapper/cryptroot /mnt

# Create subvolumes
gum spin --show-output --title "Creating root subvolume..." -- btrfs subvolume create /mnt/root
gum spin --show-output --title "Creating subvolumes..." -- btrfs subvolume create \
  /mnt/home \
  /mnt/nix \
  /mnt/persist \
  /mnt/log
if [ "$SWAP_TYPE" == 'File' ]; then
  gum spin --show-output --title "Creating swap subvolume..." -- btrfs subvolume create /mnt/swap
fi
# Empty, read-only snapshot used to potentially restore / at boot, if enabled
gum spin --show-output --title "Snapshotting empty root subvolume..." -- btrfs subvolume snapshot -r /mnt/root /mnt/root-blank
gum spin --show-output --title "Unmounting root partition..." -- umount /mnt
printf '\n'

# Mount subvolumes
gum spin --show-output --title "Mounting /..." -- mount -o subvol=root,compress=zstd,noatime /dev/mapper/cryptroot /mnt
mkdir -p /mnt/{boot,home,nix,persist,var/log}
gum spin --show-output --title "Mounting /boot to boot partition..." -- mount /dev/disk/by-partlabel/boot /mnt/boot
gum spin --show-output --title "Mounting /home..." -- mount -o subvol=home,compress=zstd /dev/mapper/cryptroot /mnt/home
gum spin --show-output --title "Mounting /nix..." -- mount -o subvol=nix,compress=zstd,noatime /dev/mapper/cryptroot /mnt/nix
gum spin --show-output --title "Mounting /persist..." -- mount -o subvol=persist,compress=zstd,noatime /dev/mapper/cryptroot /mnt/persist
gum spin --show-output --title "Mounting /var/log..." -- mount -o subvol=log,compress=zstd,noatime /dev/mapper/cryptroot /mnt/var/log

# Mount swap file/partition
if [ "$SWAP_TYPE" == 'File' ]; then
  mkdir -p /mnt/swap
  # BTRFS subvolumes currently inherit options from "/", so these options do nothing
  gum spin --show-output --title "Mounting /swap..." -- mount -o subvol=swap,compress=no,noatime,nodatacow,nodatasum /dev/mapper/cryptroot /mnt/swap
  # Bug where offset doesn't get calculated correctly on first file
  btrfs filesystem mkswapfile --size "$RAM_SIZE"G --uuid clear /mnt/swap/swapfile > /dev/null 2>&1
  rm -rf /mnt/swap/swapfile
  gum spin --show-output --title "Creating swapfile..." -- btrfs filesystem mkswapfile --size "$RAM_SIZE"G --uuid clear /mnt/swap/swapfile
  gum spin --show-output --title "Disabling copy-on-write for swapfile..." -- chattr +C /mnt/swap/swapfile
  # Swapfile hibernation variables to add to configuration
  SWAP_UUID=$(findmnt -no UUID -T /mnt/swap/swapfile)
  SWAP_OFFSET=$(btrfs inspect-internal map-swapfile -r /mnt/swap/swapfile)
  gum spin --show-output --title "Setting swapfile to on..." -- swapon /mnt/swap/swapfile
elif [ "$SWAP_TYPE" == 'Partition' ]; then
  gum spin --show-output --title "Setting swap partition as swap..." -- mkswap /dev/mapper/cryptswap
  gum spin --show-output --title "Setting swap partition to on..." -- swapon /dev/mapper/cryptswap
fi


# Create persistant folders for install files
gum spin --show-output --title "Creating persistant directories..." -- mkdir -p /mnt/etc/{nix,nixos,NetworkManager/system-connections,ssh} /mnt/persist/backups /mnt/persist/etc/{nix,nixos,NetworkManager/system-connections,secrets,ssh,users} /mnt/persist/var/lib/{bluetooth,flatpak,NetworkManager}
# Copy files to persist - be sure to remove these bind filesystems from potentially generated hardware-configuration.nix
gum spin --show-output --title "Binding local directories to persistant directories..." -- mount -o bind /mnt/persist/etc/nixos /mnt/etc/nixos
mount -o bind /mnt/persist/etc/nix /mnt/etc/nix
mount -o bind /mnt/persist/etc/NetworkManager /mnt/etc/NetworkManager
mount -o bind /mnt/persist/etc/ssh /mnt/etc/ssh

# Export cryptkey/root LUKS header files for backup
gum spin --show-output --title "Exporting key partition header..." -- cryptsetup --batch-mode --header-backup-file /mnt/persist/backups/cryptkey_header.img luksHeaderBackup /dev/disk/by-partlabel/cryptkey
gum spin --show-output --title "Exporting root partition header..." -- cryptsetup --batch-mode --header-backup-file /mnt/persist/backups/cryptroot_header.img luksHeaderBackup /dev/disk/by-partlabel/cryptroot
gum style --foreground="$YELLOW" "LUKS headers exported to '/persist/backups'!"
find /mnt/persist/backups/ -name "*.img"
sleep 3

# Set user password
gum spin --show-output --title "Creating password file for $NIX_USER..." -- echo -n "$NIX_PASS" | mkpasswd --method=SHA-512 --stdin > /mnt/persist/etc/users/"$NIX_USER"
gum spin --show-output --title "Setting 600 permissions on user password file..." -- chmod 600 /mnt/persist/etc/users/"$NIX_USER"

# Set GRUB password
gum spin --show-output --title "Creating password file for GRUB..." -- echo -e "$GRUB_PASS\n$GRUB_PASS" | grub-mkpasswd-pbkdf2 | awk '/grub.pbkdf/{print$NF}' > /mnt/persist/etc/users/grub
gum spin --show-output --title "Setting 600 permissions on GRUB password file..." -- chmod 600 /mnt/persist/etc/users/grub

# Generate NixOS configs
#nixos-generate-config --root /mnt

# Clone repo locally
gum spin --show-output --title "Cloning flake repo..." -- git clone --origin nixos https://github.com/jaysfreaky/nixos.git /mnt/persist/etc/nixos
cd /mnt/persist/etc/nixos
gum spin --show-output --title "Switching repo to SSH..." -- git remote set-url nixos git@github.com:JaysFreaky/nixos.git
printf '\n'
gum style --foreground="$GREEN" "Formatting / pre-installation setup complete!"
printf '\n'

# Prompt for system hostname from flake
gum style --foreground="$WHITE" "Once this system's hostname has been chosen, installation will begin."
mapfile -t HOSTS < <(grep "hostName" ./hosts/default.nix | cut -d '"' -f2)
if (( ${#HOSTS[@]} == 0 )); then
  gum style --foreground="$YELLOW" "No hostnames were declared in the flake! Quitting..." >&2
  exit 1
fi
while true; do
  gum style --foreground="$PINK" "Select a host to deploy:"
  NIX_HOST=$(gum choose "${HOSTS[@]}")
  if [ -z "$NIX_HOST" ]; then
    gum style --foreground="$RED" "A hostname must be selected!" && printf '\n'
  else
    gum confirm "Are you sure you want to use '$NIX_HOST'?" --default=false && break || printf '\n'
  fi;
done
printf '\n'

# Remove previous swap.nix repo file for a fresh slate
if [ -f /mnt/persist/etc/nixos/hosts/"$NIX_HOST"/swap.nix ]; then
  rm /mnt/persist/etc/nixos/hosts/"$NIX_HOST"/swap.nix
fi

# Create swap.nix file in host's directory
if [ "$SWAP_TYPE" == 'File' ]; then
  {
    echo '{ config, ... }:'
    echo '{'
    echo '  boot.kernelParams = [ "resume_offset='"$SWAP_OFFSET"'" ];'
    echo '  boot.resumeDevice = "/dev/disk/by-uuid/'"$SWAP_UUID"'";'
    echo '  fileSystems."/swap" = { device = "/dev/mapper/cryptroot"; fsType = "btrfs"; options = [ "subvol=swap" "compress=no" "noatime" "nodatacow" "nodatasum" ]; };'
    echo '  swapDevices = [ { device = "/swap/swapfile"; } ];'
    echo '}'
  } > /mnt/persist/etc/nixos/hosts/"$NIX_HOST"/swap.nix
elif [ "$SWAP_TYPE" == 'Partition' ]; then
  {
    echo '{ config, ... }:'
    echo '{'
    echo '  boot.initrd.luks.devices."cryptswap" = { device = "/dev/disk/by-partlabel/cryptswap"; keyFile = "/dev/mapper/cryptkey"; keyFileSize = 8192; };'
    echo '  boot.resumeDevice = "/dev/mapper/cryptswap";'
    echo '  swapDevices = [ { device = "/dev/mapper/cryptswap"; } ];'
    echo '}'
  } > /mnt/persist/etc/nixos/hosts/"$NIX_HOST"/swap.nix
fi


# Install NixOS
gum spin --show-output --title "Installing NixOS..." -- nixos-install --no-root-passwd --flake /mnt/persist/etc/nixos#"$NIX_HOST"
printf '\n'

# Delete unneeded system links from persistance
rm -rf /mnt/persist/etc/nix/{nix.conf,registry.json} /mnt/persist/etc/ssh/ssh_{config,known_hosts}

gum style --foreground="$YELLOW" "Remember to copy LUKS headers from '/persist/backups' to another device."
gum style --foreground="$GREEN" "Installation complete! Please reboot when ready."
