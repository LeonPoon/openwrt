#!/bin/bash -xe
PREFIX="$(cd "$(dirname "$0")" && pwd)"
[ -n "$PREFIX" ]

WORKSPACE="$(cd "$PREFIX/.." && pwd)"
[ -n "$WORKSPACE" ]

machine="$1"
shift

"$WORKSPACE/scripts/feeds" update -a
"$WORKSPACE/scripts/feeds" install -a

tee .config < "$PREFIX/common-pre.config"
tee -a .config < "$PREFIX/$machine.config"
tee -a .config < "$PREFIX/common-post.config"
make defconfig

"$WORKSPACE/scripts/diffconfig.sh"

make clean

make -j$(( $(nproc) + 1 )) download world

linksys_sig() {
	echo -n ".LINKSYS.00000007000000         " > $@.new
	printf "%08X" `cksum < "$@" | cut -d' ' -f1` >> $@.new
	echo -n "0       0000000000000000" >> $@.new
	head /dev/zero -c 192 >> $@.new
	cat $@.new >> $@
	rm -f $@.new
}

initramfs_factory() {
	local machine=$1 sig=$2
	local initramfs_kernel="$(find bin/targets -name openwrt-*-$machine-initramfs-kernel.bin)"
	[ -n "$initramfs_kernel" ] || exit 1
	local initramfs_factory="$(dirname "$initramfs_kernel")/$(basename "$initramfs_kernel" -kernel.bin)-factory.img"
	cp -va "$initramfs_kernel" "$initramfs_factory"
	"$sig" "$initramfs_factory"
	(cd "$(dirname "$initramfs_factory")" && sha256sum -b "$(basename "$initramfs_factory")" | tee -a sha256sums)
}

case $machine in
	ea8100)
		initramfs_factory $machine linksys_sig
		;;
esac
