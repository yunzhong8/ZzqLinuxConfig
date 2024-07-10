#! /bin/bash
#
# zzqmkdir.sh
# Copyright (C) 2024 zzq <zzq@zzq-HP-Pavilion-Gaming-Laptop-15-cx0xxx>
#
# Distributed under terms of the MIT license.
#
echo "
*************************************************************************
脚本基本功能：创建一个带有readme.md的目录                               *
脚本使用：zzqmkdir 文件名                                               *\n
eg：                                                                    *
    1.  zzqmkdir temp_dir                                               *
    解释：在当前目录下创建一个temp_dir目录，该目录内有一个readme.md文件 *
    文件名不能包含路径                                                  *
    2.   zzqmkdir /temp/temp_dir                                        *\n
    会出现错误的                                                        *
其他信息：                                                              *
*************************************************************************\n"

parameter_names=(1 文件名) #输入参数的名称列表

#检测参数是否正确传入
for i in {1..1}
do
    if [ -z ${!i}  ];then # $i是空则输出
        echo "${parameter_names[$i]}:未输入，终止脚本执行"
        exit 1
    else
        echo "${parameter_names[$i]}:${!i}"
    fi
done
# 创建目录，同时生成该目录的readme
mkdir $1
if [ -n $2 ];then
    readme_context=$2
fi
#father_path=$pwd
path="$father_path""$1"
touch ./$1/readme.md
if [ -n $readme_context ];then
    echo -e "# 介绍\n $2" >> ./$1/readme.md
fi

