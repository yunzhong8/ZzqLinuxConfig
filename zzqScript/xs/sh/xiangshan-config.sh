#!/bin/bash
# XiangShan 多版本环境配置文件（不依赖 jq）

# 环境配置数组（格式："名称:分支名"）
ENVS=(
    "baseline:base/clean"
    "nl-v1:feature/nextline-v1"
    "nl-v2:feature/nextline-v2"
    "nl-v3:feature/nextline-v3"
)

# 共享目录（从父目录链接）
SHARED_DIRS=(
    "DRAMsim3"
    "NEMU"
    "NutShell"
    "nexus-am"
)

# 需要复制的文件（从父目录）
COPY_FILES=(
    "env.sh"
    ".envrc"
    "Dockerfile"
    "centos.Dockerfile"
    "install-verilator.sh"
)
