#! /usr/bin/env python3
# vim:fenc=utf-8
#
# Copyright © 2024 zzq
#
# Distributed under terms of the MIT license.
# 一个命令没有执行成功会导致后续命令也无法执行
"""

"""
import subprocess
import notify2
import requests
log_file_path="/home/zzq/Code/Sheel/PythonScript/log.txt"
icon_path="/home/zzq/Pictures/girl_icon.jpeg"
### 百度单词翻译api
url = 'https://fanyi.baidu.com/sug'  # network 找到接口
# 读取剪贴板中的单词
word = subprocess.check_output("xclip -out", shell=True, text=True).strip()

try:
    # 将读取到待翻译的单词记录到log文件里
    subprocess.check_output(f"echo {word} > {log_file_path} ", shell=True, text=True).strip()

    data= {
        "kw": word
    }
    # 访问远程链接，获取返回的json结果的数据
    response = requests.post(url,json=data)
    mean_list = response.json().get('data')

    # 从json数据中解析出：单词译文 到mean变量里，
    # 如果json返回数据为空，则放mean中保存："抱歉~~~~~未能查到+_+"
    mean = mean_list[0].get('v') if mean_list else "抱歉~~~~~未能查到+_+"

    # 关闭请求
    response.close()

    # 将译文记录到log文件中
    subprocess.check_output(f"echo '{mean}' >> {log_file_path}", shell=True, text=True).strip()

    # 捕获上面代码执行是否出现异常
except subprocess.CalledProcessError as e:
    subprocess.check_output(f"echo '命令执行失败: {e}' >> {log_file_path}", shell=True, text=True).strip()
except requests.RequestException as e:
    subprocess.check_output(f"echo '请求失败: {e}' >> {log_file_path}", shell=True, text=True).strip()
except Exception as e:
    subprocess.check_output(f"echo '发生未知错误: {e}' >> {log_file_path}", shell=True, text=True).strip()

# 将译文以弹窗的方式显示出
subprocess.run(["notify-send", "单词释义", mean, "-i", icon_path, "-t", "10000"])


