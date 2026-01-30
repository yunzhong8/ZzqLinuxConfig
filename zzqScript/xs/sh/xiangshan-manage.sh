#!/bin/bash
# XiangShan 项目专用包装脚本

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_REPO="/nfs/home/zhengzhongqiang/Work/xs-env_v3/XiangShan"

# 显示用法
usage() {
    cat <<EOF
XiangShan NextLine 多版本管理工具

用法: $0 <操作> [选项]

操作:
    init-branches [REPO]    初始化分支结构
    init-worktrees [REPO]   初始化工作目录
    list-branches [REPO]    列出所有分支
    list-worktrees [REPO]   列出所有工作目录
    
    create-version N [REPO] 创建新版本 vN
    remove-worktree NAME [REPO] 删除工作目录

示例:
    # 使用默认仓库 (xs-env_v3)
    $0 init-branches
    $0 init-worktrees
    
    # 使用自定义仓库
    $0 init-branches /path/to/another/XiangShan
    
    # 创建新版本 v4
    $0 create-version 4
    
    # 删除工作目录
    $0 remove-worktree nl-v3

环境变量:
    XIANGSHAN_REPO    XiangShan 仓库路径 (默认: $DEFAULT_REPO)

EOF
}

# 获取仓库路径
# 优先级: 命令行参数 > 环境变量 XIANGSHAN_REPO > 默认路径 DEFAULT_REPO
# 这个仓库路径就是XiangShan的绝对路径
get_repo_path() {
    local repo="${1:-${XIANGSHAN_REPO:-$DEFAULT_REPO}}"
    echo "$repo"
}

# 主逻辑
case "${1:-help}" in
    init-branches)
        repo=$(get_repo_path "$2")
        echo "初始化分支结构: $repo"
        "$SCRIPT_DIR/setup-branches.sh" \
            --repo "$repo" \
            --upstream kunminghu-v3 \
            --init clean nextline-base
        ;;

    init-from-existing)
        if [ -z "$2" ]; then
            echo "错误: 需要指定当前分支作为功能分支的名称"
            echo "用法: $0 init-from-existing <feature-name> [REPO]"
            exit 1
        fi
        feature_name="$2"
        repo=$(get_repo_path "$3")
        
        echo "从现有仓库初始化: $repo"
        echo "当前工作将保存为: feature/$feature_name"
        echo ""
        
        cd "$repo"
        
        # 1. 检查当前状态
        current_branch=$(git rev-parse --abbrev-ref HEAD)
        echo "当前分支: $current_branch"
        
        # 2. 检查子模块状态
        echo ""
        echo "检查子模块状态..."
        has_submodule_changes=false
        
        # 检查是否有子模块
        if [ -f .gitmodules ]; then
            # 更新子模块状态
            git submodule update --init --recursive 2>/dev/null || true
            
            # 检查每个子模块是否有修改
            git submodule foreach --quiet --recursive '
                if ! git diff-index --quiet HEAD -- 2>/dev/null; then
                    echo "  ⚠ 子模块 $name 有未提交的修改"
                    exit 1
                fi
            ' && submodule_clean=true || has_submodule_changes=true
            
            if [ "$has_submodule_changes" = true ]; then
                echo -e "\033[1;33m⚠ 检测到子模块有未提交的修改\033[0m"
                echo ""
                echo "选项："
                echo "  1) 提交所有子模块的修改"
                echo "  2) 暂存(stash)所有子模块的修改"
                echo "  3) 放弃所有子模块的修改"
                echo "  4) 退出，手动处理"
                read -p "请选择 (1-4): " submodule_choice
                
                case "$submodule_choice" in
                    1)
                        echo "提交子模块修改..."
                        git submodule foreach --recursive '
                            if ! git diff-index --quiet HEAD -- 2>/dev/null; then
                                git add .
                                git commit -m "自动提交: 保存 $name 的修改"
                            fi
                        '
                        # 更新主仓库的子模块指针
                        git add .gitmodules $(git submodule status | awk "{print \$2}")
                        ;;
                    2)
                        echo "暂存子模块修改..."
                        git submodule foreach --recursive 'git stash push -m "自动暂存: 准备初始化分支"'
                        ;;
                    3)
                        echo "放弃子模块修改..."
                        git submodule foreach --recursive 'git checkout -- .'
                        git submodule update --recursive
                        ;;
                    4)
                        echo "退出。请手动处理子模块修改后重新运行"
                        exit 1
                        ;;
                    *)
                        echo "无效选择，退出"
                        exit 1
                        ;;
                esac
            else
                echo -e "\033[0;32m  ✓ 所有子模块都是干净的\033[0m"
            fi
        fi
        
        # 3. 检查主仓库是否有未提交的修改
        echo ""
        if ! git diff-index --quiet HEAD --; then
            echo -e "\033[1;33m⚠ 检测到主仓库有未提交的修改\033[0m"
            read -p "是否要提交这些修改? (y/n): " commit_changes
            if [ "$commit_changes" = "y" ]; then
                git add .
                read -p "输入提交信息: " commit_msg
                git commit -m "$commit_msg"
            else
                echo "请先处理未提交的修改，然后重新运行此命令"
                exit 1
            fi
        fi
        
        # 4. 将当前分支重命名为功能分支
        echo ""
        echo "步骤 1/3: 重命名当前分支为 feature/$feature_name"
        if [ "$current_branch" != "feature/$feature_name" ]; then
            git branch -m "$current_branch" "feature/$feature_name" 2>/dev/null || \
                git branch -M "$current_branch" "feature/$feature_name"
        fi
        
        # 5. 创建 base/clean 分支（从上游）
        echo ""
        echo "步骤 2/3: 创建 base/clean 分支（从上游 kunminghu-v3）"
        
        # 先 fetch 获取远程最新信息
        git fetch origin 2>/dev/null || echo -e "\033[1;33m  ⚠ 无法连接远程仓库\033[0m"
        
        # 检查本地是否已有 kunminghu-v3
        if git rev-parse --verify kunminghu-v3 >/dev/null 2>&1; then
            git checkout kunminghu-v3
            git pull origin kunminghu-v3 2>/dev/null || echo -e "\033[1;33m  ⚠ 无法拉取远程，使用本地版本\033[0m"
        else
            echo "  从远程创建 kunminghu-v3 跟踪分支"
            git checkout -b kunminghu-v3 origin/kunminghu-v3 || {
                echo -e "\033[0;31m  ✗ 无法创建分支，请确认远程分支 origin/kunminghu-v3 存在\033[0m"
                exit 1
            }
        fi
        
        # 更新子模块到上游版本
        echo "  更新子模块到上游版本..."
        git submodule update --init --recursive
        
        # 创建 base/clean
        if git rev-parse --verify base/clean >/dev/null 2>&1; then
            echo -e "\033[1;33m  ⚠ base/clean 已存在，跳过创建\033[0m"
        else
            git checkout -b base/clean kunminghu-v3
            echo -e "\033[0;32m  ✓ 创建 base/clean 分支\033[0m"
        fi
        
        # 6. 切换回功能分支
        echo ""
        echo "步骤 3/3: 切换回功能分支"
        git checkout "feature/$feature_name"
        
        # 恢复子模块到功能分支的状态
        git submodule update --recursive
        
        # 7. 显示结果
        echo ""
        echo "=========================================="
        echo "初始化完成！"
        echo "=========================================="
        echo "分支结构："
        echo "  kunminghu-v3 (上游跟踪分支)"
        echo "  base/clean (干净的上游快照)"
        echo "  feature/$feature_name (你的功能分支，当前所在)"
        echo ""
        echo "子模块状态："
        git submodule status
        echo ""
        echo "后续操作："
        echo "  # 创建子版本分支"
        echo "  $0 create-version 1"
        echo ""
        echo "  # 或手动创建子分支"
        echo "  cd $repo"
        echo "  git checkout -b feature/my-new-feature feature/$feature_name"
        ;;
    
    init-worktrees)
        repo=$(get_repo_path "$2")
        config="$SCRIPT_DIR/xiangshan-config.sh"
        echo "初始化工作目录: $repo"
        echo "配置文件: $config"
        "$SCRIPT_DIR/setup-worktrees.sh" \
            --repo "$repo" \
            --env-prefix "xs-env" \
            --init "$config"
        ;;
    
    list-branches)
        repo=$(get_repo_path "$2")
        "$SCRIPT_DIR/setup-branches.sh" \
            --repo "$repo" \
            --list
        ;;
    
    list-worktrees)
        repo=$(get_repo_path "$2")
        "$SCRIPT_DIR/setup-worktrees.sh" \
            --repo "$repo" \
            --env-prefix "xs-env" \
            --list
        ;;
    
    create-version)
        if [ -z "$2" ]; then
            echo "错误: 需要指定版本号"
            echo "用法: $0 create-version <N> [REPO]"
            exit 1
        fi
        version_num="$2"
        repo=$(get_repo_path "$3")
        
        # 创建分支
        echo "创建 feature/nextline-v${version_num} 分支"
        "$SCRIPT_DIR/setup-branches.sh" \
            --repo "$repo" \
            --create-child "feature/nextline-v${version_num}" \
            --base "feature/nextline-base"
        
        # 创建工作目录
        echo ""
        echo "创建工作目录: xs-env_nl-v${version_num}"
        "$SCRIPT_DIR/setup-worktrees.sh" \
            --repo "$repo" \
            --env-prefix "xs-env" \
            --shared-dirs "DRAMsim3 NEMU NutShell nexus-am" \
            --create "nl-v${version_num}" "feature/nextline-v${version_num}"
        ;;
    
    remove-worktree)
        if [ -z "$2" ]; then
            echo "错误: 需要指定环境名"
            echo "用法: $0 remove-worktree <name> [REPO]"
            exit 1
        fi
        env_name="$2"
        repo=$(get_repo_path "$3")
        
        "$SCRIPT_DIR/setup-worktrees.sh" \
            --repo "$repo" \
            --env-prefix "xs-env" \
            --remove "$env_name"
        ;;
    
    help|-h|--help)
        usage
        ;;
    
    *)
        echo "未知操作: $1"
        echo ""
        usage
        exit 1
        ;;
esac
