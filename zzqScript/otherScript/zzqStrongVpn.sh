#!/bin/sh
#介绍
#这是一个借用strongvpn账号，快速登入外网的脚本
#账号密码：888888一旦修改就会错误
#存放位置/usr/loacl/bin/strongvpnzzq
#read -p "输入类型" type
type=$1 #第一个变量为type
echo 操作：打开up,关闭down,检查链接状态：status
pw=888888
#判断输入操作类型
echo $pw | sudo -S ipsec $type a337877

