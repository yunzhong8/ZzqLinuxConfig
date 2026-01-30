#!/bin/bash
# 为 worktree 初始化独立的子模块

set -e

# 颜色
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 显示用法
usage() {
    cat <<EOF
用法: $0 <worktree-path>

为指定的 git worktree 初始化独立的子模块，避免与主仓库共享

参数:
    worktree-path    worktree 的路径（例如：/path/to/xs-env_baseline/XiangShan）

示例:
    $0 /nfs/home/zhengzhongqiang/Work/xs-env_baseline/XiangShan
    $0 /nfs/home/zhengzhongqiang/Work/xs-env_nextline/XiangShan

说明:
    Git worktree 默认会共享主仓库的 .git/modules，导致子模块冲突。
    此脚本会为 worktree 创建独立的子模块副本。

EOF
}

if [ $# -lt 1 ]; then
    usage
    exit 1
fi

WORKTREE_PATH=$(realpath "$1")

if [ ! -d "$WORKTREE_PATH" ]; then
    echo -e "${RED}错误: 目录不存在: $WORKTREE_PATH${NC}"
    exit 1
fi

if [ ! -f "$WORKTREE_PATH/.git" ]; then
    echo -e "${RED}错误: 不是 git worktree: $WORKTREE_PATH${NC}"
    exit 1
fi

echo "=========================================="
echo "初始化 worktree 独立子模块"
echo "=========================================="
echo "Worktree: $WORKTREE_PATH"
echo ""

cd "$WORKTREE_PATH"

# 读取 .git 文件获取主仓库路径
MAIN_GIT_DIR=$(cat .git | sed 's/gitdir: //')
MAIN_REPO=$(dirname "$(dirname "$MAIN_GIT_DIR")")

echo "主仓库: $MAIN_REPO"
echo ""

# 获取所有子模块
SUBMODULES=$(git config --file .gitmodules --get-regexp path | awk '{ print $2 }')

if [ -z "$SUBMODULES" ]; then
    echo -e "${YELLOW}没有找到子模块${NC}"
    exit 0
fi

echo -e "${BLUE}→ 找到的子模块:${NC}"
echo "$SUBMODULES" | sed 's/^/  - /'
echo ""

for submodule in $SUBMODULES; do
    echo -e "${BLUE}→ 处理子模块: $submodule${NC}"
    
    # 获取子模块应该指向的 commit
    COMMIT=$(git ls-tree HEAD "$submodule" | awk '{print $3}')
    
    if [ -z "$COMMIT" ]; then
        echo -e "  ${YELLOW}⚠ 跳过（主仓库未记录）${NC}"
        continue
    fi
    
    # 移除现有的子模块目录（如果是符号链接或共享的）
    if [ -e "$submodule" ]; then
        echo "  移除现有目录..."
        rm -rf "$submodule"
    fi
    
    # 获取子模块 URL
    URL=$(git config --file .gitmodules --get "submodule.$submodule.url")
    
    # 检查主仓库是否已经有这个子模块
    MAIN_SUBMODULE_PATH="$MAIN_REPO/$submodule"
    
    if [ -d "$MAIN_SUBMODULE_PATH/.git" ]; then
        echo "  从主仓库复制子模块..."
        # 复制整个子模块目录
        cp -r "$MAIN_SUBMODULE_PATH" "$submodule"
        
        # 切换到记录的 commit
        (
            cd "$submodule"
            git checkout "$COMMIT" 2>/dev/null || git checkout -b "detached-$COMMIT" "$COMMIT"
        )
        echo -e "  ${GREEN}✓${NC} 已复制并签出到 $COMMIT"
    else
        echo "  克隆子模块..."
        git clone "$URL" "$submodule"
        
        (
            cd "$submodule"
            git checkout "$COMMIT" 2>/dev/null || git checkout -b "detached-$COMMIT" "$COMMIT"
            
            # 递归初始化子模块的子模块
            if [ -f .gitmodules ]; then
                git submodule update --init --recursive
            fi
        )
        echo -e "  ${GREEN}✓${NC} 已克隆并签出到 $COMMIT"
    fi
    
    echo ""
done

echo -e "${GREEN}=========================================${NC}"
echo -e "${GREEN}完成！${NC}"
echo -e "${GREEN}=========================================${NC}"
echo ""
echo "子模块状态:"
git submodule status
echo ""
echo -e "${YELLOW}注意:${NC}"
echo "- 这些子模块是独立的副本，不会影响主仓库"
echo "- 运行 'make init' 不会改变这些子模块的版本"
echo "- 如果需要更新子模块，请手动操作"
