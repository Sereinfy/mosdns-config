#!/bin/bash
# Powered by Apad.pro
# https://apad.pro/easymosdns
#
mosdns_working_dir="/etc/mosdns"
mkdir -p /tmp/easymosdns \
&& curl https://raw.githubusercontent.com/Sereinfy/mosdns-config/release/cloudfront.txt > /tmp/easymosdns/cloudfront.txt \
&& curl https://raw.githubusercontent.com/Sereinfy/mosdns-config/release/cdn77_ipv4.txt > /tmp/easymosdns/cdn77_ipv4.txt \
&& curl https://raw.githubusercontent.com/Sereinfy/mosdns-config/release/cachefly_ipv4.txt > /tmp/easymosdns/cachefly_ipv4.txt \
&& curl https://raw.githubusercontent.com/Sereinfy/mosdns-config/release/private.txt > /tmp/easymosdns/private.txt \
&& curl https://raw.githubusercontent.com/Sereinfy/mosdns-config/release/white_list.txt > /tmp/easymosdns/white_list.txt \
&& curl https://raw.githubusercontent.com/Sereinfy/mosdns-config/release/block_list.txt > /tmp/easymosdns/block_list.txt \
&& curl https://raw.githubusercontent.com/Sereinfy/mosdns-config/release/hosts_akamai.txt > /tmp/easymosdns/hosts_akamai.txt \
&& curl https://raw.githubusercontent.com/Sereinfy/mosdns-config/release/hosts_fastly.txt > /tmp/easymosdns/hosts_fastly.txt \
&& curl https://raw.githubusercontent.com/Sereinfy/mosdns-config/release/akamai_domain_list.txt > /tmp/easymosdns/akamai_domain_list.txt \
&& curl https://raw.githubusercontent.com/Sereinfy/mosdns-config/release/google_cn.txt > /tmp/easymosdns/google_cn.txt \
&& curl https://raw.githubusercontent.com/Sereinfy/mosdns-config/release/china_domain_list.txt > /tmp/easymosdns/china_domain_list.txt \
&& curl https://raw.githubusercontent.com/Sereinfy/mosdns-config/release/fastly.txt > /tmp/easymosdns/fastly.txt \
&& curl https://raw.githubusercontent.com/Sereinfy/mosdns-config/release/china_ip_list.txt > /tmp/easymosdns/china_ip_list.txt \
&& curl https://raw.githubusercontent.com/Sereinfy/mosdns-config/release/proxy_domain_list.txt > /tmp/easymosdns/proxy_domain_list.txt \
&& curl https://raw.githubusercontent.com/Sereinfy/mosdns-config/release/gfw_ip_list.txt > /tmp/easymosdns/gfw_ip_list.txt \
&& curl https://raw.githubusercontent.com/Sereinfy/mosdns-config/release/telegram-cidr.txt > /tmp/easymosdns/telegram-cidr.txt \
&& curl https://raw.githubusercontent.com/Sereinfy/mosdns-config/release/cloudflare_ipv4.txt > /tmp/easymosdns/cloudflare_ipv4.txt \
&& cp -rf /tmp/easymosdns/*.txt $mosdns_working_dir/rule \
&& rm -rf /tmp/easymosdns/* \
&& echo 'update successful, restarting mosdns' \
&& /etc/init.d/mosdns reload
