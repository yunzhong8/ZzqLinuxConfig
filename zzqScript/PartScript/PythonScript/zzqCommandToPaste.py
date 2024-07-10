#! /usr/bin/env python3
# vim:fenc=utf-8
#
# Copyright © 2024 zzq <zzq@zzq-HP-Pavilion-Gaming-Laptop-15-cx0xxx>
#
# Distributed under terms of the MIT license.
# 需要而外依赖pyperclip库,如果在linux的平台还额外依赖xclip命令，

import sys
import os
import pyperclip

#**************************** 检查 ******************************#
script_inputed_arg_num = len(sys.argv)
script_arg_require_arg_num = 1

parameter_name_list = [1 ,"命令" ,3]

if script_inputed_arg_num <= script_arg_require_arg_num :
    print(f"传入参数数目{script_inputed_arg_num} <= 最低参数个数{script_arg_require_arg_num}")
    print(f"{parameter_name_list[script_inputed_arg_num:script_arg_require_arg_num+1]} 等参数未输入" )
    exit( -1)

#************************* 功能执行 ******************************#
commonds = sys.argv[1:]

commond_str = " ".join(commonds)

print(f"执行的命令：{commond_str}")

# 执行命令，并获取执行结果
commond_exe_result_file = os.popen(commond_str)
commond_exe_result_str = commond_exe_result_file.read()
if commond_exe_result_file.close() != None:
    print("命令执行错误")
    exit(-1)

# 除去输出结果的末尾的换行、空格等
commond_exe_result_str = commond_exe_result_str.rstrip(" \r\n")
print(f"命令执行结果：{commond_exe_result_str }")

# 将输出赋值到剪贴板
pyperclip.copy(commond_exe_result_str)

