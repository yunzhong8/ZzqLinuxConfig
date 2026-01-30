#!/usr/bin/env zsh
set -euo pipefail

# 这个脚本依次运行两个比较脚本：
# 1) compute_field_diff.py
# 2) compute_out_diff.py
# 请在仓库根目录下运行此脚本，或使用绝对路径运行它
BaseCloseAll=/nfs/home/share/zhengzhongqiang/perf-report-kmhv3/NL/base/cr251231-1a9a2f52c-WithConstainTl2TlCICloseAll/xs-env_v3_NLRebaseCIBase_CloseAll
# BaseV3=/nfs/home/share/zhengzhongqiang/perf-report-kmhv3/NL/base/cr251231-1a9a2f52c-WithConstainTl2TlCIBase/xs-env_v3_NLRebaseCIBase
# BaseV3=/nfs/home/share/zhengzhongqiang/perf-report-kmhv3/NL/feature/xs-env_v3_NLRebaseCI/cr260127-d5005d906--AddOnlyNlDBFixMask
BaseV3=/nfs/home/share/zhengzhongqiang/perf-report-kmhv3/NL/base/cr251231-1a9a2f52c
  
FeatureOnlyNL=/nfs/home/share/zhengzhongqiang/perf-report-kmhv3/NL/feature/xs-env_v3_NLRebaseCI_OnlyNL/cr260120-40a0e6135--OnlyNL
# FeatrueV3AddNL=/nfs/home/share/zhengzhongqiang/perf-report-kmhv3/NL/feature/xs-env_v3_NLRebaseCI_OnlyNL/highBop
FeatrueV3AddNL=/nfs/home/share/zhengzhongqiang/perf-report-kmhv3/NL/feature/xs-env_v3_NLRebaseCI_OnlyNL/cr260128-ea56ecbf2--AddNLAlignGem5HighBop_copy

# 配置要依次运行的 case 列表：格式 "Type|APath|BPath"
cases=(
  "kmhv3_BaseAndFeatureAddNL|$BaseV3|$FeatrueV3AddNL"
  # "kmhv3_BaseAndFeaturenNolyNL|$BaseCloseAll|$FeatureOnlyNL"
  # "kmhv3_BaseAndBase|$BaseCloseAll|$BaseV3"
  # "kmhv3_NLFeatureAndFeature|$FeatureOnlyNL|$FeatrueV3AddNL"
)

perfCountField=/nfs/home/share/zhengzhongqiang/perf-report-kmhv3/scripts/nlField.txt
resultField=/nfs/home/share/zhengzhongqiang/perf-report-kmhv3/scripts/resultField.txt
scoreField=/nfs/home/share/zhengzhongqiang/perf-report-kmhv3/scripts/scoreField.txt

for case in "${cases[@]}"; do
  IFS='|' read -r Type APath BPath <<< "$case"

  perfCountExcelPath="$BPath/$Type/perfCountCompareXlsx"
  perfCountOutExcelPath="$BPath/$Type/ResultCompareXlsx"
  mkdir -p "$perfCountExcelPath" "$perfCountOutExcelPath"

  echo "[1/3] Running compute_field_diff.py for $Type..."
  python3 scripts/compute_field_diff.py \
    --rootA "$APath" \
    --rootB "$BPath" \
    --fields-file "$perfCountField" \
    --occurrence 2 \
    --out-dir "$perfCountExcelPath"

  echo "[2/3] Running compute_out_diff.py for $Type..."
  python3 scripts/compute_out_diff.py \
    --rootA "$APath" \
    --rootB "$BPath" \
    --fields-file "$resultField" \
    --out-dir "$perfCountOutExcelPath"

  # 比较 score.txt 并保存 CSV/XLSX
  scoreCsvPath="$BPath/$Type/compare_score.csv"
  scoreXlsxPath="$BPath/$Type/compare_score.xlsx"
  mkdir -p "$(dirname "$scoreCsvPath")"
  echo "[3/3] Running compare_score.py for $Type..."
  python3 scripts/compare_score.py \
    --rootA "$APath" \
    --rootB "$BPath" \
    --out-csv "$scoreCsvPath" \
    --out-xlsx "$scoreXlsxPath"
done

echo "All done."
