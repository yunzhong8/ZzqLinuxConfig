#! /bin/bash
#
# zzqtouch.sh
# Copyright (C) 2024 zzq <zzq@zzq-HP-Pavilion-Gaming-Laptop-15-cx0xxx>
#
# Distributed under terms of the MIT license.
#
echo "
*************************************************************************
脚本基本功能：                                                          *
脚本使用：zzqtouch vatb 测试.cpp verilog.v                                   *\n
eg：                                                                    *
    1.                                                                  *
    解释：                                                              *
    2.                                                                  *\n
其他信i息：
vatb nvatb*
*************************************************************************\n"
parameter_names=(1  filename v_filename 4 5 6) #输入参数的名称列表

#检测参数是否正确传入
parameter_num=2
for i in $(seq 1 $parameter_names)
do
    if [ -z ${!i}  ];then # $i是空则输出
        echo "${parameter_names[$i]}:未输入，终止脚本执行"
        exit 1
    else
        echo "${parameter_names[$i]}:${!i}"
    fi
done

file_name=$1
v_file_name=$2
v_file_name_nosuffix=${v_file_name%.*}
cur_path=$(pwd)

echo "//将verilog转换的文件包含进去
#include\"V$v_file_name_nosuffix.h\"" > $file_name
    echo "
#include <nvboard.h>
//verilator的头文件
#include<verilated.h>
#include<verilated_vcd_c.h>

//定义了一个TOP_NAME类型的静态变量，变量名是dut
static TOP_NAME dut;
//绑定引脚函数
void nvboard_bind_all_pins(TOP_NAME* top);

//记录一个时钟周期的的top文件的波形
static void single_cycle() {
  dut.clk = 0; dut.eval();
  dut.clk = 1; dut.eval();
}

//重置verilog模块
static void reset(int n) {
  dut.rst = 1;
  while (n -- > 0) //每次n-1,如果n>0则一直执行
      single_cycle();
  dut.rst = 0;
}

int main() {
		Verilated::traceEverOn(true);
	const std::unique_ptr<VerilatedContext> contextp{new VerilatedContext};
	//创建波形变量，波形保存到waveform.vcd
	VerilatedVcdC *m_trace = new VerilatedVcdC;
	dut.trace(m_trace, 5);
	m_trace->open(\"waveform.vcd\");

  //初始化nvboard
  nvboard_init();

  //前10个周期都是复位
  reset(10);

 //死循环
  while(1) {
    const std::unique_ptr<VerilatedContext> contextp{new           VerilatedContext};
	//更新nvborad的界面数据
    nvboard_update();
    //记录一个时钟周期的模块输入输出数据
    single_cycle();

    m_trace->dump(contextp->time());//将值按照时钟周期保存到波形文件
	contextp->timeInc(1);

  }
	m_trace->close();
	exit(EXIT_SUCCESS);

}
" >> "$file_name"

