#!/bin/bash
sudo tee /usr/lib/dracut/modules.d/90overlayfs-tmpfs/module-setup.sh<< 'EOF'
#!/bin/bash

check() {
    [ -d /lib/modules/$kernel/kernel/fs/overlayfs ] || return 1
}

depends() {
    return 0
}

installkernel() {
    hostonly='' instmods overlay
}

install() {
    inst_hook pre-pivot 10 "$moddir/overlay-mount.sh"
}
EOF

sudo tee /usr/lib/dracut/modules.d/90overlayfs-tmpfs/overlay-mount.sh<< 'EOF'
#!/bin/sh
. /lib/dracut-lib.sh

if ! getargbool 0 tmpfsovl ; then
    return
fi

modprobe overlay
mount -o remount,nolock,noatime $NEWROOT
mkdir -p /live/image
mount --bind $NEWROOT /live/image
umount $NEWROOT
mkdir /cow
mount -n -t tmpfs -o mode=0755,size=50%,nr_inodes=500k,noexec,nodev,nosuid,noatime,nodiratime tmpfs /cow
mkdir /cow/work /cow/rw
mount -t overlay -o noatime,nodiratime,volatile,lowerdir=/live/image,upperdir=/cow/rw,workdir=/cow/work,default_permissions,relatime overlay $NEWROOT
mkdir -p $NEWROOT/live/cow
mkdir -p $NEWROOT/live/image
mount --bind /cow/rw $NEWROOT/live/cow
umount /cow
mount --bind /live/image $NEWROOT/live/image
umount /live/image
umount $NEWROOT/live/cow
EOF
