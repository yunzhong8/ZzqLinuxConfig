#!/bin/bash

# 定义目标文件名
script_name="single_handle.sh"
touch $script_name

# 使用 Here Document 将内容写入文件
cat << 'EOF' > $script_name
#!/bin/bash
echo "
*************************************************************************
脚本基本功能：                                                          *
脚本使用：  zzqBackUp  运行模式                                         *
# 0 表示不设置参数采用默认值
# 1 表示自己设置第一个参数的值
# 2 表示自己设置第二个参数的值
# 3 表示自己设置全部参数的值
eg：                                                                    *
    1.这是一个被批处理脚本调用的脚本，请自己编写。
默认这个文件脚本工作在脚本所在目录                                      *
    ./single_handle.sh name of file handled
    2.                                                                  *
其他信息：                                                              *
*************************************************************************\n"

# 检测参数是否传入的代码
parameter_names=(传入要被处理文件的名称 2 3 4 5 6) #输入参数的名称列表
parameter_num=1  # 脚本一定需要传入的参数个数

#echo " $parameter_names zzq:$(seq 1 $parameter_num)"
#检测参数是否正确传入
for i in $(seq 1 $parameter_num)
do
    if [ -z ${!i}  ];then # $i是空则输出
        echo "${parameter_names[$i]}:未输入，终止脚本执行"
        exit 1
    else
        echo "${parameter_names[$i]}:${!i}"
    fi
done

#待传入的参数
handle_file_name=$1

# 该脚本所在路径
single_script_path=$2

#待被处理的文件所在路径
handle_file_path=$3

if [ -z $single_script_path ]; then
    single_script_path=$(pwd)
fi

if [ -z $handle_file_path ]; then
    handle_file_path=$(pwd)
fi


#以下内容是个人需要配置的
#设置当前脚本工作路径
script_work_path=$handle_file_path
handle_file_suffix=.sh

# 进入脚本工作路径
pushd $script_work_path

pwd
echo $handle_file_name
file_no_suffix=$(basename -s $handle_file_suffix  $handle_file_name)
#todo
error=
if [ $error ] ;then
	exit -1
fi
popd
EOF

# 赋予脚本执行权限
chmod +x $script_name

echo "文件 $script_name 已创建并赋予执行权限"

