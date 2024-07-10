#! /usr/bin/env python3
# vim:fenc=utf-8
#
# Copyright © 2024 zzq <zzq@zzq-HP-Pavilion-Gaming-Laptop-15-cx0xxx>
#
# Distributed under terms of the MIT license.

import sys
import os

#**************************** 检查 ******************************#
script_inputed_arg_num = len(sys.argv)
script_arg_require_arg_num = 1

parameter_name_list = [1 ,"module-file-type" ,3]

if script_inputed_arg_num <= script_arg_require_arg_num :
    print(f"传入参数数目{script_inputed_arg_num} <= 最低参数个数{script_arg_require_arg_num}")
        print(f"{parameter_name_list[script_inputed_arg_num:script_arg_require_arg_num+1]} 等参数未输入" )
            exit( -1)

#************************* 功能执行 ******************************#
commonds = sys.argv[1:]
create_module_file_type=comonds[0]
commond_str = " ".join(commonds)

print(f"执行的命令：{commond_str}")

