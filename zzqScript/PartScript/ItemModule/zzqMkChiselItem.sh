#! /bin/bash
#
# zzqBatchFile.sh
# Copyright (C) 2024 zzq <zzq@zzq-HP-Pavilion-Gaming-Laptop-15-cx0xxx>
#
# Distributed under terms of the MIT license.
#
echo "
*************************************************************************
脚本基本功能：                                                          *
脚本使用：  zzqBackUp  运行模式                                         *
# o:official xsz:xiang shang zzq change
# 1 表示自己设置第一个参数的值
# 2 表示自己设置第二个参数的值
# 3 表示自己设置全部参数的值
eg：                                                                    *
    1.   zzqBackUp  3 ~/Code   /tmp                                     *
    解释：将~/Code目录进行压缩，保存到/tmp目录
    2.                                                                  *
其他信息：                                                              *
*************************************************************************\n"
parameter_names=(1 g/xsz 项目名称 待压缩文件的绝对路径  保存压缩文件的目录 4 5 6) #输入参数的名称列表
parameter_num=2  # 脚本一定需要传入的参数个数
shell_script_path=/home/zzq/Code/Sheel/   # 脚本待调用的脚本的父目录
son_script_path=makefiles  # 待调用的脚本的子目录
call_script_path="$shell_script_path""$son_script_path"


#检测参数是否正确传入
for i in $(seq 1 $parameter_num)
do
    if [ -z ${!i}  ];then # $i是空则输出
        echo "${parameter_names[$i]}:未输入，终止脚本执行"
        exit 1
    else
        echo "${parameter_names[$i]}:${!i}"
    fi
done
repo_type=$1
item_name=$2
office_item_repo_url="git@github.com:yunzhong8/zzqChisel.git"
xsz_item_repo_url="git@github.com:yunzhong8/SXChiselPlayground.git"
git_clone_repo_url=""
echo " creating item:$item_name ..."

if [ $repo_type = "o" ];then
	git_clone_repo_url=$office_item_repo_url
else
	git_clone_repo_url=$xsz_item_repo_url
fi
git clone $git_clone_repo_url $item_name

echo " item create finish"
