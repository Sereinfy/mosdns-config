import urllib.request

# 下载第一个txt文件
url1 = "https://ghproxy.cc/https://raw.githubusercontent.com/Loyalsoldier/v2ray-rules-dat/release/direct-list.txt"  # 替换为第一个txt文件的URL
urllib.request.urlretrieve(url1, "china_domain_list.txt")

# 下载第二个txt文件
url2 = "https://ghproxy.cc/https://raw.githubusercontent.com/Sereinfy/mosdns-config/main/proxy_list.txt"  # 替换为第二个txt文件的URL
urllib.request.urlretrieve(url2, "proxy_list.txt")

print("文件下载完成")


# 打开第一个文件
with open('china_domain_list.txt', 'r') as file1:
    # 读取第一个文件的所有行
    lines1 = file1.readlines()

# 打开第二个文件
with open('proxy_list.txt', 'r') as file2:
    # 读取第二个文件的所有行
    lines2 = file2.readlines()

# 创建一个空列表，用于保存同时存在于两个文件中的行
common_lines = []

# 遍历第一个文件的行
for line1 in lines1:
    # 遍历第二个文件的行
    for line2 in lines2:
        # 如果两行相同，则将其添加到common_lines列表中
        if line1 == line2:
            common_lines.append(line1)

# 将common_lines列表中的行写入第三个文件
with open('Duplicates.txt', 'w') as file3:
    file3.writelines(common_lines)