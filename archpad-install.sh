#!/bin/bash

#####################################################################################
# Please do not use this script blindly. Review and edit before use. Read the wiki! #
#####################################################################################
# Roy Williams IV - 2018 - GPLv3 #
##################################

###############
# Pre-Install #
###############

# update system clock
timedatectl set-ntp true

# disk partitioning
(
echo o    # Create a new empty GPT partition table
echo y    # Confirm changes
echo n    # 1. Create BIOS partition
echo 1      # Partition number
echo ""     # First sector (Accept default: 1)
echo +1M    # Last sector (Create 1MB size)
echo EF02   # Change type to BIOS
echo n    # 2. Create swap partition
echo 2      # Partition number
echo ""     # First sector (Accept default: 1)
echo +4G    # Last sector (Create 4GB size)
echo 8200   # Change type to BIOS
echo n    # 3. Create main partition
echo 3      # Partition number
echo ""     # First sector (Accept default: 1)
echo ""     # Last sector (Accept default: varies)
echo ""     # Change type to main
echo w      # Write changes
echo y      # Confirm changes
) | gdisk /dev/sda 

# format main partitions ext4
yes | mkfs.ext4 /dev/sda3
yes | mkfs.ext4 /dev/sda2

# configure swap
mkswap /dev/sda2
swapon /dev/sda2

#####################
# Mount and Install #
#####################

# mount main partition
mount /dev/sda3 /mnt

# start main installation
pacstrap /mnt base

# generate fstab
genfstab -U /mnt >> /mnt/etc/fstab

#######################
# Chroot Setup / Grub #
#######################

# enter chroot and continue script
arch-chroot /mnt << EOF

# set time zone
ln -sf /usr/share/zoneinfo/America/Chicago /etc/localtime

# sync hardware clock
hwclock --systohc

# set locale

echo 'en_US.UTF-8 UTF-8' >> /etc/locale.gen

locale-gen

# set language
echo 'LANG=en_US.UTF-8' >> /etc/locale.conf

# set hostname
touch /etc/hostname
echo 'archpad' >> /etc/hostname

#########################
# Install Network Tools #
#########################

# install network utilites
yes | pacman -S iw wpa_supplicant dialog

################################
# Install Grub and Intel-Ucode #
################################

# install intel-ucode and grub packages
yes | pacman -S intel-ucode grub

# install grub
grub-install /dev/sda

# generate config file
grub-mkconfig -o /boot/grub/grub.cfg

# remind user to set new password
echo "Install finished - please remember to set new root password using passwd."

EOF


