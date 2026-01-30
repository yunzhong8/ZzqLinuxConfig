#!/bin/bash
# 通用的 Git 多版本分支管理脚本
set -e

# 颜色
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 默认配置（可被参数覆盖）
REPO_PATH="${REPO_PATH:-$(pwd)}"
UPSTREAM_BRANCH="${UPSTREAM_BRANCH:-main}"
BASE_PREFIX="${BASE_PREFIX:-base}"
FEATURE_PREFIX="${FEATURE_PREFIX:-feature}"

# 函数：显示用法
usage() {
    cat <<EOF
用法: $0 [选项] <操作>

全局选项:
    --repo PATH             仓库路径 (默认: 当前目录)
    --upstream BRANCH       上游分支 (默认: main)
    --base-prefix PREFIX    基础分支前缀 (默认: base)
    --feature-prefix PREFIX 功能分支前缀 (默认: feature)

操作:
    --init [BASE] [FEATURE]
        初始化分支结构
        BASE: 基础分支名（默认: clean）
        FEATURE: 功能分支名（默认: nextline-base）
    
    --create-base NAME
        创建基础分支（基于上游分支）
    
    --create-child NAME --base BASE
        创建子分支（基于指定的基础分支）
    
    --create-versions BASE N
        创建 N 个版本分支（v1, v2, ..., vN）
    
    --list
        列出所有相关分支
    
    -h, --help
        显示此帮助信息

示例:
    # 在默认仓库初始化
    $0 --init
    
    # 在指定仓库初始化
    $0 --repo /path/to/repo --upstream kunminghu-v3 --init clean nextline-base
    
    # 创建 4 个版本分支
    $0 --repo /path/to/repo --create-versions feature/nextline-base 4
    
    # 创建新的基础分支
    $0 --repo /path/to/repo --create-base experiment
    
    # 创建子分支
    $0 --repo /path/to/repo --create-child feature/nextline-v4 --base feature/nextline-base

环境变量:
    REPO_PATH           仓库路径
    UPSTREAM_BRANCH     上游分支
    BASE_PREFIX         基础分支前缀
    FEATURE_PREFIX      功能分支前缀

EOF
}

# 函数：创建或切换到分支
create_or_checkout_branch() {
    local branch_name=$1
    local base_branch=$2
    
    cd "$REPO_PATH"
    
    if git rev-parse --verify "$branch_name" >/dev/null 2>&1; then
        echo -e "  ${YELLOW}⚠${NC} 分支 $branch_name 已存在，切换到该分支"
        git checkout "$branch_name"
        return 1
    else
        echo -e "  ${GREEN}✓${NC} 创建新分支: $branch_name (基于 $base_branch)"
        git checkout -b "$branch_name" "$base_branch"
        return 0
    fi
}

# 函数：初始化默认分支结构
init_structure() {
    local base_name="${1:-clean}"
    local feature_name="${2:-nextline-base}"
    local base_branch="${BASE_PREFIX}/${base_name}"
    local feature_branch="${FEATURE_PREFIX}/${feature_name}"
    
    cd "$REPO_PATH"
    
    echo "=========================================="
    echo "初始化分支结构"
    echo "=========================================="
    echo "仓库: $REPO_PATH"
    echo "上游分支: $UPSTREAM_BRANCH"
    echo "基础分支: $base_branch"
    echo "功能分支: $feature_branch"
    echo ""
    
    # 确保在正确的分支并更新
    echo "1. 更新上游分支: $UPSTREAM_BRANCH"
    
    # 先fetch获取远程最新信息
    git fetch origin 2>/dev/null || echo -e "${YELLOW}  ⚠ 无法连接远程仓库${NC}"
    
    # 检查本地是否已有该分支
    if git rev-parse --verify "$UPSTREAM_BRANCH" >/dev/null 2>&1; then
        # 本地分支已存在，直接checkout并pull
        git checkout "$UPSTREAM_BRANCH"
        git pull origin "$UPSTREAM_BRANCH" 2>/dev/null || echo -e "${YELLOW}  ⚠ 无法拉取远程，使用本地版本${NC}"
    else
        # 本地分支不存在，从远程创建跟踪分支
        echo -e "${YELLOW}  本地分支不存在，从远程创建${NC}"
        git checkout -b "$UPSTREAM_BRANCH" "origin/$UPSTREAM_BRANCH" || {
            echo -e "${RED}  ✗ 无法创建分支，请确认远程分支 origin/$UPSTREAM_BRANCH 存在${NC}"
            exit 1
        }
    fi

    
    # 创建基础分支
    echo ""
    echo "2. 创建基础分支: $base_branch"
    create_or_checkout_branch "$base_branch" "$UPSTREAM_BRANCH"
    
    # 创建功能分支
    echo ""
    echo "3. 创建功能分支: $feature_branch"
    create_or_checkout_branch "$feature_branch" "$base_branch"
    echo -e "${YELLOW}  注意：在此分支添加你的功能代码并提交${NC}"
    
    echo ""
    echo -e "${GREEN}=========================================${NC}"
    echo -e "${GREEN}分支创建完成！${NC}"
    echo -e "${GREEN}=========================================${NC}"
    echo ""
    echo "分支结构:"
    echo "$UPSTREAM_BRANCH"
    echo "    ↓"
    echo "$base_branch"
    echo "    ↓"
    echo "$feature_branch"
    echo ""
    echo "下一步："
    echo "1. git checkout $feature_branch"
    echo "2. 添加并提交你的功能代码"
    echo "3. 使用 --create-versions 创建多个版本分支"
}

# 函数：创建多个版本分支
create_versions() {
    local base_branch=$1
    local num_versions=$2
    
    cd "$REPO_PATH"
    
    # 验证基础分支存在
    if ! git rev-parse --verify "$base_branch" >/dev/null 2>&1; then
        echo -e "${RED}错误: 基础分支 $base_branch 不存在${NC}"
        exit 1
    fi
    
    echo "=========================================="
    echo "创建版本分支"
    echo "=========================================="
    echo "基于: $base_branch"
    echo "数量: $num_versions"
    echo ""
    
    for i in $(seq 1 "$num_versions"); do
        # 从基础分支名提取主要部分，添加版本号
        local version_branch="${base_branch}-v${i}"
        
        echo "$i. 创建 $version_branch"
        create_or_checkout_branch "$version_branch" "$base_branch"
        echo ""
    done
    
    echo -e "${GREEN}=========================================${NC}"
    echo -e "${GREEN}版本分支创建完成！${NC}"
    echo -e "${GREEN}=========================================${NC}"
}

# 函数：列出分支
list_branches() {
    cd "$REPO_PATH"
    
    echo "=========================================="
    echo "分支列表: $REPO_PATH"
    echo "=========================================="
    echo ""
    echo "基础分支 (${BASE_PREFIX}/*):"
    git branch -a | grep "${BASE_PREFIX}/" || echo "  (无)"
    echo ""
    echo "功能分支 (${FEATURE_PREFIX}/*):"
    git branch -a | grep "${FEATURE_PREFIX}/" || echo "  (无)"
    echo ""
    echo "分支图:"
    git log --oneline --graph --all --decorate -20 | head -20 || true
}

# 解析参数
while [[ $# -gt 0 ]]; do
    case $1 in
        --repo)
            REPO_PATH="$2"
            shift 2
            ;;
        --upstream)
            UPSTREAM_BRANCH="$2"
            shift 2
            ;;
        --base-prefix)
            BASE_PREFIX="$2"
            shift 2
            ;;
        --feature-prefix)
            FEATURE_PREFIX="$2"
            shift 2
            ;;
        --init)
            shift
            base_name="${1:-clean}"
            feature_name="${2:-nextline-base}"
            # 如果下一个参数不是选项，则使用它
            if [[ ! "$base_name" =~ ^-- ]]; then
                shift
                if [[ -n "$1" ]] && [[ ! "$1" =~ ^-- ]]; then
                    feature_name="$1"
                    shift
                fi
            else
                base_name="clean"
            fi
            init_structure "$base_name" "$feature_name"
            exit 0
            ;;
        --create-base)
            if [ -z "$2" ]; then
                echo -e "${RED}错误: --create-base 需要指定分支名称${NC}"
                exit 1
            fi
            branch_name="${BASE_PREFIX}/$2"
            echo "创建基础分支: $branch_name"
            create_or_checkout_branch "$branch_name" "$UPSTREAM_BRANCH"
            exit 0
            ;;
        --create-child)
            if [ -z "$2" ]; then
                echo -e "${RED}错误: --create-child 需要指定分支名称${NC}"
                exit 1
            fi
            child_name="$2"
            shift 2
            if [ "$1" != "--base" ] || [ -z "$2" ]; then
                echo -e "${RED}错误: --create-child 需要使用 --base 指定基础分支${NC}"
                exit 1
            fi
            base_name="$2"
            shift 2
            echo "创建子分支: $child_name (基于 $base_name)"
            create_or_checkout_branch "$child_name" "$base_name"
            exit 0
            ;;
        --create-versions)
            if [ -z "$2" ] || [ -z "$3" ]; then
                echo -e "${RED}错误: --create-versions 需要指定基础分支和版本数量${NC}"
                echo "用法: $0 --create-versions <base-branch> <num-versions>"
                exit 1
            fi
            create_versions "$2" "$3"
            shift 3
            exit 0
            ;;
        --list)
            list_branches
            shift
            exit 0
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo -e "${RED}未知选项: $1${NC}"
            usage
            exit 1
            ;;
    esac
done

# 如果没有提供任何操作，显示帮助
usage
