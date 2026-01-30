#!/bin/bash
# 通用的 Git Worktree 管理脚本
set -e

# 颜色
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 默认配置
REPO_PATH="${REPO_PATH:-$(pwd)}"
WORK_BASE_DIR="${WORK_BASE_DIR:-$(dirname "$REPO_PATH")}"
ENV_PREFIX="${ENV_PREFIX:-env}"

# 显示用法
usage() {
    cat <<EOF
用法: $0 [选项] <操作>

全局选项:
    --repo PATH             仓库路径 (默认: 当前目录)
    --work-dir PATH         工作目录基础路径 (默认: 仓库的父目录)
    --env-prefix PREFIX     环境目录前缀 (默认: env)
    --shared-dirs "DIR1 DIR2..."  需要共享的目录（软链接）

操作:
    --init CONFIG_FILE
        根据配置文件初始化所有工作目录
        
    --create ENV_NAME BRANCH [SHARED_DIRS]
        创建单个工作目录
        
    --remove ENV_NAME
        删除指定工作目录
        
    --list
        列出所有工作目录
        
    -h, --help
        显示此帮助信息

配置文件格式 (JSON):
{
  "environments": [
    {"name": "baseline", "branch": "base/clean"},
    {"name": "nl-v1", "branch": "feature/nextline-v1"}
  ],
  "shared_dirs": ["DRAMsim3", "NEMU"],
  "copy_files": ["env.sh", "Dockerfile"]
}

示例:
    # 创建单个工作目录
    $0 --repo /path/to/repo --create myenv feature/branch
    
    # 使用配置文件初始化
    $0 --repo /path/to/repo --init config.json
    
    # 删除工作目录
    $0 --repo /path/to/repo --remove myenv
    
    # 列出所有工作目录
    $0 --repo /path/to/repo --list

环境变量:
    REPO_PATH           仓库路径
    WORK_BASE_DIR       工作目录基础路径
    ENV_PREFIX          环境目录前缀
    SHARED_DIRS         共享目录列表（空格分隔）
    COPY_FILES          需要复制的文件列表（空格分隔）

EOF
}

# 函数：获取仓库根目录名
get_repo_name() {
    basename "$REPO_PATH"
}

# 函数：创建完整的环境目录结构
create_env_worktree() {
    local env_name=$1
    local branch=$2
    shift 2
    local shared_dirs=("$@")
    
    local repo_name=$(get_repo_name)
    local env_dir="$WORK_BASE_DIR/${ENV_PREFIX}_${env_name}"
    
    echo -e "${BLUE}→${NC} 创建 ${YELLOW}${env_name}${NC} 工作环境 (分支: ${branch})"
    
    # 检查目录是否已存在
    if [ -d "$env_dir" ]; then
        echo -e "  ${YELLOW}⚠${NC} ${env_dir} 已存在，跳过"
        return 1
    fi
    
    # 切换到仓库
    cd "$REPO_PATH"
    
    # 检查分支是否存在
    if ! git rev-parse --verify "$branch" >/dev/null 2>&1; then
        echo -e "  ${RED}✗${NC} 分支 $branch 不存在"
        return 1
    fi
    
    # 创建环境根目录
    mkdir -p "$env_dir"
    
    # 在环境目录下创建仓库 worktree
    git worktree add "$env_dir/$repo_name" "$branch"
    echo -e "  ${GREEN}✓${NC} 创建 worktree: $env_dir/$repo_name"
    
    # 复制配置文件
    if [ -n "$COPY_FILES" ]; then
        echo -e "  ${BLUE}→${NC} 复制配置文件"
        for file in $COPY_FILES; do
            local src="$(dirname "$REPO_PATH")/$file"
            if [ -f "$src" ]; then
                cp "$src" "$env_dir/"
                echo -e "    ${GREEN}✓${NC} $file"
            fi
        done
    fi
    
    # 创建共享目录软链接
    if [ ${#shared_dirs[@]} -gt 0 ] || [ -n "$SHARED_DIRS" ]; then
        echo -e "  ${BLUE}→${NC} 创建共享资源软链接"
        
        # 合并参数和环境变量中的共享目录
        local all_dirs=("${shared_dirs[@]}")
        if [ -n "$SHARED_DIRS" ]; then
            IFS=' ' read -ra env_dirs <<< "$SHARED_DIRS"
            all_dirs+=("${env_dirs[@]}")
        fi
        
        for dir in "${all_dirs[@]}"; do
            local src="$(dirname "$REPO_PATH")/$dir"
            if [ -d "$src" ]; then
                ln -s "$src" "$env_dir/$dir"
                echo -e "    ${GREEN}✓${NC} $dir -> $(basename "$(dirname "$REPO_PATH")")/$dir"
            fi
        done
    fi
    
    echo -e "  ${GREEN}✓${NC} 已创建: $env_dir"
    return 0
}

# 函数：删除工作目录
remove_env_worktree() {
    local env_name=$1
    local repo_name=$(get_repo_name)
    local env_dir="$WORK_BASE_DIR/${ENV_PREFIX}_${env_name}"
    
    echo -e "${BLUE}→${NC} 删除 ${YELLOW}${env_name}${NC} 工作环境"
    
    if [ ! -d "$env_dir" ]; then
        echo -e "  ${YELLOW}⚠${NC} ${env_dir} 不存在"
        return 1
    fi
    
    # 删除 git worktree
    if [ -d "$env_dir/$repo_name" ]; then
        cd "$REPO_PATH"
        git worktree remove "$env_dir/$repo_name" --force
        echo -e "  ${GREEN}✓${NC} 已删除 worktree"
    fi
    
    # 删除目录
    rm -rf "$env_dir"
    echo -e "  ${GREEN}✓${NC} 已删除目录: $env_dir"
    
    return 0
}

# 函数：列出所有工作目录
list_worktrees() {
    echo "=========================================="
    echo "仓库: $REPO_PATH"
    echo "工作目录基础: $WORK_BASE_DIR"
    echo "=========================================="
    echo ""
    echo "Git Worktree 列表:"
    cd "$REPO_PATH"
    git worktree list
    
    echo ""
    echo "环境目录:"
    for env in "$WORK_BASE_DIR"/${ENV_PREFIX}_*; do
        if [ -d "$env" ]; then
            local env_name=$(basename "$env" | sed "s/^${ENV_PREFIX}_//")
            echo "  - $env_name: $env"
            
            local repo_name=$(get_repo_name)
            if [ -d "$env/$repo_name" ]; then
                cd "$env/$repo_name"
                echo "    分支: $(git branch --show-current)"
            fi
        fi
    done
}

# 函数：从配置文件初始化（不依赖 jq）
init_from_config() {
    local config_file=$1
    
    if [ ! -f "$config_file" ]; then
        echo -e "${RED}错误: 配置文件不存在: $config_file${NC}"
        exit 1
    fi
    
    echo "=========================================="
    echo "从配置文件初始化工作目录"
    echo "=========================================="
    echo "配置文件: $config_file"
    echo ""
    
    # 使用简单的 shell 脚本格式配置文件
    # 检查文件格式（.sh 或 .json）
    if [[ "$config_file" == *.json ]]; then
        echo -e "${YELLOW}警告: JSON 配置文件需要 jq 工具${NC}"
        echo -e "${YELLOW}请将配置转换为 .sh 格式或手动创建工作目录${NC}"
        echo ""
        echo "示例 .sh 配置文件格式:"
        echo "----------------------------------------"
        echo "# 环境配置"
        echo "ENVS=("
        echo "    \"baseline:base/clean\""
        echo "    \"nl-v1:feature/nextline-v1\""
        echo ")"
        echo ""
        echo "# 共享目录"
        echo "SHARED_DIRS=(\"DRAMsim3\" \"NEMU\")"
        echo ""
        echo "# 复制文件"
        echo "COPY_FILES=(\"env.sh\" \"Dockerfile\")"
        echo "----------------------------------------"
        exit 1
    fi
    
    # Source 配置文件
    source "$config_file"
    
    # 设置环境变量
    if [ ${#SHARED_DIRS[@]} -gt 0 ]; then
        export SHARED_DIRS="${SHARED_DIRS[*]}"
    fi
    if [ ${#COPY_FILES[@]} -gt 0 ]; then
        export COPY_FILES="${COPY_FILES[*]}"
    fi
    
    # 创建工作目录
    local count=0
    for env_config in "${ENVS[@]}"; do
        IFS=':' read -r name branch <<< "$env_config"
        
        echo ""
        echo "$((++count)). $name ($branch)"
        create_env_worktree "$name" "$branch" "${SHARED_DIRS[@]}" || true
    done
    
    echo ""
    echo -e "${GREEN}=========================================${NC}"
    echo -e "${GREEN}工作目录创建完成！${NC}"
    echo -e "${GREEN}=========================================${NC}"
    echo ""
    
    list_worktrees
}

# 解析参数
while [[ $# -gt 0 ]]; do
    case $1 in
        --repo)
            REPO_PATH="$2"
            shift 2
            ;;
        --work-dir)
            WORK_BASE_DIR="$2"
            shift 2
            ;;
        --env-prefix)
            ENV_PREFIX="$2"
            shift 2
            ;;
        --shared-dirs)
            SHARED_DIRS="$2"
            shift 2
            ;;
        --init)
            if [ -z "$2" ]; then
                echo -e "${RED}错误: --init 需要指定配置文件${NC}"
                exit 1
            fi
            init_from_config "$2"
            shift 2
            exit 0
            ;;
        --create)
            if [ -z "$2" ] || [ -z "$3" ]; then
                echo -e "${RED}错误: --create 需要指定环境名和分支名${NC}"
                exit 1
            fi
            create_env_worktree "$2" "$3"
            shift 3
            exit 0
            ;;
        --remove)
            if [ -z "$2" ]; then
                echo -e "${RED}错误: --remove 需要指定环境名${NC}"
                exit 1
            fi
            remove_env_worktree "$2"
            shift 2
            exit 0
            ;;
        --list)
            list_worktrees
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
