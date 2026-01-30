#!/bin/bash
# 切换分支时同步切换所有子模块到同名分支

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
用法: $0 <分支名>

切换主仓库和所有子模块到指定分支

参数:
    分支名    要切换的分支名

示例:
    $0 feature/nextline-base
    $0 base/clean
    
注意:
    - 如果子模块中不存在同名分支，将保持在当前位置
    - 可以用 --create 选项在子模块中创建不存在的分支

EOF
}

# 检查参数
if [ $# -lt 1 ]; then
    usage
    exit 1
fi

BRANCH_NAME=$1
CREATE_MISSING=false

if [ "$2" = "--create" ]; then
    CREATE_MISSING=true
fi

echo "=========================================="
echo "切换到分支: $BRANCH_NAME"
echo "=========================================="
echo ""

# 1. 切换主仓库
echo -e "${BLUE}→${NC} 切换主仓库..."
if ! git checkout "$BRANCH_NAME"; then
    echo -e "${RED}错误: 主仓库分支 $BRANCH_NAME 不存在${NC}"
    exit 1
fi
echo -e "${GREEN}✓${NC} 主仓库已切换到 $BRANCH_NAME"
echo ""

# 2. 切换子模块
echo -e "${BLUE}→${NC} 切换子模块..."
echo ""

git submodule foreach "
    if git rev-parse --verify '$BRANCH_NAME' >/dev/null 2>&1; then
        git checkout '$BRANCH_NAME'
        echo -e \"  ${GREEN}✓${NC} \$name -> $BRANCH_NAME\"
    elif [ '$CREATE_MISSING' = 'true' ]; then
        current_commit=\$(git rev-parse HEAD)
        git checkout -b '$BRANCH_NAME' \$current_commit
        echo -e \"  ${GREEN}✓${NC} \$name -> $BRANCH_NAME (新建)\"
    else
        echo -e \"  ${YELLOW}⚠${NC} \$name - 分支 $BRANCH_NAME 不存在，保持当前状态\"
    fi
"

echo ""
echo -e "${GREEN}=========================================${NC}"
echo -e "${GREEN}完成！${NC}"
echo -e "${GREEN}=========================================${NC}"
echo ""
echo "子模块当前分支:"
git submodule foreach 'current=$(git branch --show-current); if [ -z "$current" ]; then echo "  $name: (detached HEAD)"; else echo "  $name: $current"; fi'
