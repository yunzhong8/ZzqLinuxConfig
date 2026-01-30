#!/bin/bash
# 处理未跟踪文件的辅助脚本

set -e

# 颜色
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "=========================================="
echo "未跟踪文件处理助手"
echo "=========================================="
echo ""

# 显示当前未跟踪文件
echo -e "${BLUE}当前未跟踪的文件/目录:${NC}"
echo ""
git ls-files --others --exclude-standard

echo ""
echo "=========================================="
echo "处理建议:"
echo "=========================================="
echo ""

echo -e "${YELLOW}1. NEXTLINE-WORKFLOW.md${NC}"
echo "   - 这是工作流程文档"
echo "   - 建议: ${GREEN}提交到版本控制${NC}（对团队有用）"
echo "   - 或者: 移动到 /nfs/home/zhengzhongqiang/Work/script/ 目录"
echo ""

echo -e "${YELLOW}2. src/main/resources/aia/${NC}"
echo "   - 这看起来是 AIA (Advanced Interrupt Architecture) 子项目"
echo "   - 建议: ${GREEN}添加为子模块${NC}（如果是独立仓库）"
echo "   - 或者: ${GREEN}添加到 .gitignore${NC}（如果是临时生成的）"
echo ""

echo -e "${YELLOW}3. zzqScript/${NC}"
echo "   - 这是旧版本的脚本目录"
echo "   - 建议: ${RED}删除${NC}（已迁移到 /nfs/home/zhengzhongqiang/Work/script/）"
echo "   - 或者: ${GREEN}添加到 .gitignore${NC}"
echo ""

echo "=========================================="
echo "快速操作选项:"
echo "=========================================="
echo ""

while true; do
    echo "请选择操作:"
    echo "  1) 将 NEXTLINE-WORKFLOW.md 添加到版本控制"
    echo "  2) 将 zzqScript/ 添加到 .gitignore"
    echo "  3) 将 src/main/resources/aia/ 添加到 .gitignore"
    echo "  4) 删除 zzqScript/ 目录"
    echo "  5) 显示详细文件列表"
    echo "  6) 全部添加到版本控制（谨慎！）"
    echo "  7) 手动处理，退出脚本"
    echo ""
    read -p "选择 (1-7): " choice
    
    case $choice in
        1)
            echo ""
            echo -e "${GREEN}添加 NEXTLINE-WORKFLOW.md 到版本控制...${NC}"
            git add NEXTLINE-WORKFLOW.md
            echo "已添加到暂存区"
            ;;
        2)
            echo ""
            echo -e "${GREEN}添加 zzqScript/ 到 .gitignore...${NC}"
            echo "" >> .gitignore
            echo "# 本地脚本目录（已迁移到 Work/script）" >> .gitignore
            echo "zzqScript/" >> .gitignore
            echo "已添加到 .gitignore"
            ;;
        3)
            echo ""
            echo -e "${GREEN}添加 src/main/resources/aia/ 到 .gitignore...${NC}"
            echo "" >> .gitignore
            echo "# AIA 临时资源" >> .gitignore
            echo "src/main/resources/aia/" >> .gitignore
            echo "已添加到 .gitignore"
            ;;
        4)
            echo ""
            echo -e "${YELLOW}确认删除 zzqScript/ 目录？ (y/N)${NC}"
            read -p "> " confirm
            if [[ "$confirm" =~ ^[Yy]$ ]]; then
                rm -rf zzqScript/
                echo -e "${GREEN}已删除 zzqScript/${NC}"
            else
                echo "取消删除"
            fi
            ;;
        5)
            echo ""
            echo -e "${BLUE}详细文件列表:${NC}"
            echo ""
            git ls-files --others --exclude-standard | while read file; do
                if [ -d "$file" ]; then
                    echo "  📁 $file/"
                    find "$file" -type f | head -5 | sed 's/^/    ├─ /'
                    count=$(find "$file" -type f | wc -l)
                    if [ "$count" -gt 5 ]; then
                        echo "    └─ ... 还有 $((count - 5)) 个文件"
                    fi
                else
                    echo "  📄 $file"
                fi
            done
            echo ""
            ;;
        6)
            echo ""
            echo -e "${RED}警告: 这将添加所有未跟踪文件到版本控制！${NC}"
            echo -e "${YELLOW}确认？ (y/N)${NC}"
            read -p "> " confirm
            if [[ "$confirm" =~ ^[Yy]$ ]]; then
                git add .
                echo -e "${GREEN}已添加所有文件到暂存区${NC}"
            else
                echo "取消操作"
            fi
            ;;
        7)
            echo ""
            echo "退出脚本"
            exit 0
            ;;
        *)
            echo -e "${RED}无效选择${NC}"
            ;;
    esac
    
    echo ""
    echo "当前状态:"
    git status --short
    echo ""
done
