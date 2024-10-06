#!/bin/bash
# Powered by Apad.pro
# https://apad.pro/easymosdns
#
mosdns_working_dir="/etc/mosdns"
mkdir -p /tmp/easymosdns \
&& curl https://files.imunify360.com/static/whitelist/v2/cloudfront-cdn.txt > /tmp/easymosdns/cloudfront.txt \
&& curl https://ghproxy.cc/https://raw.githubusercontent.com/Journalist-HK/Rules/main/cdn77_ipv4.txt > /tmp/easymosdns/cdn77_ipv4.txt \
&& curl https://ghproxy.cc/https://raw.githubusercontent.com/Journalist-HK/Rules/main/cachefly_ipv4.txt > /tmp/easymosdns/cachefly_ipv4.txt \
&& curl https://ghproxy.cc/https://raw.githubusercontent.com/Journalist-HK/Rules/master/private.txt > /tmp/easymosdns/private.txt \
&& curl https://ghproxy.cc/https://raw.githubusercontent.com/Journalist-HK/Rules/master/white_list.txt > /tmp/easymosdns/white_list.txt \
&& curl https://ghproxy.cc/https://raw.githubusercontent.com/Journalist-HK/Rules/master/block_list.txt > /tmp/easymosdns/block_list.txt \
&& curl https://ghproxy.cc/https://raw.githubusercontent.com/Journalist-HK/Rules/main/hosts_akamai.txt > /tmp/easymosdns/hosts_akamai.txt \
&& curl https://ghproxy.cc/https://raw.githubusercontent.com/Journalist-HK/Rules/main/hosts_fastly.txt > /tmp/easymosdns/hosts_fastly.txt \
&& curl https://ghproxy.cc/https://raw.githubusercontent.com/Journalist-HK/Rules/master/akamai_domain_list.txt > /tmp/easymosdns/akamai_domain_list.txt \
&& curl https://ghproxy.cc/https://raw.githubusercontent.com/Loyalsoldier/v2ray-rules-dat/release/google-cn.txt > /tmp/easymosdns/google_cn.txt \
&& curl https://ghproxy.cc/https://raw.githubusercontent.com/Loyalsoldier/v2ray-rules-dat/release/direct-list.txt > /tmp/easymosdns/china_domain_list.txt \
&& curl https://ghproxy.cc/https://raw.githubusercontent.com/Loyalsoldier/geoip/release/text/fastly.txt > /tmp/easymosdns/fastly.txt \
&& curl https://ghproxy.cc/https://raw.githubusercontent.com/Sereinfy/china_ip_list/main/china_ip_list.txt > /tmp/easymosdns/china_ip_list.txt \
&& curl https://ghproxy.cc/https://raw.githubusercontent.com/Sereinfy/mosdns-config/main/proxy_list.txt > /tmp/easymosdns/proxy_domain_list.txt \
&& curl https://ghproxy.cc/https://raw.githubusercontent.com/Sereinfy/mosdns-config/main/gfw_ip_list.txt > /tmp/easymosdns/gfw_ip_list.txt \
&& curl https://ghproxy.cc/https://raw.githubusercontent.com/Sereinfy/mosdns-config/main/telegram-cidr.txt > /tmp/easymosdns/telegram-cidr.txt \
&& curl https://ghproxy.cc/https://raw.githubusercontent.com/Sereinfy/mosdns-config/main/cloudflare-ipv4.txt > /tmp/easymosdns/cloudflare_ipv4.txt \
&& cp -rf /tmp/easymosdns/*.txt $mosdns_working_dir/rule \
&& rm -rf /tmp/easymosdns/* \
&& echo 'update successful, restarting mosdns' \
&& /etc/init.d/mosdns reload
