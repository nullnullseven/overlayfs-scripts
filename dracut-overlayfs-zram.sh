#!/bin/bash
sudo tee /usr/lib/dracut/modules.d/90overlayfs-zram/module-setup.sh<< 'EOF'
#!/bin/bash

check() {
    [ -d /lib/modules/$kernel/kernel/fs/overlayfs ] || return 1
    [ -d /lib/modules/$kernel/kernel/drivers/block/zram ] || return 1
    return 0
}

depends() {
    return 0
}

installkernel() {
    hostonly='' instmods overlay zram ext2
}

install() {
    inst_multiple mkfs.ext2

    # Optional
    # inst_multiple zramctl

    inst_hook pre-pivot 10 "$moddir/overlayz-mount.sh"
}
EOF

sudo tee /usr/lib/dracut/modules.d/90overlayfs-zram/overlay-mount.sh<< 'EOF'
#!/bin/bash

. /lib/dracut-lib.sh

if ! getargbool 0 zramovl ; then
    return
fi

modprobe overlay
modprobe zram

if [ ! -b /dev/zram0 ]; then
    echo 1 > /sys/class/zram-control/hot_add 2>/dev/null || true
fi

echo 1 > /sys/block/zram0/reset 2>/dev/null || true
echo 10G > /sys/block/zram0/disksize
mkfs.ext2 -F -m 0 -q /dev/zram0
mount -o remount,nolock,noatime $NEWROOT
mkdir -p /live/image
mount --bind $NEWROOT /live/image
umount $NEWROOT
mkdir -p /cow
mount -n -t ext2 -o noatime,nodiratime,noexec,nodev,nosuid /dev/zram0 /cow
mkdir -p /cow/work /cow/rw
mount -t overlay -o noatime,nodiratime,volatile,lowerdir=/live/image,upperdir=/cow/rw,workdir=/cow/work,default_permissions,relatime overlay $NEWROOT
mkdir -p $NEWROOT/live/cow
mkdir -p $NEWROOT/live/image
mount --bind /cow/rw $NEWROOT/live/cow
mount --bind /live/image $NEWROOT/live/image
umount /live/image
EOF
