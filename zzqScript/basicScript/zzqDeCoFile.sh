#! /bin/sh
#
# zzqdecofile.sh
# Copyright (C) 2023 zzq <zzq@zzq-HP-Pavilion-Gaming-Laptop-15-cx0xxx>
#
# Distributed under terms of the MIT license.
#shell脚本语言是我见过最垃圾的编程语言，这玩意只适合编写简单的脚本语言，复杂的脚本它做不了
echo "解压脚本,时候window和linux的大部分压缩格式                  *"
echo "使用方法:zzqdecofile 文件名.压缩格式 压缩格式 压缩后缀数目  *"
echo "zzqdecofile xx.deb deb 1                                    *"
echo "zzqdecofile xx.tar.gz tar.gz 2                              *"
echo "*************************************************************\n"
if [ -z $1 ];then
    echo "未输出文件名，已经终止脚本执行"
    exit 1
fi
file_name=$1
temp_file_name=$file_name
file_name_len=${#file_name} #获取字符串长度
#获取待解压文件的压缩后缀名
#dot_appear_time=`expr match $file_name [.]` #统计.出现次数
#dot_appear_time=$(echo $file_name | grep -o "." | wc -l) #没有用，因为grep这个函数的参数是文件，所以如果要对文件名进行匹配字符的话，会变成跟文件名对应的文件进行比较字符
#:<<EOF
#dot_appear_time=0
#for i in {$file_name}
#do
#    echo "i:$i\n"
#    if [ i='.' ];then
#        dot_appear_time=`expr $dot_appear_time + 1`;
#    fi
#done
#EOF
if [ -z $2 ] ;then
    echo "未输入压缩后缀，已经终止脚本执行"
    exit 1
fi
suffix=$2 #获取文件名中压缩的后缀
if [ -z $3 ] ;then
    echo "未输入压缩后缀个数，已经终止脚本执行"
    exit 1
fi
zip_suffix_num=$3 #获取文件名中压缩的后缀数目
#redundancy_dot_num=`expr $doc_appear_time - $zip_suffix_num`
#redundancy_dot_num=`expr $redundancy_dot_num + 1`
#echo".出现次数：$dot_appear_time,压缩后缀数目：$zip_suffix_num"
#echo"冗余dot个数：$redundancy_dot_num"

#for i in {1..$redundancy_dot_num}
#do
#    suffix=${file_name#*.}
#done

#获取待解的文件的文件名不带压缩后缀
temp_file_name=$file_name
if [ $zip_suffix_num = 1 ];then
     echo "压缩后缀个数：1，zip_suffix_num:$zip_suffix_num"
    file_name_nosuffix=${temp_file_name%.*} #后缀是1个则从右往左截断1次
elif [ $zip_suffix_num = 2 ];then
    echo "压缩后缀个数：2"
    temp_file_name=${temp_file_name%.*}
    file_name_nosuffix=${temp_file_name%.*}
fi
#file_name_nosuffix_len=${#file_name_nosuffix}
#echo "file_name_nosuffix_len: $file_name_nosuffix_len,file_name_len$file_name_len"
#file_name_len=`expr $file_name_len - 1`
#echo "file_name_nosuffix_len: $file_name_nosuffix_len,file_name_len$file_name_len"
#suffix=${file_name:$file_name_nosuffix_len}
#suffix=${file_name:26}
echo "file_name:$file_name"
echo "压缩后缀名：$suffix"
echo "不带压缩后缀的文件名：$file_name_nosuffix"
# window格式
Zip="zip"
Rar="rar"
# linux格式
Deb="deb"
Tar="tar"
Gz="gz"
Tgz="tgz"
Bz2="bz2"
Bz="bz"
Z='z'
Lha="lha"
Rpm="rpm"

# 双后缀
TarGz="tar.gz"
TarBz2="tar.bz2"
case $suffix in
    $Zip )
        echo "正在解压的类型是：$Zip"
        unzip -O GBK $file_name
        echo "$file_name" 解压成功
        ;;
    $Rar)
        echo "正在解压的类型是：$Rar"
        unrar x $file_name
        echo "$file_name" 解压成功
        ;;
    $Deb)
        echo "正在解压的类型是：$Ded"
        rm -rf $file_name_nosuffix
        mkdir ./$file_name_nosuffix
        dpkg -x $file_name ./$file_name_nosuffix
        echo "$file_name" 解压成功
        ;;
    $Tar)
        echo "正在解压的类型是：$Tar"
        tar xf $file_name
        echo "$file_name" 解压成功
        ;;
    $Gz)

        echo "正在解压的类型是：$Gz"
        gunzip -d $file_name
        echo "$file_name" 解压成功
        ;;
    $Tgz)
        echo "正在解压的类型是：$Tgz"
        tar zxf $file_name
        echo "$file_name" 解压成功
        ;;
    $Bz2)
        echo "正在解压的类型是：$Bz2"
        bzip2 -d $file_name
        echo "$file_name" 解压成功
        ;;
    $TarGz)
          echo "正在解压的类型是：$TarGz"
          tar zxvf $file_name
          echo "$file_name" 解压成功
          ;;
	$TarBz2)
		  echo "正在解压的类型是：$TarBz2"
		  tar -xvjf $file_name
		  echo "$file_name" 解压成功
		  ;;
    *)
        echo"can deco this file(无法解压该类型)"
        ;;
esac


