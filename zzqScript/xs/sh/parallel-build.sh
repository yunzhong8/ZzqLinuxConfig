#!/bin/bash
# 并行编译多个 XiangShan 配置
# 用法: ./parallel-build.sh [配置1] [配置2] ...
# 示例: ./parallel-build.sh KunminghuV2Config KunminghuV2WithNLConfig KunminghuV2MinimalConfig

set -e

NOOP_HOME=$(pwd)
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
LOG_DIR="$NOOP_HOME/build-logs"
mkdir -p "$LOG_DIR"

# 默认配置列表（如果没有指定参数）
DEFAULT_CONFIGS=(
    "KunminghuV2Config"
    "KunminghuV2WithNLConfig"
    "KunminghuV2MinimalConfig"
)

# 使用命令行参数或默认配置
if [ $# -eq 0 ]; then
    CONFIGS=("${DEFAULT_CONFIGS[@]}")
else
    CONFIGS=("$@")
fi

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}开始并行编译 ${#CONFIGS[@]} 个配置${NC}"
echo -e "${BLUE}========================================${NC}"
for cfg in "${CONFIGS[@]}"; do
    echo -e "  - ${YELLOW}$cfg${NC}"
done
echo ""

# 存储后台进程 PID 和配置名称
declare -A BUILD_PIDS
declare -A BUILD_LOGS

# 编译单个配置的函数
build_config() {
    local config=$1
    local log_file="$LOG_DIR/build-${config}-$(date +%Y%m%d-%H%M%S).log"
    
    echo -e "${BLUE}[$(date '+%H:%M:%S')]${NC} 开始编译: ${YELLOW}${config}${NC}"
    echo "日志文件: $log_file"
    
    # 使用 python3 xiangshan.py 进行编译
    cd "$NOOP_HOME"
    python3 "$NOOP_HOME/scripts/xiangshan.py" --build \
        --dramsim3 "$DRAMSIM3_HOME" --with-dramsim3 \
        --threads 8 --trace-fst \
        --config "$config" \
        > "$log_file" 2>&1
    
    local exit_code=$?
    
    if [ $exit_code -eq 0 ]; then
        echo -e "${GREEN}✓ [$(date '+%H:%M:%S')] 编译成功: ${config}${NC}"
        # 重命名 emu 文件以区分不同配置
        if [ -f "$NOOP_HOME/build/emu" ]; then
            mv "$NOOP_HOME/build/emu" "$NOOP_HOME/build/emu-${config}"
            echo -e "  → 可执行文件: build/emu-${config}"
        fi
    else
        echo -e "${RED}✗ [$(date '+%H:%M:%S')] 编译失败: ${config} (退出码: $exit_code)${NC}"
        echo -e "  → 查看日志: $log_file"
    fi
    
    return $exit_code
}

# 启动所有编译任务（后台并行）
for config in "${CONFIGS[@]}"; do
    log_file="$LOG_DIR/build-${config}-$(date +%Y%m%d-%H%M%S).log"
    BUILD_LOGS[$config]=$log_file
    
    # 在后台启动编译
    build_config "$config" &
    pid=$!
    BUILD_PIDS[$config]=$pid
    
    echo -e "${BLUE}[PID $pid]${NC} 后台启动: ${YELLOW}${config}${NC}"
    
    # 短暂延迟避免同时启动导致资源竞争
    sleep 2
done

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}所有编译任务已启动，等待完成...${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# 等待所有编译任务完成并收集结果
declare -A BUILD_RESULTS
success_count=0
fail_count=0

for config in "${CONFIGS[@]}"; do
    pid=${BUILD_PIDS[$config]}
    log_file=${BUILD_LOGS[$config]}
    
    # 等待特定 PID
    wait $pid
    exit_code=$?
    
    BUILD_RESULTS[$config]=$exit_code
    
    if [ $exit_code -eq 0 ]; then
        ((success_count++))
    else
        ((fail_count++))
    fi
done

# 打印最终报告
echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}编译完成汇总${NC}"
echo -e "${BLUE}========================================${NC}"
echo -e "成功: ${GREEN}${success_count}${NC} / 失败: ${RED}${fail_count}${NC} / 总计: ${#CONFIGS[@]}"
echo ""

for config in "${CONFIGS[@]}"; do
    exit_code=${BUILD_RESULTS[$config]}
    log_file=${BUILD_LOGS[$config]}
    
    if [ $exit_code -eq 0 ]; then
        echo -e "${GREEN}✓${NC} ${config}"
        echo -e "    可执行文件: build/emu-${config}"
    else
        echo -e "${RED}✗${NC} ${config} (退出码: $exit_code)"
        echo -e "    日志文件: $log_file"
    fi
done

echo ""
echo -e "${BLUE}所有日志保存在: $LOG_DIR${NC}"

# 返回失败数量作为退出码
exit $fail_count
