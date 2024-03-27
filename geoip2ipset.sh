#!/bin/bash

geoipfile="$1"
tag="$2"
tmpdir="/tmp/v2dat"
FW4=$(command -v fw4)

cd $(cd $(dirname $BASH_SOURCE) && pwd)

mkdir -p "$tmpdir"
filename=$(basename -- "$geoipfile")
filename="${filename%.*}"
filename="$tmpdir/${filename}_$tag.txt"

if [ "$tag" == "telegram" ]; then
    wget -4 --timeout 5 -O "$filename" 'https://ghproxy.cc/https://raw.githubusercontent.com/Sereinfy/ip-preferred/main/cidr.txt'
    if [ "$?" != "0" ]; then
         /usr/bin/v2dat unpack geoip -o "$tmpdir" -f "$tag" "$geoipfile"
    fi
else
    /usr/bin/v2dat unpack geoip -o "$tmpdir" -f "$tag" "$geoipfile"
fi

if test -f "$filename"; then
    if [ -n "$FW4" ]; then
        nft add set inet fw4 "$tag" { type ipv4_addr\; flags interval\;  auto-merge\; }
        nft add set inet fw4 "${tag}6" { type ipv6_addr\; flags interval\;  auto-merge\; }
        nft flush set inet fw4 "$tag"
        nft flush set inet fw4 "${tag}6"
    fi
    ipset create "$tag" hash:net -!
    ipset create "${tag}6" hash:net family inet6 -!
    ipset flush "$tag"
    ipset flush "${tag}6"
    while read p; do
        if ! grep -q ":" <<< "$p"; then
            if [ -n "$FW4" ]; then
                nft add element inet fw4 "$tag" { "$p" }
            fi
            ipset add "$tag" "$p"
        else
            if [ -n "$FW4" ]; then
                nft add element inet fw4 "${tag}6" { "$p" }
            fi
            ipset add "${tag}6" "$p"
        fi
    done <"$filename"
else
    echo "$filename missing."
fi

rm -rf "$tmpdir"