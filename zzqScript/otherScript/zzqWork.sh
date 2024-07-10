#! /bin/bash
#
# zzqwork.sh
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
parameter_names=(1 工作start_over 终端时长1_2) #输入参数的名称列表
# script_path=$ZZQ_SCRIPT_PATH
script_path=/home/zzq/Code/Sheel
son_script_path=work_star_over
#检测参数是否正确传入
for i in {1..2}
do
    if [ -z ${!i}  ];then # $i是空则输出
        echo "${parameter_names[$i]}:未输入，终止脚本执行"
        exit 1
    else
        echo "${parameter_names[$i]}:${!i}"
    fi
done
action=$1 #获取工作开始还是结束
time=$2   #1表示短期结束，即不用推送代码，拉取代码，2表示长期结束，即很长时间不会用
if [ $action = 'start' ];then
    echo "正在启动pigo"
    gnome-terminal -- bash -c "zzqpigo; exec bash"
    echo
    if [ $? -eq -0 ];then
        echo "成功打开新端口，并启动pigo"
    else
        echo "pigo启动失败，后续指令停止执行"
        exit 1
    fi

    echo "正在启动vpn"
    gnome-terminal -- bash -c "zzqvpn start; exec bash"
    echo
    if [ $? -eq -0 ];then
        echo "成功打开新端口，并启动vpn"
    else
        echo "vpn启动失败，后续指令停止执行"
        exit 1
    fi
    if [ $time = 2 ];then
        echo "代码拉取更新"
        gnome-terminal -- bash -c "zzqgitpush pull 1; exec bash"
        echo
        if [ $? -eq -0 ];then
            echo "成功拉取仓库代码，"
        else
            echo "拉取失败，停止执行"
            exit 1
        fi
    fi
elif [ $action = 'over' ];then
    pkill gnome-terminal  # 关闭全部的终端
    if [ $time = 2 ];then # 将代码推送
		echo $ZZQ_SCRIPT_PATH
		gnome-terminal -- bash -c "$script_path/$son_script_path/zzqgitpush.sh push 1; exec bash"
    fi
fi


