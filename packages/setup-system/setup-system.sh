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
export GUM_CONFIRM_SELECTED_FOREGROUND="$BLUE"
export GUM_INPUT_PROMPT_FOREGROUND="$BLUE"
export GUM_SPIN_SPINNER="points"
export GUM_SPIN_SPINNER_FOREGROUND="$PURPLE"

if [[ $EUID != 0 ]]; then
  gum style --foreground="$YELLOW" "Error! This script requires root privileges. Please re-run as root."
  exit 1
fi
clear

# Set timezone (for git)
timedatectl set-timezone 'America/Chicago'

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
mapfile -t DISKS < <(find "/dev/" -regex '/dev/nvme[0-9]n[0-9]\|/dev/sd[a-z]\|/dev/vd[a-z]\|/dev/hd[a-z]' | sort)
if (( ${#DISKS[@]} == 0 )); then
  gum style --foreground="$YELLOW" "No disk devices were found! Quitting..." >&2
  exit 1
fi

# Prompt for disk from array
gum style --foreground="$PINK" "Select a disk to be formatted for installation:"
while true; do
  DISK=$(gum choose "${DISKS[@]}")
  if [ -z "$DISK" ]; then
    gum style --foreground="$YELLOW" "A disk must be selected!" && printf '\n'
  else
    gum confirm "Are you sure you want to use $DISK?" --default=false && break || printf '\n'
  fi
done
printf '\n'

# Prompt for swap location
gum style --foreground="$PINK" "If enabled, swap will be setup to match the amount of system RAM (""$RAM_SIZE""GB)"
while true; do
  SWAP_TYPE=$(gum choose "File" "Partition" "None")
  if [ -z "$SWAP_TYPE" ]; then
    gum style --foreground="$YELLOW" "A swap type must be selected!" && printf '\n'
  else
    break
  fi
done
printf '\n'

# Prompt for username
while true; do
  NIX_USER=$(gum input --placeholder="username" --prompt="What username is defined in NixOS? ")
  if [ -z "$NIX_USER" ]; then
    gum style --foreground="$YELLOW" "Username cannot be blank!" && printf '\n'
  else
    break
  fi
done

# Prompt for user password
while true; do
  NIX_PASS=$(gum input --password --placeholder="password" --prompt="What password would you like to assign to $NIX_USER? ")
  NIX_PASS2=$(gum input --password --placeholder="password" --prompt="Re-enter user password for verification: ")
  if [ -z "$NIX_PASS" ] || [ -z "$NIX_PASS2" ]; then
    gum confirm "Are you sure you don't want to set a user password?" --default=false && break
  elif [ "$NIX_PASS" = "$NIX_PASS2" ]; then
    break
  else
    gum style --foreground="$YELLOW" "Passwords do not match! Please try again!" && printf '\n'
  fi
done

# Prompt for GRUB password
gum style --background="$PINK" --foreground="$WHITE" "The GRUB bootloader password will now be setup."
gum style --foreground="$WHITE" "If any action other than booting is performed, a password will be required before allowing access."
gum style --foreground="$WHITE" "Systemd is the default bootloader, but if GRUB is later enabled, it's ready to go with this."
printf '\n'
while true; do
  GRUB_PASS=$(gum input --password --placeholder="password" --prompt="What password would you like to assign to the GRUB bootloader? ")
  GRUB_PASS2=$(gum input --password --placeholder="password" --prompt="Re-enter GRUB password for verification: ")
  if [ -z "$GRUB_PASS" ] || [ -z "$GRUB_PASS2" ]; then
    gum style --foreground="$YELLOW" "Password cannot be blank!" && printf '\n'
  elif [ "$GRUB_PASS" = "$GRUB_PASS2" ]; then
    break
  else
    gum style --foreground="$YELLOW" "Passwords do not match! Please try again!" && printf '\n'
  fi
done

# Prompt for encryption
gum confirm "Would you like to enable encryption?" && ENCRYPT="YES" || ENCRYPT="NO"

# If using encryption, prompt for passwords
if [ "$ENCRYPT" = 'YES' ]; then
  # Prompt for cryptkey password
  gum style --background="$PINK" --foreground="$WHITE" "The first of two partition encryption passwords will now be setup."
  gum style --foreground="$WHITE" "First, cryptkey, will be used at every boot to unlock the system partitions."
  printf '\n'
  while true; do
    CRYPTKEY_PASS=$(gum input --password --placeholder="cryptkey" --prompt="What will your cryptkey password be? ")
    CRYPTKEY_PASS2=$(gum input --password --placeholder="cryptkey" --prompt="Re-enter cryptkey password for verification: ")
    if [ -z "$CRYPTKEY_PASS" ] || [ -z "$CRYPTKEY_PASS2" ]; then
      gum style --foreground="$YELLOW" "Password cannot be blank!" && printf '\n'
    elif [ "$CRYPTKEY_PASS" = "$CRYPTKEY_PASS2" ]; then
      break
    else
      gum style --foreground="$YELLOW" "Passwords do not match! Please try again!" && printf '\n'
    fi
  done

  # Prompt for cryptroot password
  gum style --background="$PINK" --foreground="$WHITE" "The second of two partition encryption passwords will now be setup."
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
    if [ -z "$CRYPTROOT_PASS" ] || [ -z "$CRYPTROOT_PASS2" ]; then
      gum style --foreground="$YELLOW" "Password cannot be blank!" && printf '\n'
    elif [ "$CRYPTROOT_PASS" = "$CRYPTROOT_PASS2" ]; then
      break
    else
      gum style --foreground="$YELLOW" "Passwords do not match! Please try again!" && printf '\n'
    fi
  done
fi

# Prompt to start formatting
gum confirm "Are you ready to proceed with formatting?" --default=false || (echo "Quitting..." && exit 1)
printf '\n'

##########################################################
# Wipe disk / create GPT table
gum spin --show-output --title "Wiping disk..." -- wipefs --all --force "$DISK"
gum spin --show-output --title "Updating partition layout..." -- partprobe "$DISK" || true
gum spin --show-output --title "Creating partition table..." -- parted --align=opt --script "$DISK" mklabel gpt

# Create / format 1GiB EFI partition
gum spin --show-output --title "Creating boot partition..." -- parted --align=opt --script "$DISK" \
  mkpart "boot" fat32 0% 1024MiB \
  set 1 esp on
gum spin --show-output --title "Formatting boot partition..." -- mkfs.vfat -F 32 /dev/disk/by-partlabel/boot

# Create 32MiB key partition; first 16MiB are LUKS header data
if [ "$ENCRYPT" = 'YES' ]; then
  # 1024MiB boot + 32MiB LUKS key = 1056MiB
  gum spin --show-output --title "Creating LUKS key partition..." -- parted --align=opt --script "$DISK" mkpart "key" 1024MiB 1056MiB
  BOOT_SIZE=1056
  SWAP_PART=3
else
  BOOT_SIZE=1024
  SWAP_PART=2
fi

# Create swap and root partition(s), then leave remaining 10% of disk for SSD health
if [ "$SWAP_TYPE" = 'Partition' ]; then
  SWAP_SIZE=$((RAM_SIZE * 1024 + BOOT_SIZE))
  gum spin --show-output --title "Creating swap & root partitions..." -- parted --align=opt --script "$DISK" \
    mkpart "swap" linux-swap "$BOOT_SIZE"MiB "$SWAP_SIZE"MiB \
    set "$SWAP_PART" swap on \
    mkpart "root" btrfs "$SWAP_SIZE"MiB 90%
else
  gum spin --show-output --title "Creating root partition..." -- parted --align=opt --script "$DISK" mkpart "root" btrfs "$BOOT_SIZE"MiB 90%
fi

##########################################################
# Setup LUKS encryption and disk path variables
if [ "$ENCRYPT" = 'YES' ]; then
  # Encrypt key partition - 16MiB remaining; max keysize is 8192KiB (8MiB)
  gum spin --show-output --title "Encrypting key partition..." -- echo -n "$CRYPTKEY_PASS" | cryptsetup --batch-mode luksFormat /dev/disk/by-partlabel/key
  # Maps partition to /dev/mapper/cryptkey
  gum spin --show-output --title "Unlocking key partition..." -- echo -n "$CRYPTKEY_PASS" | cryptsetup --batch-mode luksOpen /dev/disk/by-partlabel/key cryptkey
  # Create random key
  gum spin --show-output --title "Setting key partition as keyfile..." -- dd if=/dev/random of=/dev/mapper/cryptkey bs=1MiB count=8 iflag=fullblock status=progress
  gum spin --show-output --title "Setting 600 permissions on keyfile..." -- chmod 600 /dev/mapper/cryptkey

  # Encrypt (optional) swap partition
  if [ "$SWAP_TYPE" = 'Partition' ]; then
    gum spin --show-output --title "Encrypting swap partition using key partition..." -- cryptsetup --batch-mode luksFormat /dev/disk/by-partlabel/swap --key-file /dev/mapper/cryptkey --keyfile-size 8192
    gum spin --show-output --title "Unlocking swap partition..." -- cryptsetup --batch-mode luksOpen /dev/disk/by-partlabel/swap cryptswap --key-file /dev/mapper/cryptkey --keyfile-size 8192
  fi

  # Encrypt root partition
  gum spin --show-output --title "Encrypting root partition..." -- echo -n  "$CRYPTROOT_PASS" | cryptsetup --batch-mode luksFormat /dev/disk/by-partlabel/root
  gum spin --show-output --title "Adding key partition as keyfile to root partition..." -- echo -n  "$CRYPTROOT_PASS" | cryptsetup --batch-mode luksAddKey /dev/disk/by-partlabel/root /dev/mapper/cryptkey --new-keyfile-size 8192
  gum spin --show-output --title "Unlocking root partition..." -- cryptsetup --batch-mode luksOpen /dev/disk/by-partlabel/root cryptroot --key-file /dev/mapper/cryptkey --keyfile-size 8192
  printf '\n'
  SWAP_PATH="/dev/mapper/cryptswap"
  ROOT_PATH="/dev/mapper/cryptroot"
else
  SWAP_PATH="/dev/disk/by-partlabel/swap"
  ROOT_PATH="/dev/disk/by-partlabel/root"
fi

# Format root partition
gum spin --show-output --title "Formatting root partition..." -- mkfs.btrfs --force --label "NixOS" "$ROOT_PATH"

# Create subvolumes
mkdir -p /mnt
gum spin --show-output --title "Mounting root partition for subvolumes..." -- mount -t btrfs "$ROOT_PATH" /mnt
gum spin --show-output --title "Creating root subvolume..." -- btrfs subvolume create /mnt/root
gum spin --show-output --title "Creating subvolumes..." -- btrfs subvolume create \
  /mnt/home \
  /mnt/nix
if [ "$SWAP_TYPE" = 'File' ]; then
  gum spin --show-output --title "Creating swap subvolume..." -- btrfs subvolume create /mnt/swap
  # Bug where offset doesn't get calculated correctly on first file
  btrfs filesystem mkswapfile --size "$RAM_SIZE"G --uuid clear /mnt/swap/swapfile > /dev/null 2>&1
  rm -rf /mnt/swap/swapfile
  gum spin --show-output --title "Creating swapfile..." -- btrfs filesystem mkswapfile --size "$RAM_SIZE"G --uuid clear /mnt/swap/swapfile
fi
# Empty, read-only snapshot used to potentially restore / at boot, if enabled
gum spin --show-output --title "Snapshotting empty root subvolume..." -- btrfs subvolume snapshot -r /mnt/root /mnt/root-blank
gum spin --show-output --title "Unmounting root partition..." -- umount /mnt
printf '\n'

# Mount subvolumes
gum spin --show-output --title "Mounting /..." -- mount -o subvol=root,compress=zstd,noatime "$ROOT_PATH" /mnt
mkdir -p /mnt/{boot,home,nix}
gum spin --show-output --title "Mounting /boot to boot partition..." -- mount /dev/disk/by-partlabel/boot /mnt/boot
gum spin --show-output --title "Mounting /home..." -- mount -o subvol=home,compress=zstd "$ROOT_PATH" /mnt/home
gum spin --show-output --title "Mounting /nix..." -- mount -o subvol=nix,compress=zstd,noatime "$ROOT_PATH" /mnt/nix

# Mount swap file/partition
if [ "$SWAP_TYPE" = 'File' ]; then
  mkdir -p /mnt/swap
  # BTRFS subvolumes currently inherit options from "/"; mkswapfile sets +C attribute (disables copy-on-write) | 'lsattr' can verify +C attribute was added
  gum spin --show-output --title "Mounting /swap..." -- mount -o subvol=swap,compress=no,noatime "$ROOT_PATH" /mnt/swap
  # Swapfile hibernation variables to add to swap.nix
  SWAP_UUID=$(findmnt -no UUID -T /mnt/swap/swapfile)
  SWAP_OFFSET=$(btrfs inspect-internal map-swapfile -r /mnt/swap/swapfile)
  gum spin --show-output --title "Setting swapfile to on..." -- swapon /mnt/swap/swapfile
elif [ "$SWAP_TYPE" = 'Partition' ]; then
  gum spin --show-output --title "Setting swap partition as swap..." -- mkswap "$SWAP_PATH"
  gum spin --show-output --title "Setting swap partition to on..." -- swapon "$SWAP_PATH"
fi

##########################################################
# Export key/root LUKS header files for backup, if encryption enabled
if [ "$ENCRYPT" = 'YES' ]; then
  gum spin --show-output --title "Creating luksBackup directory..." -- mkdir -p /mnt/home/"$NIX_USER"/luksBackup
  gum spin --show-output --title "Exporting key partition header..." -- cryptsetup --batch-mode luksHeaderBackup /dev/disk/by-partlabel/key --header-backup-file /mnt/home/"$NIX_USER"/luksBackup/cryptkey_header.img
  gum spin --show-output --title "Exporting root partition header..." -- cryptsetup --batch-mode luksHeaderBackup /dev/disk/by-partlabel/root --header-backup-file /mnt/home/"$NIX_USER"/luksBackup/cryptroot_header.img
  gum style --foreground="$PINK" "LUKS headers exported to '/mnt/home/""$NIX_USER""/luksBackup'"
  find /mnt/home/"$NIX_USER"/luksBackup/ -name "*.img"
fi

# Set passwords
mkdir -p /mnt/etc/users
gum spin --show-output --title "Creating password file for $NIX_USER..." -- echo -n "$NIX_PASS" | mkpasswd --method=SHA-512 --stdin > /mnt/etc/users/"$NIX_USER"
gum spin --show-output --title "Creating password file for GRUB..." -- echo -e "$GRUB_PASS\n$GRUB_PASS" | grub-mkpasswd-pbkdf2 | cut -d' ' -f7 > /mnt/etc/users/grub
gum spin --show-output --title "Setting 600 permissions on password files..." -- chmod -R 600 /mnt/etc/users/

# Clone repo locally
gum spin --show-output --title "Cloning flake repo..." -- git clone --origin nixos https://github.com/JaysFreaky/nixos.git /mnt/etc/nixos
cd /mnt/etc/nixos
gum spin --show-output --title "Switching repo to SSH..." -- git remote set-url nixos git@github.com:JaysFreaky/nixos.git
gum spin --show-output --title "Setting temporary git config..." -- git config --global user.email "95696624+JaysFreaky@users.noreply.github.com" && git config --global user.name "JaysFreaky"
printf '\n'
gum style --foreground="$GREEN" "Formatting complete! Proceeding with host selection..."
printf '\n'

# Prompt for system hostname from flake
gum style --foreground="$WHITE" "Once the system hostname has been chosen, installation will begin."
mapfile -t HOSTS < <(grep "hostName" ./flake.nix | cut -d '"' -f2)
if (( ${#HOSTS[@]} == 0 )); then
  gum style --foreground="$YELLOW" "No hostnames were declared in the flake! Quitting..." >&2
  exit 1
fi
while true; do
  gum style --foreground="$PINK" "Select a host to deploy:"
  NIX_HOST=$(gum choose "${HOSTS[@]}")
  if [ -z "$NIX_HOST" ]; then
    gum style --foreground="$YELLOW" "A hostname must be selected!" && printf '\n'
  else
    gum confirm "Are you sure you want to use '$NIX_HOST'?" --default=false && break || printf '\n'
  fi
done
printf '\n'

# Remove previous swap.nix repo file for a fresh slate
if [ -f /mnt/etc/nixos/hosts/"$NIX_HOST"/swap.nix ]; then
  gum spin --show-output --title "Removing previous swap.nix..." -- rm /mnt/etc/nixos/hosts/"$NIX_HOST"/swap.nix
fi
# Create swap.nix file in host's directory
if [ "$SWAP_TYPE" = 'File' ]; then
  {
    echo '{ config, ... }: {'
    echo '  boot.kernelParams = [ "resume_offset='"$SWAP_OFFSET"'" ];'
    echo '  boot.resumeDevice = "/dev/disk/by-uuid/'"$SWAP_UUID"'";'
    echo '  fileSystems."/swap" = { device = "'"$ROOT_PATH"'"; fsType = "btrfs"; options = [ "subvol=swap" "compress=no" "noatime" ]; };'
    echo '  swapDevices = [ { device = "/swap/swapfile"; } ];'
    echo '}'
  } > /mnt/etc/nixos/hosts/"$NIX_HOST"/swap.nix
elif [ "$SWAP_TYPE" = 'Partition' ]; then
  {
    echo '{ config, ... }: {'
    if [ "$ENCRYPT" = 'YES' ]; then
      echo '  boot.initrd.luks.devices."cryptswap" = { device = "/dev/disk/by-partlabel/swap"; keyFile = "/dev/mapper/cryptkey"; keyFileSize = 8192; };'
    fi
    echo '  boot.resumeDevice = "'"$SWAP_PATH"'";'
    echo '  swapDevices = [ { device = "'"$SWAP_PATH"'"; } ];'
    echo '}'
  } > /mnt/etc/nixos/hosts/"$NIX_HOST"/swap.nix
fi
# Check if swap.nix was generated; commit to repo so it builds with install
if [ -f /mnt/etc/nixos/hosts/"$NIX_HOST"/swap.nix ]; then
  gum spin --show-output --title "Commiting swap.nix to local repo..." -- git add /mnt/etc/nixos/hosts/"$NIX_HOST"/swap.nix && git commit -m "add swap.nix to $NIX_HOST"
fi

# Generate NixOS hardware config | 2>/dev/null hides 'Not a Btrfs filesystem' output error
#gum spin --show-output --title "Generating hardware config..." -- sleep 1 && nixos-generate-config --root /mnt --no-filesystems --show-hardware-config > /mnt/etc/nixos/hosts/"$NIX_HOST"/generated-hardware-configuration.nix 2>/dev/null

# Install NixOS
gum spin --show-output --title "Installing NixOS..." -- nixos-install --no-root-passwd --flake /mnt/etc/nixos#"$NIX_HOST"
printf '\n'

# Pre-reboot tasks
cd /
gum spin --show-output --title "Syncing disk..." -- sync
if [ "$SWAP_TYPE" = 'File' ]; then
  gum spin --show-output --title "Setting swapfile to off..." -- swapoff /mnt/swap/swapfile
elif [ "$SWAP_TYPE" = 'Partition' ]; then
  gum spin --show-output --title "Setting swap to off..." -- swapoff "$SWAP_PATH"
  if [ "$ENCRYPT" = 'YES' ]; then
    gum spin --show-output --title "Closing cryptswap..." -- cryptsetup close /dev/mapper/cryptswap
  fi
fi
gum spin --show-output --title "Unmounting /mnt..." -- umount -R /mnt
if [ "$ENCRYPT" = 'YES' ]; then
  gum spin --show-output --title "Closing cryptroot..." -- cryptsetup close /dev/mapper/cryptroot
  gum spin --show-output --title "Closing cryptkey..." -- cryptsetup close /dev/mapper/cryptkey
  printf '\n'
  gum style --foreground="$PINK" "Remember to copy LUKS headers from '/home/""$NIX_USER""/luksBackup/' to another device."
fi
printf '\n'
gum style --foreground="$GREEN" "Installation complete! Please reboot when ready."
