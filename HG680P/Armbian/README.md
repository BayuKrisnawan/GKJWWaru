##Backup EMMC to SDCARD

###Virtual Disk
```bash
## 5gb virtualdisk
dd if=/dev/zero of=/opt/virtualdisk.img bs=1M count=5120 
losetup -fP /opt/virtualdisk.img
fdisk /opt/virtualdisk.img
```
Output must be like this
```bash
root@leviticus:/opt# fdisk  -l /opt/virtualdisk.img
Disk /opt/virtualdisk.img: 7 GiB, 7516192768 bytes, 14680064 sectors
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
Disklabel type: dos
Disk identifier: 0x8c12ba80

Device                Boot   Start      End  Sectors  Size Id Type
/opt/virtualdisk.img1         2048  1048575  1046528  511M  c W95 FAT32 (LBA)
/opt/virtualdisk.img2      1048576 14680063 13631488  6.5G 83 Linux
```
Format the disk
```bash
mkfs -t vfat /dev/loop0p1
fatlabel /dev/loop0p1 GKJWBOOT
mkfs -t ext4 /dev/loop0p2
```
Copy the boot & rootfs
```bash
mkdir -p /mnt/boot /mnt/rootfs /mnt/srcrootfs
mount /dev/loop0p1 /mnt/boot
mount /dev/mmcblk1p2 /mnt/srcrootfs  ### Source rootfs
mount /dev/loop0p2 /mnt/rootfs/	       ### Destination rootfs

#Copy  originalboot folder or from /boot with some modification
rsync -av /root/originboot/ /mnt/boot/ 
#copy the rootfs
rsync -av --progress --sparse --hard-links --delete --exclude={'/mnt/*','/opt','/proc/*','/sys/*','/dev/*','/tmp/*','/var/log/*','/var/cache/apt/','/usr/src','/var/log.hdd/'} /mnt/srcrootfs/ /mnt/rootfs/
```
Modify the new-boot & new-fstab using this command `blkid |grep loop`
```bash
root@leviticus:/opt# blkid |grep loop
/dev/loop0p1: SEC_TYPE="msdos" UUID="D64C-6F2F" BLOCK_SIZE="512" TYPE="vfat" PARTUUID="8c12ba80-01"  
/dev/loop0p2: UUID="910220c2-0892-45e6-9f52-b273d1831c84" BLOCK_SIZE="4096" TYPE="ext4" PARTUUID="8c12ba80-02"
```

edit `/mnt/boot/uEnv.txt` with `910220c2-0892-45e6-9f52-b273d1831c84` rootfs uuid
```bash
LINUX=/zImage
INITRD=/uInitrd
FDT=/dtb/amlogic/meson-gxl-s905x-p212.dtb
APPEND=root=UUID=910220c2-0892-45e6-9f52-b273d1831c84 rootflags=data=writeback rw rootwait rootfstype=ext4 console=ttyAML0,115200n8 console=tty0 no_console_suspend consoleblank=0 fsck.fix=yes fsck.repair=yes net.ifnames=0 max_loop=128 cgroup_enable=cpuset cgroup_memory=1 cgroup_enable=memory swapaccount=1 video=HDMI-A-1:1920x1080@60e
```
edit `/mnt/rootfs/` with `910220c2-0892-45e6-9f52-b273d1831c84` & `D64C-6F2F` 
```bash
UUID=910220c2-0892-45e6-9f52-b273d1831c84    /        ext4    defaults,noatime,nodiratime,commit=600,errors=remount-ro      0 1
UUID=D64C-6F2F                  /boot    vfat                   defaults                   0 2
tmpfs                  /tmp     tmpfs                  defaults,nosuid            0 0
```
Done, final task.
```bash
umount /mnt/boot
umount /mnt/rootfs
sync
losetup  -d /dev/loop0 #detach the vdisk
```
