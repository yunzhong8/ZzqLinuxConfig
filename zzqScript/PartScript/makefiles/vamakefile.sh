#! /bin/bash
echo "创建一个基本的Makefile文件,会删除本目录下的makefile"

echo "需要输入两个变量：\n
vamakefile vfile_top_name c_mode [c_file_path] v_mode [v_file_path]
c_mode:1 2 3 va 1 2 3 nva_mode:1 2 3
1.c_mode 数字：表示模式，
    1：default:test/top_\$(top_name).cpp as test cpp
    2: default:test/all .cpp as test cpp
    3：self set cpp file ,max support num :4 ,input absulot path
2.v-mode :
	1: default:src/\$(top_name).v as verilog file
	2: default:src/all .v as verilog file
	3: self v file ,max support num :4,input absulot path
"

touch makefile
#******************************************* 解析传入的参数******************************************
# 检查参数个数
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
parameter_names=(1  verilog的顶层文件名 C语言文件模式 ... Verilog文件模式 ....)
require_para_num=2
check_require_para $parameter_names $require_para_num

top_name=$1
modle1=$2
# 获取指定cpp文件的列表最大支持4个
cmodle=${modle1:0:1}
cfile_num=${modle1:1:2}

modle2=$3
cfile=() # 设置文件为空
if [ $cmodle = 3 ];then
	i=3
	modle2_index=$(expr $cfile_num + 3 )
	while [ $i -lt $modle2_index ] # 参数get 3的都是c语言文件，将其拼接起来
	do
	    if [ ! -z ${!i} ];then
	        cfile+="${!i} "
	    fi
		((i++))
	done
	modle2=${!modle2_index}
fi

vmodle=${modle2:0:1}
vfile_num=${modle2:1:2}

vfile=() # 设置文件为空
if [ $vmodle = 3 ] ;then
	for i in {$(exper $cfile_num + 4 )..$(expr $cfile_num + 4 + $vfile -1 )} # 参数get 3的都是c语言文件，将其拼接起来
	do
	    if [ ! -z ${!i} ];then
	        vfile+="${!i} "
	    fi
	done
fi
rm -rf makefile

## 编写生成makefile文件代码############################################################
echo "
all: sim
#make构建的可执行文件的所有中间文件保存在这个目录下
BUILD_DIR = \$(abspath build)
#顶层可执行文件名称
TOP_NAME = $top_name
# 最终可执行文件名称
#exe_name = \$(BUILD_DIR)/\$(TOP_NAME)
exe_name = \$(BUILD_DIR)/tbexe
# C++文件所在目录
C_DIR = \$(abspath tests)
# Verilog文件所在目录
VERILOG_DIR = \$(abspath src)
" >> makefile
#测试文件设置
if [ $cmodle = 1 ];then # 添加tests目录下某个cpp文件作为测试函数
    echo "TEST_BENCH_SRC = \$(C_DIR)/tb_$top_name.cpp">>makefile
elif [ $cmodle = 2 ];then # 添加tests目录下全部文件
    echo "TEST_BENCH_SRC := \$(wildcard \$(C_DIR)/*.cpp)">>makefile
elif [ $cmodle = 3 ];then # 添加指定目录下某文件
    echo "TEST_BENCH_SRC := $cfile">>makefile
fi


# v文件设置
if [ $vmodle = 1 ];then
	#verilog资源文件名称
	echo "VERILOG_SRC := \$(VERILOG_DIR)/$top_name.v" >>makefile
elif [ $vmodle = 2 ] ;then
	#verilog资源文件名称
	echo "VERILOG_SRC := $(wildcard $(VERILOG_DIR)/*.v)" >>makefile
elif [ $vmodle = 3 ] ;then
	#verilog资源文件名称
	echo"VERILOG_SRC := $vfile" >>makefile

fi


echo "
# gcc编译的设置
# 设置gcc的额外检索目录
ZZQ_C_LIB=
SELF_CFLAGS = \$(addprefix -I , \$(ZZQ_C_LIB))

# 连接器编译的设置
SELF_LDFLAGS =
#verilator编译器名称
VERILATOR = verilator
#verilator编译器编译选项
VERILATOR_CFLAGS = -Wall --trace

#-Mdir \$(BUILD_DIR)/obj_dir --CFLAGS "-I../ -Wno-DECLFILENAME"
BIN = \$(BUILD_DIR)/\$(TOPNAME)
# 如果bulid目录没有创建则创建
# 进入vsrc这个目录去执行后续指令，&&表示如果前面指令没有执行成功则不执行后续执行 \$(VERILATOR) \$(VERILATOR_CFLAGS) 表示使用verialtor 编译选项是 -Wall --trace
# 规定verilogd顶层模块名称为mux412
# 需要转为c++文件的verilog文件是\$(VERILOG_SRC)
# 将\$(TEST_BENCH_SRC)的c++代码和verilog转义出的c++文件一起编译成可执行文件
# 设置最终可执行文件的名称是\$(exe_name)
# 指定verilator将转义出的c++文件保存在\$(BUILD_DIR)/obj_dir
# -c 指定make在\$(BUILD_DIR)/obj_dir查找makefile -f 指定V\$(TOP_NAME).mk作为编译的makefile V\$(TOP_NAME)表示最终生成的目标文件名
sim: \$(VERILOG_SRC) \$(TEST_BENCH_SRC)
	mkdir -p \$(BUILD_DIR)
	cd \$(VERILOG_DIR) && \$(VERILATOR) \$(VERILATOR_CFLAGS) \\
	--top-module \$(TOP_NAME) \\
	--cc \$(VERILOG_SRC) \\
	--exe \$(TEST_BENCH_SRC) \\
	-o \$(exe_name) \\
	-Mdir \$(BUILD_DIR)/obj_dir \\
	-CFLAGS \$(SELF_CFLAGS) \\
	-LDFLAGS \$(SELF_LDFLAGS) \\
	--build
#	-CFLAGS \$(SELF_CFLAGS) \\
#	-LDFLAGS \$(SELF_LDFLAGS) \\

# make -j -C \$(BUILD_DIR)/obj_dir -f V\$(TOP_NAME).mk V\$(TOP_NAME)
.PHONY: clean
clean:
	rm -rf \$(BUILD_DIR)/obj_dir \$(exe_name)
" >> makefile
