#! /bin/bash
#
# zzqsetvimrc.sh
# Copyright (C) 2024 zzq <zzq@zzq-HP-Pavilion-Gaming-Laptop-15-cx0xxx>
#
# Distributed under terms of the MIT license.
#
echo "
*****************************************************************************************************************
脚本基本功能：将配置好的config文件拷贝到官方的config区                                                                   *
脚本使用：zzqsetvimrc                                                                                           *\n
eg:                                                                                                             *
    1. zzqsetconfig xxx                                                                                             *
    解释：在你在/home/zzq/.vim_runtime/my_configs.vim中设置好my_configs.vim，后执行上述命令则可以更新vim的vimrc *
    2.                                                                                                          *\n
其他信息：                                                                                                      *
vim软件规定的vimrc地址：~/.vimrc                                                                                *
我设置的vimrm配置文件地址：/home/zzq/.vim_runtime/my_configs.vim                                                *
我编辑的vimrc的地址/home/zzq/Code/MarkDown/Vim/my_configs.vimi*
vimrc
sources.list
bashrc
*****************************************************************************************************************\n"

parameter_names=(1 配置的文件 引用文件目录) #输入参数的名称列表

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


file_name=$1
# 自己的配置文件所在目录
zzq_father_path=/home/zzq/Code/Linux_Config/
# 自己编写的配置文件
zzq_vimrc_path="$zzq_father_path""my_configs.vim"
zzq_source_list_path="$zzq_father_path""sources.list"
zzq_bashrc_path="$zzq_father_path""bashrc"
# 官方的配置文件
office_vimrc_path=/home/zzq/.vim_runtime
office_source_list_path=/etc/apt/sources.list
office_bashrc_path=~/.bashrc

function check_pre_finsh(){
    local sucesss_comment=
    local fail_comment=
   if [ $? -eq 0 ]; then
            echo "$sucesss_comment"
    else
            echo "$fail_comment"
   fi

}
if [ $file_name = 'vimrc' ];then
    echo "开始设置vimrc"
        cp $zzq_vimrc_path $office_vimrc_path
elif [ $file_name = 'sources.list' ];then
    echo "开始配置软件源列表"
    sudo cp $zzq_source_list_path $office_source_list_path
elif [ $file_name = 'bashrc' ];then
	echo "开始配置bashrc"
	sudo cp $zzq_bashrc_path $office_bashrc_path
	source ~/.bashrc
fi
echo "设置完成"


