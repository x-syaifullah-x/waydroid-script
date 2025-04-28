#! /bin/bash

if [ `id --user` != 0 ]; then
  echo "Must be superuser." && exit
fi

[ -e /dev/loop-control ] || /sbin/modprobe -v loop max_part=32

if [ ! -x "$(command -v waydroid)" ]; then
  apt update
  if [ "$1" = "update=true" ]; then
    apt install --no-install-recommends --no-install-suggests ca-certificates curl -y
    curl https://repo.waydro.id | bash
  fi
  apt install --no-install-recommends --no-install-suggests apparmor ca-certificates nftables waydroid wl-clipboard -y
  systemctl restart nftables.service
fi

# STOP SERVICE WAYDROID-CONTAINER
systemctl stop --now waydroid-container.service

sed -i 's/LXC_USE_NFT="false"/LXC_USE_NFT="true"/g' /lib/waydroid/data/scripts/waydroid-net.sh

VAR_LIB_WAYDROID="/var/lib/waydroid"

# CLEAR DIRECTORY /var/lib/waydroid
rm -rfv $VAR_LIB_WAYDROID/*

# DEFAULT CONFIG
tee "$VAR_LIB_WAYDROID/waydroid.cfg" << EOF
[waydroid]
arch = x86_64
system_datetime = 9999999999
vendor_datetime = 9999999999
system_ota = https://ota.waydro.id/system/lineage/waydroid_x86_64/GAPPS.json
vendor_ota = https://ota.waydro.id/vendor/waydroid_x86_64/MAINLINE.json
mount_overlays = False

[properties]
ro.product.cpu.abilist = x86_64,x86,armeabi-v7a,armeabi,arm64-v8a
ro.product.cpu.abilist32 = x86,armeabi-v7a,armeabi
ro.product.cpu.abilist64 = x86_64,arm64-v8a
ro.dalvik.vm.native.bridge = libndk_translation.so
ro.enable.native.bridge.exec = 1
ro.dalvik.vm.isa.arm = x86
ro.dalvik.vm.isa.arm64 = x86_64
ro.vendor.enable.native.bridge.exec = 1
ro.vendor.enable.native.bridge.exec64 = 1
ro.ndk_translation.version = 0.2.3
ro.product.waydroid.brand = $(cat /sys/devices/virtual/dmi/id/sys_vendor)
ro.product.waydroid.device = $(cat /sys/devices/virtual/dmi/id/product_name)
ro.product.waydroid.manufacturer = $(cat /sys/devices/virtual/dmi/id/board_vendor)
ro.product.waydroid.model = $(cat /sys/devices/virtual/dmi/id/board_name)
ro.product.waydroid.name = $(cat /sys/devices/virtual/dmi/id/product_version)
#persist.waydroid.width = 300
#persist.waydroid.height = 600
persist.waydroid.height_padding = 0
persist.waydroid.width_padding = 0
persist.waydroid.multi_windows = true
EOF

CURRENT_DIR="/$(realpath --relative-to=/ $(dirname $0))"

# SETUP WAYDROID IMAGES
waydroid init -f -s GAPPS -i "${CURRENT_DIR}/images/lineage-20.0"

# DATA_FILE_TAR=$CURRENT_DIR/data/waydroid.tar.gz
# if [ -f $DATA_FILE_TAR ]; then
#   SHARE_DIR=/home/xxx/.local/share
#   if [ -d $SHARE_DIR ]; then
#    rm -rfv $SHARE_DIR/waydroid
#     tar xzvf $CURRENT_DIR/data/waydroid.tar.gz -C $SHARE_DIR
#   fi
# fi
