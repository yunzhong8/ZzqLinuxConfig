#!/bin/bash

#read -p "输入要翻译的文件名" file_path
#read -p "输入文件名" comptransfilepath
file_path=$1
echo "文件路径$file_path"
trans :zh file://$file_path

