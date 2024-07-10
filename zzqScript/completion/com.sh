#! /bin/bash
#
# com.sh
# Copyright (C) 2024 zzq <zzq@zzq-HP-Pavilion-Gaming-Laptop-15-cx0xxx>
#
# Distributed under terms of the MIT license.
#
echo "
*************************************************************************
脚本基本功能：                                                          *
脚本使用：                                                              *\n
eg：                                                                    *
    1.                                                                  *
    解释：                                                              *
    2.                                                                  *\n
其他信息：                                                              *
*************************************************************************\n"
parameter_names=(1 2 3 4 5 6) #输入参数的名称列表

#检测参数是否正确传入
#for i in {1..5}
#do
#    if [ -z ${!i}  ];then # $i是空则输出
#        echo "${parameter_names[$i]}:未输入，终止脚本执行"
#        exit 1
#    else
#        echo "${parameter_names[$i]}:${!i}"
#    fi
#done
function completion(){
    local cur
    COMPREPLY=() # compreply
    cur="${COMP_WORDS[COMP_CWORD]}"
    if [[ ${cur} == "m" ]];then
        COMPREPLY=("man")
    elif [[ ${cur} == 't' ]];then
        COMPREPLY=("end")
    fi
}
complete -F completion "zzqman"

