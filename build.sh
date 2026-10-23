#!/usr/bin/env bash
# Build the Termux .deb for a1-link.
#
# Termux packages are ordinary .debs whose paths are rooted at the Termux prefix:
# the data archive carries ./data/data/com.termux/files/usr/...  (verified
# against sl_5.05-1_aarch64.deb from packages.termux.dev, not guessed).
set -euo pipefail

HERE=$(cd "$(dirname "$0")" && pwd)
NAME=a1-link
VERSION=1.0.0
ARCH=aarch64

STAGE=$(mktemp -d)
trap 'rm -rf "$STAGE"' EXIT

install -d "$STAGE/data/data/com.termux/files/usr/bin"
install -d "$STAGE/data/data/com.termux/files/usr/share/doc/$NAME"
install -d "$STAGE/data/data/com.termux/files/usr/share/$NAME"
install -d "$STAGE/DEBIAN"

install -m 755 "$HERE/src/a1"        "$STAGE/data/data/com.termux/files/usr/bin/a1"
install -m 644 "$HERE/README.md"      "$STAGE/data/data/com.termux/files/usr/share/doc/$NAME/README.md"
install -m 644 "$HERE/src/a1"         "$STAGE/data/data/com.termux/files/usr/share/$NAME/a1.source"

cat > "$STAGE/DEBIAN/control" <<EOF
Package: $NAME
Version: $VERSION
Architecture: $ARCH
Maintainer: A1-143 <cid3trkd@gmail.com>
Installed-Size: 60
Depends: bash, curl, proot, tar
Homepage: https://github.com/Cid3-TrKd/a1-link
Section: utils
Priority: optional
Description: Link this Termux to A1-143
 Installs the a1 command, which runs the opencode TUI inside a proot Alpine
 rootfs and connects it to the A1-143 server over the internet.
EOF

cat > "$STAGE/DEBIAN/postinst" <<'EOF'
#!/bin/sh
set -e
echo ""
echo "a1 installed. Two steps:"
echo "  a1 pair        # one time: server address + password"
echo "  a1             # open the terminal"
echo ""
EOF
chmod 755 "$STAGE/DEBIAN/postinst"

install -d "$HERE/dist"
OUT="$HERE/dist/${NAME}_${VERSION}_${ARCH}.deb"
rm -f "$OUT"
# --root-owner-group: dpkg-deb refuses odd ownership otherwise, and Termux
# installs everything as the app uid anyway.
dpkg-deb --build --root-owner-group "$STAGE" "$OUT" >/dev/null

echo "built: $OUT"
ls -l "$OUT"
sha256sum "$OUT"
echo
echo "--- installed paths ---"
dpkg-deb -c "$OUT" | awk '{print $6}' | grep -v '/$'
echo "--- control ---"
dpkg-deb -f "$OUT"
