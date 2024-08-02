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

echo "
//c++库文件
#include<stdlib.h>
#include<iostream>
#include<assert.h>

//个人库文件

//verilator的头文件
#include<verilated.h>
#include<verilated_vcd_c.h>
" > $file_name
#将verilog转换的文件包含进去
echo "#include\"V$v_file_name_nosuffix.h\"" >> $file_name
#如果属性文件也存在则包含进去
if [ -f "$cur_path/obj_dir/V$v_file_name__024unit.h" ];then
    echo "#include\"V$v_file_name__024unit.h\"" >> $file_name
fi
echo "
using namespace std;
//仿真时钟周期
#define MAX_SIM_TIME 2000
vluint64_t sim_time = 0;


//创建模块变量
V$v_file_name_nosuffix *dut= new V$v_file_name_nosuffix;
static void signle_cycle(){
    dut->clk=0;dut->eval();
    dut->clk=1;dut->eval();
}
//重置verilog模块
static void reset(int n) {
  dut.rst = 1;
  while (n -- > 0) //每次n-1,如果n>0则一直执行
      single_cycle();
  dut->rst = 0;
}

//根据某个条件记录波形
void dum_n_cycle(VerilatedVcdC *m_trace ,const std::unique_ptr<VerilatedContext>& contextp, int front_cycles,int back_cycles)
{
	for (int i=-front_cycles;i<=back_cycles;i++){
	//for (int i=0;i<=back_cycles;i++){
		m_trace->dump(contextp->time()+i);
		//m_trace->dump( sim_time+i);
		if(i%10==0)
			cout<<"记录"<<endl;
		//m_trace->dump( i);
	}
}


//主函数
int main(int argc,char ** argv,char **env){

const std::unique_ptr<VerilatedContext> contextp{new VerilatedContext};
    //创建波形变量，波形保存到waveform.vcd
    Verilated::traceEverOn(true);
    VerilatedVcdC *m_trace = new VerilatedVcdC;
    dut->trace(m_trace, 5);
    m_trace->open(\"waveform.vcd\");

  //前10个周期都是复位
  reset(10);

    while (contextp->time() < MAX_SIM_TIME) {
      //assert(  );#检查是否发生错误
      signle_cycle();//获取模块输入输出变量的值
      m_trace->dump(contextp->time());//将值按照时钟周期保存到波形文件

	  dum_n_cycle(m_trace,contextp,1000,1000);
	  contextp->timeInc(1)
    }

    //结束
    m_trace->close();
    delete dut;
    exit(EXIT_SUCCESS);
}
" >>$file_name

