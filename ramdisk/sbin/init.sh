#!/sbin/busybox sh
set +x
_PATH="$PATH"
export PATH=/sbin
busybox cd /
busybox date >>boot.txt
exec >>boot.txt 2>&1
busybox rm /init

# include device specific vars
source /sbin/bootrec-device

# create directories
busybox mkdir -m 755 -p /cache
busybox mkdir -m 755 -p /dev/block
busybox mkdir -m 755 -p /dev/input
busybox mkdir -m 555 -p /proc
busybox mkdir -m 755 -p /sys

# create device nodes
busybox mknod -m 600 /dev/block/mmcblk0 b 179 0
busybox mknod -m 600 ${BOOTREC_CACHE_NODE}
busybox mknod -m 600 ${BOOTREC_EVENT_NODE}
busybox mknod -m 666 /dev/null c 1 3

# mount filesystems
busybox mount -t proc proc /proc
busybox mount -t sysfs sysfs /sys
busybox mount -t ext4 ${BOOTREC_CACHE} /cache

# trigger amber LED
busybox echo 255 > ${BOOTREC_LED_RED}
busybox echo 0 > ${BOOTREC_LED_GREEN}
busybox echo 255 > ${BOOTREC_LED_BLUE}
busybox echo "50" > ${BOOTREC_VIBRATOR}

# keycheck
busybox cat ${BOOTREC_EVENT} > /dev/keycheck&
busybox sleep 3

# android ramdisk
load_image=/sbin/ramdisk.cpio

# boot decision
if [ -s /dev/keycheck -o -e /cache/recovery/boot ]
then
	busybox echo 'RECOVERY BOOT' >>boot.txt
       export TZ="$(getprop persist.sys.timezone)"
    /system/bin/time_daemon &
    busybox sleep 1
    busybox kill -9 time_daemon

    busybox echo on init > /tz.conf
	buxybox echo export TZ "$(getprop persist.sys.timezone)" >> /tz.conf	
    busybox chmod 750 /tz.conf
    busybox tar cf /zoneinfo.tar /system/usr/share/zoneinfo
	busybox rm -fr /cache/recovery/boot
	# orange led for recoveryboot
	busybox echo 255 > ${BOOTREC_LED_RED}
	busybox echo 100 > ${BOOTREC_LED_GREEN}
	busybox echo 0 > ${BOOTREC_LED_BLUE}
	# recovery ramdisk

	
	# default recovery ramdisk is CWM 
	busybox mknod -m 600 ${BOOTREC_FOTA_NODE}
	busybox mount -o remount,rw /
	busybox ln -sf /sbin/busybox /sbin/sh
	extract_elf_ramdisk -i ${BOOTREC_FOTA} -o /sbin/ramdisk-recovery.cpio -t / -c
	busybox rm /sbin/sh
	load_image=/sbin/ramdisk-recovery.cpio
else
	busybox echo 'ANDROID BOOT' >>boot.txt
	# poweroff LED
	busybox echo 0 > ${BOOTREC_LED_RED}
	busybox echo 0 > ${BOOTREC_LED_GREEN}
	busybox echo 0 > ${BOOTREC_LED_BLUE}
fi

# kill the keycheck process
busybox pkill -f "busybox cat ${BOOTREC_EVENT}"

# unpack the ramdisk image
busybox cpio -i < ${load_image}

busybox umount /cache
busybox umount /proc
busybox umount /sys

busybox rm -fr /dev/*
busybox date >>boot.txt
export PATH="${_PATH}"
exec /init
