#! /bin/bash
#
# zzqBatchFile.sh
# Copyright (C) 2024 zzq <zzq@zzq-HP-Pavilion-Gaming-Laptop-15-cx0xxx>
#
# Distributed under terms of the MIT license.
#
echo "
*************************************************************************
脚本基本功能：            进行批处理                                              *
脚本使用：                                                              *\n
eg：                                                                    *
    1.                                                                  *
    解释：                                                              *
    2.                                                                  *\n
其他信息：                                                              *
*************************************************************************\n"
parameter_names=(1 2 3 4 5 6) #输入参数的名称列表
parameter_num=2  # 脚本一定需要传入的参数个数
shell_script_path=/home/zzq/Code/Sheel/   # 脚本待调用的脚本的父目录
son_script_path=makefiles  # 待调用的脚本的子目录
call_script_path="$shell_script_path""$son_script_path"

#echo " $parameter_names zzq:$(seq 1 $parameter_names)"
#检测参数是否正确传入
for i in $(seq 1 $parameter_names)
do
    if [ -z ${!i}  ];then # $i是空则输出
        echo "${parameter_names[$i]}:未输入，终止脚本执行"
        exit 1
    else
        echo "${parameter_names[$i]}:${!i}"
    fi
done
#exit 1
folder_path=$1
handle_single_file_script=$2

# 获取用户输入
get_files_without_extension() {
    folder_path=$1
	work_path=$2
    cd $folder_path

    files_basename_list=()
    files_list=()

    for file in *; do
        if [ -f "$file" ]; then
            filename=$(basename "$file")
            files_list+=("$filename")
            filename_no_extension="${filename%.*}"
			extenion="${filename##*.}"
			echo $filename $extenion $filename
            files_basename_list+=("$filename_no_extension")
			# if [ $extenion = "v" ];then
            # 	files_basename_list+=("$filename")
			# fi
        fi
    done
	cd $work_path
}

deal_files(){
	folder_path=$1
	work_path=$2
	cd $folder_path

	for filename in "${files_list[@]}"; do
		chmod +x $handle_single_file_script # 确保脚本具有执行权
        /bin/bash $handle_single_file_script $filename # 对当个文件执行程序
	done 
	cd $work_path

}

get_files_without_extension $folder_path $(pwd)
deal_files $folder_path $(pwd)
