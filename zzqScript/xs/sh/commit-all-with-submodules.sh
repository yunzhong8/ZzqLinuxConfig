#!/bin/bash
# 提交主仓库和所有子模块到指定分支

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
用法: $0 <分支名> [提交信息]

将主仓库和所有有修改的子模块提交到指定分支

参数:
    分支名         要创建/切换的分支名
    提交信息       可选，默认为 "feat: update to <分支名>"

示例:
    $0 feature/nextline-base
    $0 feature/nextline-v1 "add nextline prefetcher v1"
    
工作流程:
    1. 检查主仓库和子模块的修改
    2. 在主仓库创建/切换到指定分支
    3. 在有修改的子模块中创建同名分支并提交
    4. 在主仓库提交所有修改（包括子模块引用更新）

EOF
}

# 检查参数
if [ $# -lt 1 ]; then
    usage
    exit 1
fi

BRANCH_NAME=$1
COMMIT_MSG=${2:-"feat: update to $BRANCH_NAME"}

echo "=========================================="
echo "提交到分支: $BRANCH_NAME"
echo "提交信息: $COMMIT_MSG"
echo "=========================================="
echo ""

# 1. 处理子模块
echo -e "${BLUE}→${NC} 检查子模块修改..."
echo ""

git submodule foreach "
    if git diff-index --quiet HEAD -- 2>/dev/null && [ -z \"\$(git ls-files --others --exclude-standard)\" ]; then
        echo -e \"  ${GREEN}✓${NC} \$name - 无修改，跳过\"
    else
        echo -e \"  ${YELLOW}→${NC} \$name - 检测到修改\"
        
        # 创建或切换分支
        if git rev-parse --verify '$BRANCH_NAME' >/dev/null 2>&1; then
            echo \"    切换到已存在分支: $BRANCH_NAME\"
            git checkout '$BRANCH_NAME'
        else
            echo \"    创建新分支: $BRANCH_NAME\"
            current_commit=\$(git rev-parse HEAD)
            git checkout -b '$BRANCH_NAME' \$current_commit
        fi
        
        # 添加并提交修改
        git add -A
        if git diff --cached --quiet; then
            echo -e \"    ${YELLOW}⚠${NC} 无暂存修改\"
        else
            git commit -m '$COMMIT_MSG'
            echo -e \"    ${GREEN}✓${NC} 已提交修改\"
        fi
    fi
"

echo ""

# 2. 处理主仓库
echo -e "${BLUE}→${NC} 处理主仓库..."
echo ""

# 创建或切换主仓库分支
if git rev-parse --verify "$BRANCH_NAME" >/dev/null 2>&1; then
    echo -e "  ${YELLOW}⚠${NC} 分支 $BRANCH_NAME 已存在，切换到该分支"
    git checkout "$BRANCH_NAME"
else
    echo -e "  ${GREEN}✓${NC} 创建新分支: $BRANCH_NAME"
    git checkout -b "$BRANCH_NAME"
fi

# 添加所有修改（包括子模块引用）
echo ""
echo "添加修改文件..."
git add -A

# 提交
if git diff --cached --quiet; then
    echo -e "${YELLOW}⚠ 主仓库无修改需要提交${NC}"
else
    git commit -m "$COMMIT_MSG"
    echo -e "${GREEN}✓ 主仓库修改已提交${NC}"
fi

echo ""
echo -e "${GREEN}=========================================${NC}"
echo -e "${GREEN}完成！${NC}"
echo -e "${GREEN}=========================================${NC}"
echo ""
echo "当前状态:"
git status
echo ""
echo "子模块状态:"
git submodule foreach 'echo "  $name: $(git branch --show-current || echo detached HEAD)"'
