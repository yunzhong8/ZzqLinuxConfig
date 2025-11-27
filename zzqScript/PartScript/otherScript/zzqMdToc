#!/bin/sh
echo 在md文件的所在文件夹进行该操作，且操作数是：文件名.md,保证网络能正常链接github
echo 开始
#read -p "输入文件夹地址" doc_path
doc_path=$(pwd)
#read -p "输入文件名称" doc_name
#将第一个输入的操作数作为文件名
doc_name=$1
# 从右往左截取.之后的字符串，即文件名
doc_name=${doc_name%.*}
#doc_name=${$1:0-4}
echo 修改后的文件名：$doc_name
doc_all_path=$doc_path/"$doc_name".md
tocdoc_all_path=$doc_path/"$doc_name"toc.md
echo 文件完整地址$doc_all_path
echo toc文件完整地址$tocdoc_all_path

rm -rf $tocdoc_all_path
touch $tocdoc_all_path
echo toc文件创建完成
#/home/zzq/code/MarkDown/gh-md-toc $doc_all_path
/home/zzq/code/MarkDown/gh-md-toc $doc_all_path > $tocdoc_all_path
cat $doc_all_path >> $tocdoc_all_path
echo 完成
