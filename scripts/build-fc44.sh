#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

WING_BASE="b089b568649f03f909477adb6c7db25535a58782"
DAE_BASE="dbae2e82d3ed5324e1648548720f8bbc8cde3882"

# build flags from COPR spec
export CFLAGS="-fno-stack-protector"
export CGO_ENABLED=1
export CGO_CPPFLAGS="${CPPFLAGS:-}"
export CGO_CFLAGS="${CFLAGS}"
export CGO_CXXFLAGS="${CXXFLAGS:-}"
export CGO_LDFLAGS="${LDFLAGS:-}"
export GOFLAGS="-buildmode=pie -trimpath -ldflags=-linkmode=external -mod=readonly -modcacherw"

export NODE_OPTIONS="--max-old-space-size=8192"

#
# Ensure submodule repositories exist.
#
cd "$ROOT"
git submodule update --init wing

#
# Reset dae-wing to our upstream base.
#
cd "$ROOT/wing"

git fetch origin
git reset --hard
git clean -fd
git checkout --detach "$WING_BASE"

git submodule update --init dae-core

#
# Reset dae-core to our explicitly selected upstream base.
#
cd "$ROOT/wing/dae-core"

git fetch origin
git reset --hard
git clean -fd
git checkout --detach "$DAE_BASE"

#
# Apply dae-core patches in filename order.
#
for patch in "$ROOT"/patches/dae-core/*.patch; do
    echo "Applying dae-core: $(basename "$patch")"
    git am "$patch"
done

#
# Apply dae-wing patches.
#
cd "$ROOT/wing"

for patch in "$ROOT"/patches/wing/*.patch; do
    echo "Applying dae-wing: $(basename "$patch")"
    git am "$patch"
done

#
# Build daed without allowing its Makefile to reset our submodules.
#
cd "$ROOT"

make SKIP_SUBMODULES=1 "$@"
