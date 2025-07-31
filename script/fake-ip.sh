
# ----------------------以下是自定义脚本 删除 OpenClash 对非FakeIP代理的流量转发 ---------------------------

FW4=$(command -v fw4)
en_mode=$(uci -q get openclash.config.en_mode)
proxy_port=$(uci -q get openclash.config.proxy_port)

if [ "$en_mode" == "fake-ip" ]; then
  LOG_OUT "当前模式为 fake-ip，将限制路由仅处理 fake-ip流量，使用代理端口 $proxy_port "
  
  /etc/mosdns/script/ipset.sh
  
  if [ -n "$FW4" ]; then
    handle=$(nft -a list chain inet fw4 openclash | grep 'ip protocol tcp counter' | awk '{print $NF}')
    if [ -n "$handle" ]; then
      nft delete rule inet fw4 openclash handle $handle
    fi
    LOG_OUT "已删除 非FakeIP代理 的流量转发，并将 Telegram IP 集合的流量重定向到代理端口 $proxy_port"
    nft add rule inet fw4 openclash ip protocol tcp ip daddr @telegram counter redirect to $proxy_port
  else
    iptables -t nat -D openclash -p tcp -j REDIRECT --to-ports $proxy_port
    LOG_OUT "已删除 非FakeIP代理 的流量转发，并将 Telegram IP 集合的流量重定向到代理端口 $proxy_port"
    iptables -t nat -A openclash -m set --match-set telegram dst -p tcp -j REDIRECT --to-ports $proxy_port
  fi
else
  LOG_OUT "当前模式不是 fake-ip，无需进行特殊路由配置"
fi

# ------------------------------------自定义脚本结束------------------------------------------------------