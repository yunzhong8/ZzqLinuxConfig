#! /bin/bash
#
# zzqOpenSoft.sh
# Copyright (C) 2024 zzq <zzq@zzq-HP-Pavilion-Gaming-Laptop-15-cx0xxx>
#
# Distributed under terms of the MIT license.
#
echo "
*************************************************************************
脚本基本功能：用于打开软件                                                          *
脚本使用：   zzqOpenSoft 软件名称                                                           *\n
eg：                                                                    *
    1.    zzqOpenSoft Pycharm/PicGo/Vpn/FastGithub                                                              *
    解释：                                                              *
    2.                                                                  *\n
其他信息：                                                              *
*************************************************************************\n"
parameter_names=(1 软件名称 3 4 5 6) #输入参数的名称列表
parameter_num=1  # 脚本一定需要传入的参数个数
shell_script_path=/home/zzq/Code/Sheel/   # 脚本待调用的脚本的父目录
son_script_path=SoftsSetUp  # 待调用的脚本的子目录
call_script_path="$shell_script_path""$son_script_path"


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
soft_name=$1 #获取软件名称
soft_set_up_shell="$call_script_path""/zzq$soft_name"".sh" # 获取软件启动脚本
echo "$soft_set_up_shell"
echo "正在启动$soft_name"
gnome-terminal -- bash -c "$soft_set_up_shell start; exec bash"
echo
if [ $? -eq -0 ];then
    echo "成功打开新端口，并启动$soft_name"
else
    echo "$soft_name启动失败，后续指令停止执行"
    exit 1
fi

