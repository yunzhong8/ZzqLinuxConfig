#! /bin/bash
#
# zzqtouch.sh
# Copyright (C) 2024 zzq <zzq@zzq-HP-Pavilion-Gaming-Laptop-15-cx0xxx>
#
# Distributed under terms of the MIT license.
#
echo "
*************************************************************************
脚本基本功能：                                                          *
脚本使用：zzqtouch vatb 测试.cpp verilog.v                                   *\n
eg：                                                                    *
    1.                                                                  *
    解释：                                                              *
    2.                                                                  *\n
其他信i息：
vatb nvatb*
*************************************************************************\n"
parameter_names=(1 file_type filename v_filename 4 5 6) #输入参数的名称列表

#检测参数是否正确传入
for i in {1..3}
do
    if [ -z ${!i}  ];then # $i是空则输出
        echo "${parameter_names[$i]}:未输入，终止脚本执行"
        exit 1
    else
        echo "${parameter_names[$i]}:${!i}"
    fi
done

file_type=$1
SH=/bin/bash
shell_script_path=/home/zzq/Code/Sheel/
son_script_path=touchs

if [ $file_type = 'vatb' ];then
	$SH "$shell_script_path$son_script_path/vatb.sh" $2 $3 $4 $5 $6 $7 $8 $9

elif  [ $file_type = "nvatb" ];then
	$SH "$shell_script_path$son_script_path/nvatb.sh" $2 $3 $4 $5 $6 $7 $8 $9
fi
