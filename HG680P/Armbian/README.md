##Backup EMMC to SDCARD

###Virtual Disk
```bash
mkdir -p /mnt/dstloop/
## 5gb virtualdisk
dd if=/dev/zero of=/mnt/dstloop/virtualdisk.img bs=1M count=3072 
losetup -fP /mnt/dstloop/virtualdisk.img
losetup #check which loop device 
fdisk /dev/loop0
```
Output must be like this
```bash
root@leviticus:/opt# fdisk  -l /dev/loop0
Disk /dev/loop0: 3 GiB, 3221225472 bytes, 6291456 sectors
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
Disklabel type: dos
Disk identifier: 0x31ed086b

Device       Boot   Start     End Sectors  Size Id Type
/dev/loop0p1         2048 1026047 1024000  500M  c W95 FAT32 (LBA)
/dev/loop0p2      1026048 6291455 5265408  2.5G 83 Linux
```
Format the disk
```bash
mkfs -t vfat /dev/loop0p1
fatlabel /dev/loop0p1 GKJWBOOT
mkfs -t ext4 /dev/loop0p2
e2label /dev/loop0p2 GKJWROOT
```
Copy the boot & rootfs
```bash
mkdir -p /mnt/boot /mnt/rootfs /mnt/srcrootfs
mount /dev/loop0p1 /mnt/boot
mount /dev/loop0p2 /mnt/rootfs/	       ### Destination rootfs
mount /dev/mmcblk1p2 /mnt/srcrootfs    ### Remount / for cloning

#Copy  originalboot folder or from /boot with some modification
rsync -av /mnt/originboot/ /mnt/boot/
#copy the rootfs
rsync -av --progress --sparse --hard-links --delete --exclude={'/mnt/','/opt/*','/proc/*','/sys/*','/dev/*','/tmp/*','/var/log/*','/var/cache/*','/usr/src','/usr/include','/var/log.hdd/','/var/tmp/*','/var/lib/smartmontools','/var/lib/snmp','/var/lib/apt/lists','/var/lib/NetworkManager/*','*.cache/*','*.config/*','.bash_history'} /mnt/srcrootfs/ /mnt/rootfs/
mkdir /mnt/rootfs/mnt
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
### Use Rufus to Burn The Image   
Possibly require to adjust disk capacity.
```bash
#growpart [disk] [partition-number]
growpart /dev/mmcblk1 2
#resize the partition
resize2fs /dev/mmcblk1p2
##Compress image 
 7z a -t7z -mhe=on -mx=9 ndiplayer-v1_1_r0.7z ndiplayer-v1_1_r0.img -p
```