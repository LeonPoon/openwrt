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

exec make -j$(( $(nproc) + 1 )) download world
