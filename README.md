# 基于 DNS 的内网代理分流方案

DNS分流流程

屏蔽 QTYPE 65 #内网域名 # DDNS 和 其他白名单

黑名单，可添加去广告列表 

缓存开始，上方不缓存，下方进入缓存

1.自定义名单：`direct_domain_list`

```
      - matches:
          - qname &/etc/mosdns/rule/direct_domain_list.txt
        exec: jump remote_sequence # 1.不进行 IP 替换的域名，且不转发给clash
```

2.自定义名单： `grey_list`  `wall_list`

放在geosite_cn之前，也可以放geosite_cn之后

有尚未移出geosite_cn列表，却被Q的，所以放前面最好

```
      - matches:
          - qname &./rule/google_cn.txt &./rule/grey_list.txt &./rule/wall_list.txt # wall_list手动创建
        exec: jump clash_sequence # 2.适用于被Q/被污染/尚未移出geosite_cn列表的，提前走代理
```

3.`geosite_cn`列表走直连 

`cdnlist` 列表，这个列表会和gfw列表重复，实际上是可以走直连的

gfw列表中还有一些可以走直连的，比如apple.com 

```
      - matches:
          - qname $geosite_cn $cdnlist &./rule/akamai_domain_list.txt apple.com icloud.com
        exec: jump ali_sequence # 国内域名 & 3.令存在于gfwlist列表中的部分国内cdn，提前走直连
```

4.`gfw`列表：走代理

```
      - matches:
          - qname &/etc/mosdns/rule/proxy_domain_list.txt # GFW 域名直接请求clash
        exec: jump clash_sequence
```

4.不在所有列表之内的

用ailidns解析后，判断ip

如果是国内，直接接受

如果是国外，判断是否为gfwip 是的话走代理

不是的话，那就是国外可直连ip。走直连。

ailidns无响应 用fallback



1. 基于 DNS 的流量分流，国内流量绕过 Clash 核心
2. 用 Fake-IP 模式来解决 DNS 污染的问题，但限制 Fake-IP 的范围，不需要代理的域名仍返回正常 IP
3. 兼容 BT/PT 应用，无需特殊配置也不会消耗代理流量

> https://songchenwen.com/tproxy-split-by-dns

## 流量代理分流

经过 DNS 分流以后，我们只需要一条防火墙规则，把所有目的地址是 Fake IP 的流量都转发到 Clash 核心，所有其他流量都不经转发正常通行。

OpenClash 在 Fake IP 模式下会自动帮我们添加对应的防火墙规则。但它为了防止小白误操作把其它 IP 的流量也转发到 Clash 核心了，这是没必要的，我们在自定义防火墙规则里把这条删掉就可以了。

同时由于只有 Fake IP 流量会经过代理，那么无需 DNS 解析的 IP 直连流量自然就不会经过代理了，这样就不用再担心 BT/PT 跑代理的流量了。

## 解决个别 IP 的代理问题

有的需要代理的 App 是直连 IP，不经过 DNS 域名解析的步骤的，目前我用到的只有一个，就是 telegram。好在 telegram 提供了[它所使用的 ip-cidr 列表](https://core.telegram.org/resources/cidr.txt)，我们只需要为这些 IP 单独配置防火墙规则，给它们转发到 Clash 核心。

#### OpenClash



 `geoip-asn.dat`（精简版 GeoIP，只包含上述新增类别）：

- https://raw.githubusercontent.com/Loyalsoldier/geoip/release/geoip-asn.dat
- https://cdn.jsdelivr.net/gh/Loyalsoldier/geoip@release/geoip-asn.dat



~~下载后更名为<u>/etc/openclash/</u>`GeoIP.dat`~~ <br/> 
更新，我自己合并了geoip-asn和GeoIP-cn
- https://github.com/Sereinfy/geoip
  
`iptables.txt` 放在`插件设置` `开发者选项`

其中 `/etc/mosdns/rule/geoip2ipset.sh` 这个脚本可以根据 GeoIP 数据库来生成对应的 ipset。内容如下，这个文件放到路由器上后，记得要执行 `chmod a+x /etc/mosdns/rule/geoip2ipset.sh` 给它赋予可执行权限。

#### mosdns

选自定义配置文件`config_custom.yaml`， `DNS 转发`的打勾，注意 Clash DNS 端口要改成你自己在 OpenClash 里的配置，这里 mosdns 监听了 5335 端口

`update`文件用于下载`config_custom.yaml` 所需的分流规则



#### 遇到的问题

- qanme写法

  ```
  准备两个txt
  只有一个里面有百度
  nslookup.exe baidu.com ok
  2个里面有百度
  Query refused
        - matches:
            - qname &/etc/mosdns/rule/baidu1.txt # 黑名单，可添加去广告列表
            - qname &/etc/mosdns/rule/baidu2.txt # 黑名单，可添加去广告列表  
          exec: reject 5
          # 确认是and关系
          
   第二种
          
        - matches:
            - qname &/etc/mosdns/rule/baidu1.txt &/etc/mosdns/rule/baidu2.txt # 只有一个里面有百度
          exec: reject 5
          Query refused
          # 确认是 or 关系
  ```
  
  
