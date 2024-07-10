#! /bin/bash
#
# zzqgitpush.sh
# Copyright (C) 2024 zzq <zzq@zzq-HP-Pavilion-Gaming-Laptop-15-cx0xxx>
#
# Distributed under terms of the MIT license.
#
echo -e "
*************************************************************************
脚本基本功能：快速推送代码到我对远程库                                  *
脚本使用：                                                              *\n
eg：                                                                    *
    1.                                                                  *
    解释：                                                              *
    2.                                                                  *\n
其他信息：                                                              *
*************************************************************************\n"
parameter_names=(1 git_action repo_path) #输入参数的名称列表

repos=(PdfBookRepo  LoogArchRepo  CodeRepo YsyxRepo repo1/ysys_workbench_repo )
git_path="/home/zzq"
git_files=(book_pdf LA Code ysyx ysyx/ysyx-workbench)
#***************************************************************** 函数定义 ***************************************************#
function git_push_fun(){
    local commit_content=$1
    local git_path=$2
    local git_file=$3
    local repo_path=$4
    local repo=$5
    local action=$6
    echo "commit_content:$commit_content"
    echo "repo_path:$repo_path/$repo"
    cd "$git_path/$git_file"
    pwd
    if [ $action = "pull" ];then
        git pull "$repo_path/$repo"
        if [ $? -eq 0 ];then
            echo -e "代码拉取成功\n\n\n"
        else
            echo -e "执行错误,脚本运行终止\n\n\n"
            exit 1
        fi
    elif [ $action = "push" ];then
        git add .
        if [ $? -eq 0 ];then
            echo "文件添加入缓存区"
        else
            echo "执行错误，脚本终止执行"
            exit 1
        fi

        git commit -m "$commit_content"
        if [ $? -eq 0 ];then
            echo "文件提交"
        #else
        #    echo "执行错误，脚本终止运行"
        #    exit 1
        fi

        git push "$repo_path/$repo"
        if [ $? -eq 0 ];then
            echo -e "代码推送成功\n\n\n"
        else
            echo -e "执行错误,脚本运行终止\n\n\n"
            exit 1
        fi
    fi
}
#******************************************************** 主要代码 *************************************************#
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

action=$1 #对git对仓库操作的行为
repo_path=$2
if [ $2 = 1 ];then # 使用固态硬盘的本地仓库
repo_path="/media/zzq/android/Repo"
elif [ $2 = 2 ];then # 使用机械硬盘的本地仓库
repo_path="/media/zzq/My_Passport/Repo/ZzqData"
else
    echo "输入路径选择"
    exit 1
fi
repo_num=4 #仓库个数，数值再+1就是仓库个数

# 将仓库进行推送或者拉取
for i in $(seq 0 $repo_num)
do
    now_date=$(date)
    echo "$now_date"
    git_push_fun "$now_date" "$git_path" "${git_files[$i]}" "$repo_path" "${repos[$i]}" "$action"
done









