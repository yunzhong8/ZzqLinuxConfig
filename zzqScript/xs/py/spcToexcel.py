import re
import os
import time
from openpyxl import Workbook
from openpyxl.styles import Font, Alignment

# ===================== 核心配置（仅需修改这里）=====================
# 你的SPEC2006数据文本文件【绝对路径/相对路径】（必填！）
DATA_FILE_PATH = "/nfs/home/share/zhengzhongqiang/perf-report-kmhv3/NL/base/cr251231-1a9a2f52c/score.txt"
# DATA_FILE_PATH = "/nfs/home/share/zhengzhongqiang/perf-report-kmhv3/NL/feature/xs-env_v3_NLRebaseCI_OnlyNL/cr260128-ea56ecbf2--AddNLAlignGem5HighBop_copy/score.txt"
# Excel输出路径（默认和脚本同目录，也可改绝对路径）
EXCEL_BASE_NAME = "base.xlsx"
# ===========================================================================
def main():
    # 初始化变量
    test_data = []  # 存储测试项数据（400.perlbench这类）
    summary_data = {}  # 存储3个汇总数据：SPEC2006/GHz、SPECint2006/GHz、SPECfp2006/GHz
    current_section = ""  # 记录当前所属分区（SPECINT2006/SPECFP2006）
    # 正则匹配规则
    section_pattern = re.compile(r'\*+ (SPECINT|SPECFP)\s+2006 \*+')  # 匹配分区
    item_pattern = re.compile(r'(\d+)\.([\w\d]+):\s*(\d+\.\d+),\s*(\d+\.\d+)')  # 匹配测试项
    # 新增：匹配3个GHz汇总数据
    summary_pattern = re.compile(r'(SPEC2006/GHz|SPECint2006/GHz|SPECfp2006/GHz):\s*(\d+\.\d+)')

    # 1. 读取外部文本文件
    try:
        if not os.path.exists(DATA_FILE_PATH):
            print(f"❌ 错误：数据源文件不存在 → {DATA_FILE_PATH}")
            print(f"💡 请检查文件路径是否正确！")
            return

        with open(DATA_FILE_PATH, "r", encoding="utf-8") as f:
            lines = f.readlines()
        print(f"✅ 成功读取数据源文件，共 {len(lines)} 行")

    except Exception as e:
        print(f"❌ 读取文件失败：{str(e)}")
        return

    # 2. 遍历每行，提取【分区+测试项+3个汇总值】
    for line_num, line in enumerate(lines, 1):
        line = line.strip()
        if not line:  # 跳过空行
            continue

        # 匹配分区标识，更新当前分区
        sec_match = section_pattern.search(line)
        if sec_match:
            current_section = f"{sec_match.group(1)}2006"
            print(f"📌 识别到分区：{current_section}（第{line_num}行）")
            continue

        # 匹配3个GHz汇总数据（优先提取，避免被其他规则过滤）
        sum_match = summary_pattern.search(line)
        if sum_match:
            sum_key = sum_match.group(1)  # 汇总项名称（如SPEC2006/GHz）
            sum_val = float(sum_match.group(2))  # 汇总数值
            summary_data[sum_key] = sum_val
            print(f"📊 提取汇总数据：{sum_key} = {sum_val}（第{line_num}行）")
            continue

        # 匹配测试项，提取数据（仅当分区已识别时处理）
        if current_section:
            item_match = item_pattern.search(line)
            if item_match:
                prefix_num = int(item_match.group(1))
                test_name = f"{prefix_num}.{item_match.group(2)}"
                val1 = float(item_match.group(3))
                val2 = float(item_match.group(4))
                test_data.append({
                    "prefix_num": prefix_num,
                    "section": current_section,
                    "name": test_name,
                    "val1": val1,
                    "val2": val2
                })

    # 3. 数据有效性检查
    # 检查测试项
    if not test_data:
        print(f"❌ 错误：未提取到有效SPEC2006测试项！")
        return
    # 检查3个汇总值是否完整
    required_summary = ["SPEC2006/GHz", "SPECint2006/GHz", "SPECfp2006/GHz"]
    missing_summary = [k for k in required_summary if k not in summary_data]
    if missing_summary:
        print(f"⚠️  警告：缺失汇总数据 → {', '.join(missing_summary)}")
    else:
        print(f"✅ 3个汇总数据全部提取完成！")

    # 4. 测试项按【前缀数字】升序排列
    test_data.sort(key=lambda x: x["prefix_num"])
    print(f"✅ 共提取 {len(test_data)} 个有效测试项，已按前缀数字升序排序")

    # 5. 生成带日期的Excel文件名（格式：基础名_YYYYMMDD.xlsx）
    current_date = time.strftime("%Y%m%d")  # 获取当前日期，如20260130
    excel_filename = f"{EXCEL_BASE_NAME}_{current_date}.xlsx"
    # 若配置了绝对路径，可拼接绝对路径（示例）：
    # excel_filename = f"/nfs/home/zhengzhongqiang/Work/{EXCEL_BASE_NAME}_{current_date}.xlsx"

    # 6. 生成Excel文件（含测试项+汇总数据，美化格式）
    try:
        wb = Workbook()
        ws = wb.active
        ws.title = "SPEC2006_Result"

        # ===== 第一步：写入测试项表头 + 数据 =====
        # 测试项表头
        test_headers = ["分区", "测试项名称", "数值1", "数值2"]
        for col, header in enumerate(test_headers, 1):
            cell = ws.cell(row=1, column=col, value=header)
            cell.font = Font(bold=True, size=11)
            cell.alignment = Alignment(horizontal="center", vertical="center")
        # 写入测试项数据
        for row, item in enumerate(test_data, 2):
            ws.cell(row=row, column=1, value=item["section"])
            ws.cell(row=row, column=2, value=item["name"])
            ws.cell(row=row, column=3, value=item["val1"])
            ws.cell(row=row, column=4, value=item["val2"])

        # ===== 第二步：写入汇总数据（测试项下隔2行，单独分组）=====
        summary_start_row = len(test_data) + 4  # 汇总数据开始行（隔2行，更清晰）
        # 汇总数据表头
        ws.cell(row=summary_start_row, column=1, value="汇总数据（GHz）")
        ws.cell(row=summary_start_row, column=1).font = Font(bold=True, size=12)
        ws.cell(row=summary_start_row, column=1).alignment = Alignment(horizontal="center")
        # 汇总数据列头
        ws.cell(row=summary_start_row+1, column=1, value="指标名称")
        ws.cell(row=summary_start_row+1, column=2, value="数值")
        for col in [1,2]:
            cell = ws.cell(row=summary_start_row+1, column=col)
            cell.font = Font(bold=True, size=11)
            cell.alignment = Alignment(horizontal="center")
        # 写入3个汇总数据
        for row, (sum_key, sum_val) in enumerate(summary_data.items(), summary_start_row+2):
            ws.cell(row=row, column=1, value=sum_key)
            ws.cell(row=row, column=2, value=sum_val)

        # ===== 第三步：Excel格式美化（列宽适配）=====
        ws.column_dimensions['A'].width = 20  # 分区/指标名称列
        ws.column_dimensions['B'].width = 18  # 测试项名称/数值列
        ws.column_dimensions['C'].width = 10  # 数值1列
        ws.column_dimensions['D'].width = 10  # 数值2列
        # 合并汇总表头单元格（A列跨列，更美观）
        ws.merge_cells(f'A{summary_start_row}:D{summary_start_row}')

        # 保存Excel文件
        wb.save(excel_filename)
        if os.path.exists(excel_filename):
            file_size = os.path.getsize(excel_filename) / 1024
            print("="*70)
            print(f"🎉 全部处理完成！")
            print(f"📊 输出Excel文件：{os.path.abspath(excel_filename)}")
            print(f"📈 数据量：{len(test_data)} 个测试项 + {len(summary_data)} 个汇总项")
            print(f"📁 文件大小：{file_size:.2f} KB")
            print(f"💡 可直接用Excel/WPS/LibreOffice打开，格式已美化！")
            print("="*70)
        else:
            print(f"❌ 错误：Excel文件生成失败！")

    except Exception as e:
        print(f"❌ 生成Excel失败：{str(e)}")
        print(f"💡 请检查输出路径是否有写入权限！")

if __name__ == "__main__":
    print("===== SPEC2006数据提取工具（含汇总值+Excel带日期）=====\n")
    main()