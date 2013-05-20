#!/bin/sh
rm -rf ramdisk.img
cd ramdisk
find | fakeroot cpio -H newc -o > ../ramdisk.cpio 2>/dev/null
cd -
ls -lh ramdisk.cpio
gzip -9 ramdisk.cpio
mv -f ramdisk.cpio.gz ramdisk.img
python mkelf.py -o kernel.elf zImage@0x80208000 ramdisk.img@0x81600000,ramdisk RPM.bin@0x20000,rpm cmdline@0x00000000,cmdline
#adb reboot bootloader
#fastboot flash boot kernel.elf
#fastboot reboot

