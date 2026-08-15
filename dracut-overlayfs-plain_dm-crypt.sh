#!/bin/bash
sudo tee /usr/lib/dracut/modules.d/90overlayfs-crypt/module-setup.sh<< 'EOF'
#!/bin/bash

check() {
    require_binaries cryptsetup || return 1
    require_binaries losetup || return 1
    require_binaries mkfs.ext4 || return 1
    return 0
}

depends() {
    return 0
}

installkernel() {
    hostonly='' instmods overlay 2>/dev/null || true
    hostonly='' instmods dm-crypt 2>/dev/null || true
}

install() {
    inst_multiple cryptsetup losetup mkfs.ext4 dd modprobe mount umount shred
    inst_hook pre-pivot 10 "$moddir/overlay-crypt.sh"
}
EOF

sudo tee /usr/lib/dracut/modules.d/90overlayfs-crypt/overlay-mount.sh<< 'EOF'
#!/bin/bash

. /lib/dracut-lib.sh

if ! getargbool 0 cryptovl ; then
    return
fi

modprobe overlay 2>/dev/null || true
modprobe dm-crypt 2>/dev/null || true

mount -o remount,ro /sysroot 2>/dev/null || true
mkdir -p /live/image
mount --bind /sysroot /live/image
umount /sysroot

dd if=/dev/urandom bs=64 count=1 of=/dev/shm/overlay-key status=none
chmod 600 /dev/shm/overlay-key

mkdir -p /var/lib
dd if=/dev/zero of=/var/lib/overlay-crypt.img bs=1M count=0 seek=10240 status=none
losetup -f
LOOP_DEV=$(losetup -f --show /var/lib/overlay-crypt.img)

cryptsetup luksFormat --type luks2 \
    --cipher aes-xts-plain64 --key-size 512 \
    --hash sha256 --pbkdf pbkdf2 --pbkdf-force-iterations 1000 \
    --batch-mode --key-file /dev/shm/overlay-key "$LOOP_DEV"

cryptsetup open --type luks2 --key-file /dev/shm/overlay-key "$LOOP_DEV" overlaycrypt
mkfs.ext4 -F -L "overlaycrypt" /dev/mapper/overlaycrypt
mkdir -p /cow
mount -o noatime,nodiratime,nobarrier /dev/mapper/overlaycrypt /cow
mkdir -p /cow/work /cow/rw
mount -t overlay -o noatime,nodiratime,volatile,lowerdir=/live/image,upperdir=/cow/rw,workdir=/cow/work,default_permissions,relatime overlay /sysroot
mkdir -p /sysroot/live/cow /sysroot/live/image
mount --bind /cow/rw /sysroot/live/cow
mount --bind /live/image /sysroot/live/image
umount /cow 2>/dev/null || true
umount /live/image 2>/dev/null || true
shred -u /dev/shm/overlay-key 2>/dev/null || rm -f /dev/shm/overlay-key
EOF
