#! /bin/bash
#
# zzqcrpath.sh
# Copyright (C) 2024 zzq <zzq@zzq-HP-Pavilion-Gaming-Laptop-15-cx0xxx>
#
# Distributed under terms of the MIT license.
#
echo "
*************************************************************************
脚本基本功能：    计算相对路径的脚本                                                      *
脚本使用：                                                              *\n
eg：                                                                    *
    1.                                                                  *
    解释：                                                              *
    2.                                                                  *\n
其他信息：                                                              *
*************************************************************************\n"
parameter_names=(1 当前目录 引用文件目录) #输入参数的名称列表

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

path1=$(pwd)"/$1"
echo "Path1:$path1"
path2=$2

# 获取路径的部分
# 按照/切割构成列表
path1_parts=($(realpath -m "$path1" | tr '/' ' '))
path2_parts=($(realpath -m "$path2" | tr '/' ' '))
path1_parts_num=${#path1_parts[@]}
path2_parts_num=${#path2_parts[@]}
relate_path=()
common_path=()

i=0
while [ "${path1_parts[$i]}" = "${path2_parts[$i]}" ]; do
    echo "{path1_parts[$i]}:${path1_parts[$i]}{path2_parts[$i]}:${path2_parts[$i]}"
    common_path+="${path1_parts[$i]}/"
    ((i++))
done
echo "common_path:$common_path,i:$i"
j=$i
echo "j=$j,path2_parts_num:$path2_parts_num"
while [ $j -lt $path2_parts_num ];do
    echo "path2_parts[$j]:${path2_parts[$j]}"
    relate_path+="${path2_parts[$j]}"
    ((j++))
    if [ $j -lt $path2_parts_num ];then
        relate_path+="/"
    fi
done
prefix_num=$(expr $path1_parts_num - $i)
prefix=()
k=0
while [ $k -lt $(expr $prefix_num - 1)  ];do
    prefix+="../"
    ((k++))
done
result="$prefix$relate_path"

echo "Common path: $result"

