#! /usr/bin/env python3
# vim:fenc=utf-8
#
# Copyright © 2024 zzq <zzq@zzq-HP-Pavilion-Gaming-Laptop-15-cx0xxx>
#
# Distributed under terms of the MIT license.
# 一个命令没有执行成功会导致后续命令也无法执行
"""

"""
import subprocess
import notify2
import requests
### 百度单词翻译api
url = 'https://fanyi.baidu.com/sug'  # network 找到接口
# 读取剪贴板中的单词
word = subprocess.check_output("xclip -out", shell=True, text=True).strip()
try:
    subprocess.check_output(f"echo {word} > /home/zzq/Code/Sheel/PythonScript/temp.txt", shell=True, text=True).strip()

    data= {
        "kw": word
    }
    response = requests.post(url,json=data)
    mean_list = response.json().get('data')
    mean = mean_list[0].get('v') if mean_list else "抱歉~~~~~未能查到+_+"
    response.close()
# 查询单词的释义
# sdcv -n {word} 这个命令的意思是使用 sdcv（StarDict Console Version）这个命令行词典软件来查询单词的释义。-n 选项表示执行模糊查询，它用于寻找与给定单词相近的条目。
# 在上下文中，这个命令会通过 sdcv 查询剪贴板中的单词 {word} 的释义，并返回查询结果。
#grep '^[a-z]' 在对内容进行过滤
#try:
#    mean = subprocess.check_output(f"sdcv -n {word} |sdcv -n {word} | grep -E '(^[a-z]\.)|\(C\)|\[~s\][\u4e00-\u9fa5]*.*' ", shell=True, text=True).strip()
#except subprocess.CalledProcessError as e:
#    mean="抱歉~~~~~指令执行失败+_+"
#    subprocess.run(["notify-send", "单词释义", mean, "-i", "/home/zzq/Pictures/girl_icon.jpeg", "-t", "10000"])
    subprocess.check_output(f"echo '{mean}' >> /home/zzq/Code/Sheel/PythonScript/temp.txt", shell=True, text=True).strip()

except subprocess.CalledProcessError as e:
    subprocess.check_output(f"echo '命令执行失败: {e}' >> /home/zzq/Code/Sheel/PythonScript/temp.txt", shell=True, text=True).strip()
except requests.RequestException as e:
    subprocess.check_output(f"echo '请求失败: {e}' >> /home/zzq/Code/Sheel/PythonScript/temp.txt", shell=True, text=True).strip()
except Exception as e:
    subprocess.check_output(f"echo '发生未知错误: {e}' >> /home/zzq/Code/Sheel/PythonScript/temp.txt", shell=True, text=True).strip()
#if mean is None:
#    mean="抱歉~~~~~未能查到+_+"
subprocess.run(["notify-send", "单词释义", mean, "-i", "/home/zzq/Pictures/girl_icon.jpeg", "-t", "10000"])
## 初始化通知
#notify2.init("Custom Notification")
#
## 创建通知对象
#n = notify2.Notification("Word Meaning", mean)
#
## 设置通知显示时间和其他属性
#n.set_timeout(10000)  # 设置通知显示时间（毫秒）
#n.set_urgency(notify2.URGENCY_NORMAL)  # 设置通知紧急程度
#
## 设置通知窗口尺寸
#n.set_hint('x', 1000)  # 设置通知宽度为 1920 px
#n.set_hint('y', 1000)  # 设置通知高度为 1080 px
#
## 发送通知
#n.show()

