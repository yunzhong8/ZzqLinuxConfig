#******************************************************************** zzq自己设置的配置************************************#
###
 # @Author: ysyx_22050928-zheng zhong qiang 3486829357@qq.com
 # @Date: 2024-07-13 13:47:23
 # @LastEditors: ysyx_22050928-zheng zhong qiang 3486829357@qq.com
 # @LastEditTime: 2024-07-13 17:56:10
 # @FilePath: /ZzqLinuxConfig/bashrc/special_bashrc/ubuntu/linux_bashrc.sh
 # @Description: 这是默认设置,请设置`customMade`, 打开koroFileHeader查看配置 进行设置: https://github.com/OBKoro1/koro1FileHeader/wiki/%E9%85%8D%E7%BD%AE
### 
# 导入其他bashrc其他文件

#*****************************************变量**************************************************
OVERALL_EXE_UBUNTU_SCRIPT_PATH="${HOME}/.zzq_config/zzqScript/OverallScript/ubuntu"



#********************************************其他环境变量***********************************
export  STARDICT_DATA_DIR=/usr/share/stardict/dic/stardict-dict/
# 自己编写的库函数的环境变量
export ZZQ_C_LIB=/home/zzq/Code/C_Cadd/zzqlib/


#ChipLab 环境变量
export CHIPLAB_HOME=/home/zzq/code/LoogArch/chiplab

#*******************************************PATH***********************************************8
export PATH="${OVERALL_EXE_UBUNTU_SCRIPT_PATH}:${PATH}" # 全局Ubuntu脚本目录
### loogarch32环境变量
export PATH=/home/zzq/pan_softwave/loongarch32r-linux-gnusf-2022-05-20-x86/loongarch32r-linux-gnusf-2022-05-20/bin/:$PATH

#自己编写脚本的环境变量（所有自己编写的脚本都放在这里）
export PATH=/home/zzq/bin/:$PATH #export PATH=route:$PATH

export PATH=/home/zzq/.local/bin/:$PATH

#chiplibGCC交叉编译器的环境变量
export PATH=/home/zzq/code/LoogArch/chiplab/toolchains/loongarch32r-linux-gnusf-2022-05-20/bin/:$PATH

export export PATH=/usr/local/lib/nodejs/bin:/home/zzq/bin:/home/zzq/code/LoogArch/chiplab/toolchains/loongarch32r-linux-gnusf-2022-05-20/bin/:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/snap/bin:/snap/bin


#**********************************************alia****************************************
#zzq自己设置的按键别名
alias zzqintooldscirpt='cd /usr/local/bin/' # 快速进入脚本目录

#***************************************other********************************************************
# minicom配置
alias minicom='env LANG=en_US minicom'

## vivado环境变量
##使vivado可以在terminal上运行
source /home/zzq/pan_softwave/Xilinx/Vivado/2019.2/settings64.sh
