#! /bin/bash
#
# cmakefile.sh
# Copyright (C) 2024 zzq <zzq@zzq-HP-Pavilion-Gaming-Laptop-15-cx0xxx>
#
# Distributed under terms of the MIT license.
#

rm -rf makefile
echo "创建一个基本的c语言的Makefile文件,会删除本目录下的makefile
1 gdb 路径/xx.c 表示指定文件参与编译，最大5个
2 gdb 空 表示：当前目录下全部的.c文件都参与编译
3 gdb 空 表示：src目录全部的.c文件参与编译
"
touch makefile
function check_require_para() {
    local require_para_num=$1
    local parameter_names=$2
    local i=1
    while [ $i -lt  $require_para_num  ]
    do
        if [ -z ${!i} ];then
            echo "$0:${parameter_names[$i]}:未输入，终止脚本执行"
            exit 1
        else
            echo "${parameter_names[$i]}:${!i}"
        fi
		((i++))
    done
}
parameter_names=(1  modle参数 是否使用gdb的参数)
if [ -z $1 ];then
    echo "${parameter_names[1]}:未输入，终止脚本执行"
    exit 1
else
    echo "${parameter_names[1]}:$1"

fi

modle=$1
open_gdb=$2
check_require_para 2 $parameter_names
# 获取指定cpp文件的列表最大支持4个
cfile=() # 设置文件为空
for i in {3..8} # 参数get 3的都是c语言文件，将其拼接起来
do
    if [ ! -z ${!i} ];then
        cfile+="${!i} "
    fi
done
rm -rf makefile
## 编写生成makefile文件代码############################################################
# 定义伪目标
    echo ".PHONY:clean show" >> makefile
    echo "
CFLAGS = -Iinclude

EXECUTABLE = \$(BINDIR)/my_program
    " >> makefile

# 不同模式下makefile的obj的值不同
if [ $modle = 1 ];then
        echo "OBJ = $cfile" >> makefile
        echo "TARGET = exe" >> makefile
elif [ $modle = 2 ];then
        echo "OBJ := \$(wildcard *.c) #将当前文件下全部的.c文件作为依赖文件" >> makefile
        echo "TARGET = exe" >> makefile
elif [ $modle = 3 ];then
echo "SRCDIR = src # 保存项目源码
OBJDIR = obj # 保存全部项目用到.c文件汇编出的.o文件
BINDIR = bin # 保存项目依赖的库

SOURCES := \$(wildcard \$(SRCDIR)/*.c) # 搜索SRCDIR目录下的.c文件,并全部赋值给SOURCES变量
OBJ := \$(SOURCES:\$(SRCDIR)/%.c=\$(OBJDIR)/%.o) #将SOURCE文件的的变量（即文件带有相应的路径，全部变换的obj目录，且后缀修改为.o格式）
TARGET = \$(BINDIR)/exe  #可执行程序名称是exe，存放在BINDIR即bin中
    " >> makefile
    # elif [ $modle = 4 ];then
fi


# 设置makefile中目标文件的名称
echo "\$(TARGET):\$(OBJ)" >> makefile

 # 开启gdb模式下的makefile命令
if [ $open_gdb = "gdb" ] ;then
     echo -e '\t$(CXX) $^ -g -o $@' >> makefile # echo -e表示识别字符串中的特殊字符
     if [ $modle = 3 ];then
            echo "
(OBJECTS): \$(OBJDIR)/%.o : \$(SRCDIR)/%.c # OBJDIR变量中全部.c文件依赖于SRCDIR变量中的全部.c文件
	@mkdir -p \$(@D)
        " >> makefile
     else
            echo '%.o:%.cpp' >> makefile
     fi

        echo "生成具有gdb调试的makefile"
else #不启用gdb模式下的命令
        echo -e '\t$(CXX) $^ -o $@' >> makefile
     if [ $modle = 3 ];then
                echo "
(OBJECTS): \$(OBJDIR)/%.o : \$(SRCDIR)/%.c
	@mkdir -p \$(@D)
        " >> makefile
      else
        echo '%.o:%.cpp' >> makefile
      fi
        echo "生成不具有gdb调试的makefile"
fi

 echo -e '\t$''(CXX) -c $^ -o $''@' >> makefile


    # 设置make clean
    echo 'clean:' >> makefile
    echo -e '\t$''(RM) *.o $''(TARGET)' >> makefile
