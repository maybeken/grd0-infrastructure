#!/usr/bin/with-contenv bash
set -e

NEW_USER="${WEBTOP_USER:-abc}"
NEW_GECOS="${WEBTOP_DISPLAY_NAME:-${NEW_USER}}"

# `abc` is hardcoded throughout the image's s6 services, so keep that account
# and prepend an alias with its UID/GID instead. getpwuid/getgrgid then resolve
# to the configured name while `s6-setuidgid abc` still works.
if [ "${NEW_USER}" = "abc" ]; then
	exit 0
fi

awk -F: -v OFS=: -v user="${NEW_USER}" -v gecos="${NEW_GECOS}" '
	$1 == user { next }
	$1 == "abc" { print user, $2, $3, $4, gecos, $6, $7 }
	{ print }
' /etc/passwd > /etc/passwd.new
cat /etc/passwd.new > /etc/passwd
rm -f /etc/passwd.new

awk -F: -v OFS=: -v group="${NEW_USER}" '
	$1 == group { next }
	$1 == "abc" { print group, $2, $3, $4 }
	{ print }
' /etc/group > /etc/group.new
cat /etc/group.new > /etc/group
rm -f /etc/group.new
