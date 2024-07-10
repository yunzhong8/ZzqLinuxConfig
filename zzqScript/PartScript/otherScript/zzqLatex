#!/bin/sh
echo strat compile ".tex"file and output ".dvi" file
file=$1 #获取编译文件名
file_name=${file%.*} #截取不包含后缀的文件名
echo $file, ,$file_name
latex $file #编译.tex文件
echo start compile ".div"file
dvipdfmx "$file_name".dvi
echo start delet other file
rm -rf "$file_name".aux "$file_name".dvi "$file_name".log
echo have deleted "$file_name".aux "$file_name".dvi "$file_name".log


