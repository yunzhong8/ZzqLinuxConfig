#! /bin/sh
#
# zzqvpn.sh
# Copyright (C) 2024 zzq <zzq@zzq-HP-Pavilion-Gaming-Laptop-15-cx0xxx>
#
# Distributed under terms of the MIT license.
#
echo "使用方法：zzqvpn 命令.eg:zzqvpn start"
echo "start表示开启，close表示关闭"
if [ -z $1 ] ;then
    echo "没有输入对vpn的操作"
    exit 1
fi
if [ $1="start" ];then
    echo "vpn正在打开"
    # strongvpn的打开vpn
    # zzqstrongvpn start

    #clash的打开vpn
    echo "设置网络代理为手动"
	gsettings set org.gnome.system.proxy mode 'manual'
    echo "正在打开clash的vpn，使用魔戒"
	cd ~/soft_collection/ClashforWindows
    ./cfw
    #启用网络代理变量（没用不知道这是什么意思）
    #export http_proxy='http://proxyServerSddress:proxyPort'
    #export https_proxy='https://proxyServerSddress:proxyPorto'
	echo "网络代理切换为自动模式"
	gsettings set org.gnome.system.proxy mode 'auto'
    echo "vpn关闭"
elif [ $1="close" ];then
    echo "vpn正在关闭"
    #不启用网络代理变量
    #unset http_proxy
    #unset https_proxy
    echo "vpn关闭"
fi
