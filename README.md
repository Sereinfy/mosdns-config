# 基于 DNS 的内网代理分流方案

主要思路是国内域名用 运营商dns解析<br>
国内列表里 <br>
会有一些突然被屏蔽的域名，那么在国内域名之前还有一个 wall_list.txt(只有这个文件，需要手动创建)<br>
用于手动让其提前走国外，或者发送给clash<br>
国外列表里 <br>
有一些原本可以直连的域名，那么在国外域名之前还有一个 akamai_domain_list.txt<br>
这个列表和国内列表放在一起，走直连<br>
结构是<br>

wall_list.txt 走国外 google_cn 走国外（也可以走直连[慎用]） <br>
geosite_cn 走直连 akamai_domain_list.txt 走直连<br>
proxy_domain_list.txt 走国外<br>

update.sh里面有所以的文件
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
  
  
