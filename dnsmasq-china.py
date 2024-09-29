import urllib.request
import requests

# 下载第一个txt文件
url1 = "https://raw.githubusercontent.com/Loyalsoldier/v2ray-rules-dat/release/direct-list.txt"  # 替换为第一个txt文件的实际URL
response1 = requests.get(url1)
with open("china_domain_list1.txt", "wb") as file1:
    file1.write(response1.content)

# 下载第二个txt文件
url2 = "https://raw.githubusercontent.com/Loyalsoldier/v2ray-rules-dat/release/china-list.txt"  # 替换为第二个txt文件的实际URL
response2 = requests.get(url2)
with open("proxy_list21.txt", "wb") as file2:
    file2.write(response2.content)

print("文件下载完成")


# 打开第一个文件
with open('china_domain_list1.txt', 'r') as file1:
    # 读取第一个文件的所有行
    lines1 = file1.readlines()

# 打开第二个文件
with open('proxy_list21.txt', 'r') as file2:
    # 读取第二个文件的所有行
    lines2 = file2.readlines()

# 使用集合差集提取不同的行
diff_lines = list(set(lines1).difference(set(lines2)) | set(lines2).difference(set(lines1)))

# 将不同的行写入 Duplicates2.txt 文件
with open('Duplicates2.txt', 'w') as f:
    f.write(' '.join(diff_lines))  # 使用空格连接，不换行

