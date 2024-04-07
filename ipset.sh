#!/bin/bash

tag="telegram"
FW4=$(command -v fw4)
filename="/etc/mosdns/telegram-cidr.txt"

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
