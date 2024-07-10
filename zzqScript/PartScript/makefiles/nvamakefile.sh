#! /bin/bash
#
# nvamakefile.sh
# Copyright (C) 2024 zzq <zzq@zzq-HP-Pavilion-Gaming-Laptop-15-cx0xxx>
#
# Distributed under terms of the MIT license.
#

echo "创建一个基本的Makefile文件,会删除本目录下的makefile"
echo "需要输入两个变量：\n
1. 数字：表示模式，
    1：表示自己指定文件，最大支持指定4个文件
    2：表当前目录下全部.c文件(即所有文件都在一个目录)
    3：表示包含目录的（即这个makefile要处理多个目录的文件）这种一般是构成c语言项目了，建议按照c语言的项目结构安排
1、xx.c表示对哪个文件c文件进行make\n
2、gdb表示要使用gdb编译
item_type :c va nva
c_mode:1 2 3 va 1 2 3 nva_mode:1 2 3
1 表示tb
gdb:gdb top_name:
file_name:
"
echo " eg：zzqmakefile 1 gdb exe.c
echo 表示采用指定文件模式，启用gdb调试，对exe.c文件进行编译
"
touch makefile
function check_require_para(){
    local require_para_num=$1
    local parameter_names=$2
    local i=1
    while [ $i -lt  $require_para_num ]
    do
        if [ -z ${!i} ];then
            echo "${parameter_names[$i]}:未输入，终止脚本执行"
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

require_para_num=2
check_require_para $parameter_names $require_para_num
top_name=$1
modle1=$2
# 获取指定cpp文件的列表最大支持4个
cmodle=${modle1:0:1}
cfile_num=${modle1:1:2}

cfile=() # 设置文件为空
if [ $cmodle = 3 ];then
	for i in {3..$(expr $cfile_num + 2 )} # 参数get 3的都是c语言文件，将其拼接起来
	do
	    if [ ! -z ${!i} ];then
	        cfile+="${!i} "
	    fi
	done
fi
modle2=$3
vmodle=${modle2:0:1}
vfile_num=${modle2:1:2}

vfile=() # 设置文件为空

if [ $vmodle = 3 ];then
	for i in {$(expr $cfile_num + 4 )..$(expr $cfile_num + 4 + $vfile -1 )} # 参数get 3的都是c语言文件，将其拼接起来
	do
	    if [ ! -z ${!i} ];then
	        vfile+="${!i} "
	    fi
	done
fi
    echo "
TOPNAME = $top_name
NXDC_FILES = constr/top.nxdc
INC_PATH ?=
VSRC = src
CSRC = tests
VERILATOR = verilator
VERILATOR_CFLAGS += -MMD --trace --build -cc  \\
				-O3 --x-assign fast --x-initial fast --noassert

BUILD_DIR = ./build
OBJ_DIR = \$(BUILD_DIR)/obj_dir
#BIN = \$(BUILD_DIR)/\$(TOPNAME)
BIN = \$(BUILD_DIR)/tbexe
default: \$(BIN)

\$(shell mkdir -p \$(BUILD_DIR))

# constraint file
SRC_AUTO_BIND = \$(abspath \$(BUILD_DIR)/auto_bind.cpp)
\$(SRC_AUTO_BIND): \$(NXDC_FILES)
	python3 \$(NVBOARD_HOME)/scripts/auto_pin_bind.py $^ \$@

# project source
VSRCS = \$(shell find \$(abspath ./\$(VSRC)) -name "*.v")
" >> makefile
if [ $cmodle = 2 ];then
    echo "CSRCS = \$(shell find \$(abspath ./\$(CSRC)) -name "*.c" -or -name "*.cc" -or -name "*.cpp")" >>makefile
elif [ $cmodle = 1 ];then # 添加tests目录下和顶层模块同名的tb文件作为测试函数
    echo "CSRCS = \$(abspath ./\$(CSRC))/tb_\$(TOPNAME).cpp"  >>makefile
elif [ $cmodule = 3 ];then #添加指定目录下文件
    echo "CSRCS = $cfile" >>makefile
fi

echo "
CSRCS += \$(SRC_AUTO_BIND)

# rules for NVBoard
include \$(NVBOARD_HOME)/scripts/nvboard.mk

# rules for verilator
INCFLAGS = \$(addprefix -I, \$(INC_PATH))
CXXFLAGS += \$(INCFLAGS) -DTOP_NAME=\"\\\"V\$(TOPNAME)\\\"\"

\$(BIN): \$(VSRCS) \$(CSRCS) \$(NVBOARD_ARCHIVE)
	@rm -rf \$(OBJ_DIR)
	\$(VERILATOR) \$(VERILATOR_CFLAGS) \\
		--top-module \$(TOPNAME) $^ \\
		\$(addprefix -CFLAGS , \$(CXXFLAGS)) \$(addprefix -LDFLAGS , \$(LDFLAGS)) \\
		--Mdir \$(OBJ_DIR) --exe -o \$(abspath \$(BIN))

all: default

run: \$(BIN)
	@$^

clean:
	rm -rf \$(BUILD_DIR)

.PHONY: default all clean run
" >> makefile



