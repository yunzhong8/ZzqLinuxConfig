#! /bin/bash
#
# zzqrunnemutest.sh
# Copyright (C) 2024 zzq <zzq@zzq-HP-Pavilion-Gaming-Laptop-15-cx0xxx>
#
# Distributed under terms of the MIT license.
#
echo "
*************************************************************************
脚本基本功能：                                                          *
脚本使用：                                                              *\n
eg：                                                                    *
    1.     ~ native/nemu batch/a/m/o  blank/xx/xx                                                             *
    解释：                                                              *
    2.                                                                  *\n
其他信息：                                                              *
*************************************************************************\n"
parameter_names=(1  使用平台 类型  运行测试名不带后缀 3 4 5 6) #输入参数的名称列表

#检测参数是否正确传入
for i in {1..2}
do
    if [ -z ${!i}  ];then # $i是空则输出
        echo "${parameter_names[$i]}:未输入，终止脚本执行"
        exit 1
    else
        echo "${parameter_names[$i]}:${!i}"
    fi
done
get_files_without_extension() {
    folder_path=$1
	work_path=$2
    cd $folder_path

    files_list=()

    for file in *; do
        if [ -f "$file" ]; then
            filename=$(basename "$file")
            filename_no_extension="${filename%.*}"
            files_list+=("$filename_no_extension")
        fi
    done

    #echo "文件夹 $folder_path 中的文件列表（不带后缀）："
    #for filename in "${files_list[@]}"; do
    #    echo "$filename"
    #done
	cd $work_path
}



platform=$1
if [ $platform = "nemu" ] ;then
	platform="riscv32-$platform"
fi
run_type=$2
test_name=$3
log_path="/home/zzq/ysyx/ysyx-workbench/am-kernels/tests/cpu-tests/log.txt"
folder_path="/home/zzq/ysyx/ysyx-workbench/am-kernels/tests/cpu-tests/tests"
get_files_without_extension $folder_path $(pwd)

make_func(){
	if [ $run_type = "batch" ] ;then
		cd "/home/zzq/ysyx/ysyx-workbench/am-kernels/tests/cpu-tests"
		echo "start" > $log_path
		for filename in "${files_list[@]}"; do
	    	make ARCH=$platform ALL=$filename run >> $log_path
			#echo " make ARCH=$platform ALL=$filename run >> $log_path"
	    	#make ARCH=$platform ALL=$filename run
		done
	elif [ $run_type = 'a' ];then
		cd "/home/zzq/ysyx/ysyx-workbench/am-kernels/tests/cpu-tests"
		make ARCH=$platform ALL=$test_name run
	elif [ $run_type = 'm' ];then
		echo "执行m模式"
		echo "$(pwd)"
		echo "make ARCH=$platform mainargs=$test_name run"
		make ARCH=$platform mainargs=$test_name run
	elif [ $run_type = 'o' ];then
		echo "执行ordinay模式"
		make ARCH=$platform  run
	else
		echo "ERROR:run_type= $run_type is not exit "
	fi
}
make_func
