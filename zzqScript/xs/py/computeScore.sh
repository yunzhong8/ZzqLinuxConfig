CHECKPOINT="/nfs/home/share/lianyqin/spec06_rv64gcb_O3_20m_gcc12.2.0-intFpcOff-jeMalloc/checkpoint-0-0-0"
# CLUSTER_JSON="/nfs/home/zhengzhongqiang/Work/script/mcf_gcc12o3-incFpcOff-jeMalloc-0.3.json"
CLUSTER_JSON="/nfs/home/zhengzhongqiang/Work/script/gcc12o3-incFpcOff-jeMalloc-0.3.json"
XS="/nfs/home/zhengzhongqiang/WorkNL/xs-env_v3_NLRebaseCI_OnlyNL/XiangShan"
THREADS=8
# OUTDIR="/nfs/home/share/zhengzhongqiang/perf-report-kmhv3/NL/feature/xs-env_v3_NLRebaseCI_OnlyNL/highBop"
# OUTDIR="/nfs/home/share/zhengzhongqiang/perf-report-kmhv3/NL/feature/xs-env_v3_NLRebaseCI_OnlyNL/cr260128-ea56ecbf2--AddNLAlignGem5HighBop_copy"
OUTDIR="/nfs/home/share/zhengzhongqiang/perf-report-kmhv3/NL/base/cr251231-1a9a2f52c"

mkdir -p "$OUTDIR" && python3 /nfs/home/share/liyanqin/env-scripts/perf/xs_autorun_multiServer.py "$CHECKPOINT" "$CLUSTER_JSON" --xs "$XS" --threads "$THREADS" --dir "$OUTDIR" --report > "$OUTDIR/score.txt" 2>&1