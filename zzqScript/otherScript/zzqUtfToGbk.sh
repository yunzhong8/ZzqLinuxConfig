#! /bin/bash
#
# zzqutftogbk.sh
# Copyright (C) 2023 zzq <zzq@zzq-HP-Pavilion-Gaming-Laptop-15-cx0xxx>
#
# Distributed under terms of the MIT license.
#
#parameter_names={1 }
##检测参数是否正确传入
#for i in {1..2}
#do
#    if [ -z ${!i}  ];then # $i是空则输出
#        echo "${parameter_names[$i]}:未输入，终止脚本执行"
#        exit 1
#    else
#        echo "${parameter_names[$i]}:${!i}"
#    fi
#done


cli="find . -type f \( "
for arg in ${@:1:$#-1}
do
	cli="$cli -iname \*.$arg -o "
done
cli="$cli -iname \*.${@: -1} \)"

PRE_IFS=$IFS
IFS=$'\n'
for i in `eval $cli`
do
	enca -x GBK $i # 对文件进行编码转换
done
IFS=$PRE_IFS
echo "ok!"
