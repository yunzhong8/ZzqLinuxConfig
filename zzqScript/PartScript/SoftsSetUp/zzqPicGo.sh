#! /bin/bash
#
# zzqpigo.sh
# Copyright (C) 2024 zzq <zzq@zzq-HP-Pavilion-Gaming-Laptop-15-cx0xxx>
#
# Distributed under terms of the MIT license.
#
echo "
*************************************************************************
脚本基本功能：                                                          *
脚本使用：                                                              *\n
eg：                                                                    *
    1.                                                                  *
    解释：                                                              *
    2.                                                                  *\n
其他信息：                                                              *
*************************************************************************\n"
parameter_names=(1 2 3 4 5 6) #输入参数的名称列表
parameter_num=1  # 脚本一定需要传入的参数个数
shell_script_path=/home/zzq/Code/Sheel/   # 脚本待调用的脚本的父目录
son_script_path=makefiles  # 待调用的脚本的子目录
call_script_path="$shell_script_path""$son_script_path"
softs_dir=/home/zzq/soft_collection/
soft_basename=$softs_dir
soft_path=$soft_basename"PicGo-2.3.1.AppImage"

#检测参数是否正确传入
for i in $(seq 1 $parameter_names)
do
    if [ -z ${!i}  ];then # $i是空则输出
        echo "${parameter_names[$i]}:未输入，终止脚本执行"
        exit 1
    else
        echo "${parameter_names[$i]}:${!i}"
    fi
done
action=$1
if [ $action == "start" ];then
	$soft_path
else
	echo "$action 没有实现"
fi
