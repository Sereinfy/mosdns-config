FW4=$(command -v fw4)
en_mode=$(uci -q get openclash.config.en_mode)
proxy_port=$(uci -q get openclash.config.proxy_port)

if [ "$en_mode" == "fake-ip" ]; then
  LOG_OUT "当前模式为 fake-ip，限制路由仅使用代理端口 $proxy_port 处理 fake-ip 流量"
  
  LOG_OUT "正在使用 文件生成 Telegram IP 集合..."
  /etc/mosdns/ipset.sh telegram
  
  if [ -n "$FW4" ]; then
    LOG_OUT "检测到 fw4，使用 nftables 进行规则配置..."
    handle=$(nft -a list chain inet fw4 openclash | grep 'ip protocol tcp counter' | awk '{print $NF}')
    if [ -n "$handle" ]; then
      LOG_OUT "删除现有的 nftables 规则，handle 为 $handle"
      nft delete rule inet fw4 openclash handle $handle
    fi
    LOG_OUT "添加新的 nftables 规则，将 Telegram IP 集合的流量重定向到代理端口 $proxy_port"
    nft add rule inet fw4 openclash ip protocol tcp ip daddr @telegram counter redirect to $proxy_port
  else
    LOG_OUT "未检测到 fw4，使用 iptables 进行规则配置..."
    LOG_OUT "删除现有的 iptables 规则..."
    iptables -t nat -D openclash -p tcp -j REDIRECT --to-ports $proxy_port
    LOG_OUT "添加新的 iptables 规则，将 Telegram IP 集合的流量重定向到代理端口 $proxy_port"
    iptables -t nat -A openclash -m set --match-set telegram dst -p tcp -j REDIRECT --to-ports $proxy_port
  fi
else
  LOG_OUT "当前模式不是 fake-ip，无需进行特殊路由配置"
fi