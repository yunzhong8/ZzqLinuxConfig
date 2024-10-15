
all: sim
#make构建的可执行文件的所有中间文件保存在这个目录下
BUILD_DIR = $(abspath build)
#顶层可执行文件名称
TOP_NAME = 
# 最终可执行文件名称
#exe_name = $(BUILD_DIR)/$(TOP_NAME)
exe_name = $(BUILD_DIR)/tbexe
# C++文件所在目录
C_DIR = $(abspath tests)
# Verilog文件所在目录
VERILOG_DIR = $(abspath src)


# gcc编译的设置
# 设置gcc的额外检索目录
ZZQ_C_LIB=
SELF_CFLAGS = $(addprefix -I , $(ZZQ_C_LIB))

# 连接器编译的设置
SELF_LDFLAGS =
#verilator编译器名称
VERILATOR = verilator
#verilator编译器编译选项
VERILATOR_CFLAGS = -Wall --trace

#-Mdir $(BUILD_DIR)/obj_dir --CFLAGS -I../ -Wno-DECLFILENAME
BIN = $(BUILD_DIR)/$(TOPNAME)
# 如果bulid目录没有创建则创建
# 进入vsrc这个目录去执行后续指令，&&表示如果前面指令没有执行成功则不执行后续执行 $(VERILATOR) $(VERILATOR_CFLAGS) 表示使用verialtor 编译选项是 -Wall --trace
# 规定verilogd顶层模块名称为mux412
# 需要转为c++文件的verilog文件是$(VERILOG_SRC)
# 将$(TEST_BENCH_SRC)的c++代码和verilog转义出的c++文件一起编译成可执行文件
# 设置最终可执行文件的名称是$(exe_name)
# 指定verilator将转义出的c++文件保存在$(BUILD_DIR)/obj_dir
# -c 指定make在$(BUILD_DIR)/obj_dir查找makefile -f 指定V$(TOP_NAME).mk作为编译的makefile V$(TOP_NAME)表示最终生成的目标文件名
sim: $(VERILOG_SRC) $(TEST_BENCH_SRC)
	mkdir -p $(BUILD_DIR)
	cd $(VERILOG_DIR) && $(VERILATOR) $(VERILATOR_CFLAGS) \
	--top-module $(TOP_NAME) \
	--cc $(VERILOG_SRC) \
	--exe $(TEST_BENCH_SRC) \
	-o $(exe_name) \
	-Mdir $(BUILD_DIR)/obj_dir \
	-CFLAGS $(SELF_CFLAGS) \
	-LDFLAGS $(SELF_LDFLAGS) \
	--build
#	-CFLAGS $(SELF_CFLAGS) \
#	-LDFLAGS $(SELF_LDFLAGS) \

# make -j -C $(BUILD_DIR)/obj_dir -f V$(TOP_NAME).mk V$(TOP_NAME)
.PHONY: clean
clean:
	rm -rf $(BUILD_DIR)/obj_dir $(exe_name)

