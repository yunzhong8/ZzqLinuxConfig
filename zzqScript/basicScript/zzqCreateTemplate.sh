#! /bin/sh
#
# zzqcreatetemplate.sh
# Copyright (C) 2023 zzq <zzq@zzq-HP-Pavilion-Gaming-Laptop-15-cx0xxx>
#
# Distributed under terms of the MIT license.
#
echo  "
*********************************************************************
脚本功能：这是一个创建vim模板的脚本                                 *
脚本使用:zzqcreatetemplate file_name                                *
file_name的格式:你要设置类型的文件的后缀.template                   *
eg: cpp.template 表示这是一个以cpp为后缀的文件的模板                *
模板保存的目录在/home/zzq/Code/Templates                            *
*********************************************************************\n"
# 根据文件名，获取模板名称
if [ -z $1 ];then
    echo "未输入文件名，终止脚本"
    exit 1
fi
office_template_path=~/.vim_runtime/my_plugins/vim-template/templates/
#zzq_tempate_path=()
symbol="'"
file_name=$1
type=."${file_name%.**}"
template_name="=template=""$type"
symbol_template_name_symbol=$symbol"$template_name"$symbol
echo "模板脚本名:$template_name" #显示模板名称
# 删除原来的模板
rm -rf $office_template_path$template_name
echo  $office_template_path$template_name

# 将模板文件复制到vim的模板目录
cp "$file_name" "$office_template_path"
# 修改模板的名称
mv "$office_template_path""$file_name"  "$office_template_path""$template_name"
echo "脚本移入完成"
