#*****************************************定义变量********************************************************************
###
 # @Author: ysyx_22050928-zheng zhong qiang 3486829357@qq.com
 # @Date: 2024-07-13 13:18:48
 # @LastEditors: ysyx_22050928-zheng zhong qiang 3486829357@qq.com
 # @LastEditTime: 2024-07-13 17:50:34
 # @FilePath: /ZzqLinuxConfig/bashrc/my_bashrc.sh
 # @Description: 这是默认设置,请设置`customMade`, 打开koroFileHeader查看配置 进行设置: https://github.com/OBKoro1/koro1FileHeader/wiki/%E9%85%8D%E7%BD%AE
###
ZZQ_CODE_HOME="${HOME}/Code"

#****************************************定义环境变量****************************************************************#
# 自己编写脚本的环境变量（所有自己编写的脚本都放在这里）
export EXE_SCIRPT_PATH="${HOME}/.zzq_config/zzqScript"

# 进入zzq自己配置的config
export ZCONFIG_PATH="${HOME}/.zzq_config"
# 这保存的是配到系统环境变量中的脚本
export OVERALL_EXE_BASIC_SCRIPT_PATH="${HOME}/.zzq_config/zzqScript/OverallScript/basic"

# 这里保存的脚本是不会配到环境变量中去的
export PART_EXE_SCRIPT_PATH="${HOME}/.zzq_config/zzqScript/PartScript/"

# 我的代码保存这里
export CODE_PATH="${HOME}/Code"

# mill的版本
export DEFAULT_MILL_VERSION=0.11.8

# 保存可执行软件的目录
export EXE_SOFT_PATH="/home/zzq/soft_collection"

# 我的项目保存在这里
export ITEM_PATH="${HOME}/Item"

# 我的笔记保存这里
export MARKDOWN_PATH="${HOME}/Markdown"

# 自己编写的库函数的环境变量
export ZZQ_C_LIB="${HOME}/Code/C_Cadd/zzqlib/"

# ysyx项目的路径
export YSYX_PATH="${HOME}/ysyx"

# ysyx的配置
export NEMU_HOME="${HOME}/ysyx/ysyx-workbench/nemu"
export AM_HOME="${HOME}/ysyx/ysyx-workbench/abstract-machine"
export NPC_HOME="${HOME}/ysyx/ysyx-workbench/npc"
export NVBOARD_HOME="${HOME}/ysyx/ysyx-workbench/nvboard"
# 配置JAVA的jvm所在路径
export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
#***************************************修改PATH环境变量****************************************************************
# 修改PATH环境变量
export PATH="${HOME}/bin:${PATH}"             # 用户自定义bin目录
export PATH="/usr/lib/ccache:${PATH}"         # 使用ccache加速gcc
export PATH="${HOME}/.local/bin:${PATH}"      # 用户本地安装的工具
export PATH="/usr/bin:/bin:${PATH}"           # 系统默认bin目录
export PATH="${OVERALL_EXE_BASIC_SCRIPT_PATH}:${PATH}" # 全局基本脚本目录
export PATH=$JAVA_HOME/bin:$PATH

#*************************************************alias****************************************************************
# 自定义快捷命令
alias zzqintozconfig="cd ${ZCONFIG_PATH}"
alias zzqintocode="cd ${CODE_PATH}"
alias zzqintoscirpt="cd ${EXE_SCIRPT_PATH}"        # 快速进入脚本目录
alias zzqintohosts="sudo vim /etc/hosts"           # 编辑hosts
alias zzqintoDiary="cd ${CODE_PATH}/Diary"         # 编辑日记
alias zzqintoDictionary="cd ${CODE_PATH}/Dictionary" # 进入自定义字典文件
alias zzqintoLinuxConfig="cd ${CODE_PATH}/Linux_Config"
alias zzqintoItem="cd ${ITEM_PATH}"
alias zzqintoTemplate="cd ${CODE_PATH}/Templates"  # 进入模板文件目录
alias zzqintoshell="cd ${CODE_PATH}/Shell"         # 进入脚本文件
alias zzqintoysyx="cd ${YSYX_PATH}/ysyx-workbench" # 进入一生一芯项目
alias zzqintoMarkdown="cd ${MARKDOWN_PATH}"        # 快速进入笔记文件
alias zzqintoMarkdownysyx="cd ${MARKDOWN_PATH}/ysyx" # 进入一生一芯笔记
alias zzqintoysyxnpc="cd ${NPC_HOME}"
alias reboot="sync; sync; sync; reboot"
alias zzqrm="rm -rfI"                              # rm命令的安全别名

#**************************************************软件特殊配置**********************************************************
# vivado环境变量 (注释掉，如果需要可以取消注释)
# source /home/zzq/pan_softwave/Xilinx/Vivado/2019.2/settings64.sh

# RISC-V环境变量
export RISCV="/usr/local/riscv"

# nvm (Node Version Manager) 的配置
export NVM_DIR="${HOME}/.nvm"
[ -s "${NVM_DIR}/nvm.sh" ] && \. "${NVM_DIR}/nvm.sh"  # This loads nvm
[ -s "${NVM_DIR}/bash_completion" ] && \. "${NVM_DIR}/bash_completion"  # This loads nvm bash_completion

