#! /bin/bash
#
# zzqmkcdir.sh
# Copyright (C) 2024 zzq <zzq@zzq-HP-Pavilion-Gaming-Laptop-15-cx0xxx>
#
# Distributed under terms of the MIT license.
#
echo "
*************************************************************************
脚本基本功能：创建一个C语言项目文件夹                                   *
脚本使用：    zzqmkcdir 项目类型 c语言项目名称                                   *\n
eg：                                                                    *
    1.       zzqmkcdir nva temp                                             *
    解释：   会在当前目录创建一个temp的目录,C语言项目名称不能带有路径   *
    2.                                                                  *\n
其他信息：                                                              *
*************************************************************************\n"
parameter_names=(1 item_type 文件名称) # 输入参数名称列表
bin_readme_content='#\n这是一个保存项目库文件的目录
1. 可执行程序：经过编译链接后生成的可执行程序，用户可以直接运行。
2. 命令行工具：如果是命令行界面（CLI）工具或实用程序，它们通常会被放置在 "bin" 目录下。
3. 脚本文件：有些项目会将一些需要被直接执行的脚本文件（如bash脚本、Python脚本等）放置在 "bin" 目录下进行统一管理。
'
src_readme_content="#\n这是一个保存项目源文件的目录
1. 源代码文件：主要的源代码文件，通常是编程语言（例如C、C++、Java等）中的源文件，用于实现项目的核心功能。
2. 头文件：如果是C/C++项目，可能还会包含头文件（.h或.hpp文件），用于声明函数原型、宏定义和类的声明等。
3. 配置文件：某些项目可能会将配置文件放在此处，用于配置项目的各种参数和选项。
4. 子目录：为了组织代码和模块化开发，"src" 目录可能包含多个子目录，每个子目录对应一个特定的功能模块或库
"
tests_readme_content="#\n常用于保存项目的测试代码和测试相关的资源文件
1. 单元测试：针对代码中的单个函数、类或模块进行的测试，通常以单元测试框架（如JUnit、Pytest等）编写。
2. 集成测试：用于验证多个组件之间的交互和集成情况。
3. 端到端测试：模拟真实场景下用户操作，验证整个系统的功能和性能。
4. 测试数据：可能包括测试所需的输入数据、期望输出数据以及其他测试用例相关的资源文件。
5. 测试配置文件：包括测试运行环境的配置文件，如测试数据库的配置文件、Mock服务的配置文件等
"
build_readme_content="#\n这是一个保存：
+ 可执行文件：编译后生成的可执行程序或库文件。
+ 中间文件：编译过程中生成的临时文件和中间结果，如目标文件（.o）、链接文件等。
+ 构建配置文件：包括编译器和链接器生成的配置文件，例如 Makefile 或 CMakeLists.txt 等。
+ 日志文件：记录构建过程中的警告、错误和其他信息的日志文件。
+ 构建工具生成的输出：例如静态分析工具的报告、代码覆盖率报告等。
"
# 根据路径和文件名称创建文件
function create_file(){
    local father_path="$1/$2"
    local cur_dir_name=$2
    local file_name=$3
    echo " father_path:$father_path,file_name:$file_name"
    cd $father_path
    touch "$file_name"

    if [ $? -eq 0 ]; then
        echo "成功创建$father_path/$file_name文件"
    else
        echo "无法创建$father_path/$file_name文件"
    fi

    if [ $cur_dir_name  = 'src' ] ; then
        if [ $file_name  = 'readme.md' ];then
            echo -e "$src_readme_content" > $file_name
        fi
    elif [ $cur_dir_name = 'bin' ];then
        if [ $file_name  = 'readme.md' ];then
            echo -e "$bin_readme_content" > $file_name
        fi
    elif [ $cur_dir_name = 'tests' ];then
        if [ $file_name  = 'readme.md' ];then
            echo -e "$tests_readme_content" > $file_name
        fi
    elif [ $cur_dir_name = 'bulid' ];then
        if [ $file_name  = 'readme.md' ];then
            echo -e "build_readme_content" > $file_name
        fi
    fi

}
# 根据路径和目录名创建目录
function create_dir(){
    cd $1
    mkdir "$2"
    if [ $? -eq 0 ]; then
        echo "成功创建$1/$2目录"
    else
        echo "无法创建$1/$2目录"
    fi
}
# 检查参数是否传入
for i in {1..2}
do
    if [ -z ${!i}  ];then # $i是空则输出
        echo "${parameter_names[$i]}:未输入，终止脚本执行"
        exit 1
    else
        echo "${parameter_names[$i]}:${!i}"
    fi
done
# 在当前目录创建目录
item_type=$1
dir_name=$2
mkdir $dir_name
# 获取创建好的目录的路径
father_path=$(pwd)
path="$father_path/$dir_name"

create_file "$father_path" "$dir_name"  "readme.md"
create_file "$father_path" "$dir_name" "makefile"
create_file "$father_path" "$dir_name" "LICENSE"

create_dir "$path" "bin"
create_file "$path" "bin" "readme.md"

create_dir "$path" "build"
create_file "$path" "build" "readme.md"

create_dir "$path" "src"
create_file "$path" "src" "readme.md"

create_dir "$path" "tests"
create_file "$path" "tests" "readme.md"

create_dir "$path" "include"
create_file "$path" "include" "readme.md"
verilog_module=/home/zzq/ysyx/ysyx-workbench/nvboard/example/vsrc/*.v
if [ $item_type = 'nva' ];then
    create_dir "$path" "constr"
    create_dir "$path" "resource"
    cp  "/home/zzq/ysyx/ysyx-workbench/nvboard/example/resource/picture.hex" "$path/resource"
    cp $verilog_module "$path/src"
    echo $!!
    cp "/home/zzq/ysyx/ysyx-workbench/nvboard/example/constr/top.nxdc" "$path/constr"
fi
echo "目录创建完成"

