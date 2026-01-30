#!/usr/bin/env python3
"""
比较两个目录下的 score.txt 文件（或指定文件名），输出每个 benchmark 的 A 值、B 值、delta 与百分比。

用法示例：
  python3 scripts/compare_score.py --rootA /path/to/A --rootB /path/to/B

参数：
  --rootA / -a : 目录 A
  --rootB / -b : 目录 B
  --file -f    : 文件名（默认为 score.txt）
  --out-csv    : 将 CSV 输出写到指定文件（默认写到 stdout）
  --out-xlsx   : 可选，将全部结果写入一个 xlsx 文件（需 openpyxl）

行为：
  - 当某 benchmark 的值为 N/A（不区分大小写）或任一侧缺失时，delta 与 pct 输出为 N/A
  - 支持值为逗号分隔的数值序列，例如 "47.998, 15.999"，按位置分别比较
  - 百分比保留两位小数并带上 % 符号
"""

import argparse
import os
import re
import sys
from typing import Dict, List, Optional, Tuple

NUM_RE = r'[-+]?(?:\d{1,3}(?:,\d{3})*|\d+)(?:\.\d+)?(?:[eE][-+]?\d+)?'


def read_score_file(path: str) -> Dict[str, Optional[List[float]]]:
    """读取 score 文件，返回 dict: benchmark -> list of floats OR None (表示 N/A)。"""
    data: Dict[str, Optional[List[float]]] = {}
    if not os.path.exists(path):
        return data
    line_re = re.compile(r'^\s*([^:]+):\s*(.+)$')
    with open(path, 'r', encoding='utf-8', errors='ignore') as fh:
        for ln in fh:
            m = line_re.match(ln.rstrip('\n'))
            if not m:
                continue
            name = m.group(1).strip()
            val = m.group(2).strip()
            if not val or val.lower() == 'n/a':
                data[name] = None
                continue
            parts = [p.strip() for p in val.split(',') if p.strip()]
            nums: List[float] = []
            bad = False
            for p in parts:
                # 移除千位分隔符中的逗号，然后尝试解析浮点
                pp = p.replace(',', '')
                try:
                    nums.append(float(pp))
                except Exception:
                    bad = True
                    break
            if bad:
                # 无法解析时当作 N/A
                data[name] = None
            else:
                data[name] = nums
    return data


def compute_deltas(a_vals: List[float], b_vals: List[float]) -> Tuple[List[float], List[Optional[float]]]:
    """对齐 a_vals 与 b_vals（要求长度相等），返回 (deltas, pcts)
    pcts 中的元素为 (b-a)/a*100 或 None（当 a==0 且 b==0 -> 0.0；当 a==0 且 b!=0 -> inf）。
    """
    n = len(a_vals)
    deltas: List[float] = []
    pcts: List[Optional[float]] = []
    for i in range(n):
        a = a_vals[i]
        b = b_vals[i]
        d = b - a
        deltas.append(d)
        if a == 0.0:
            if b == 0.0:
                p = 0.0
            else:
                p = float('inf')
        else:
            p = (d / a) * 100.0
        pcts.append(p)
    return deltas, pcts


def save_to_excel(path: str, header: List[str], rows: List[List[str]]) -> bool:
    try:
        from openpyxl import Workbook
    except Exception as e:
        print(f"要保存为 Excel，请先安装 openpyxl：pip install openpyxl\n导入错误：{e}", file=sys.stderr)
        return False
    wb = Workbook()
    ws = wb.active
    for r in rows:
        ws.append(r)
    # 调整列宽
    for i, col in enumerate(ws.columns, start=1):
        max_len = 0
        for cell in col:
            try:
                v = '' if cell.value is None else str(cell.value)
            except Exception:
                v = ''
            if len(v) > max_len:
                max_len = len(v)
        try:
            ws.column_dimensions[ws.cell(row=1, column=i).column_letter].width = max_len + 2
        except Exception:
            pass
    try:
        wb.save(path)
        return True
    except Exception as e:
        print(f"保存 Excel 失败：{e}", file=sys.stderr)
        return False


def build_rows(a_map: Dict[str, Optional[List[float]]], b_map: Dict[str, Optional[List[float]]]) -> List[List[str]]:
    # 计算所有 benchmark 的并集
    all_keys = sorted(set(a_map.keys()) | set(b_map.keys()))
    # 先确定最大的字段数量以便构造表头
    max_cols = 1
    for v in list(a_map.values()) + list(b_map.values()):
        if v is not None:
            max_cols = max(max_cols, len(v))

    hdr = ['benchmark']
    for i in range(1, max_cols + 1):
        hdr += [f'A_{i}', f'B_{i}', f'delta_{i}', f'pct_{i}']

    rows: List[List[str]] = [hdr]

    for key in all_keys:
        a = a_map.get(key)
        b = b_map.get(key)
        row = [key]
        if a is None or b is None:
            # 只要任一侧为 None 或缺失，则输出 N/A
            # show A_i and B_i if present, else N/A
            for i in range(max_cols):
                if a is None or i >= len(a):
                    row.append('N/A')
                else:
                    row.append(format_number(a[i]))
                if b is None or i >= len(b):
                    row.append('N/A')
                else:
                    row.append(format_number(b[i]))
                row.append('N/A')  # delta
                row.append('N/A')  # pct
        else:
            # 两侧都存在，要求长度相同才能比较。
            if len(a) != len(b):
                # 若长度不同，仍把已有值写出，但 delta/pct 置为 N/A
                for i in range(max_cols):
                    if i < len(a):
                        row.append(format_number(a[i]))
                    else:
                        row.append('N/A')
                    if i < len(b):
                        row.append(format_number(b[i]))
                    else:
                        row.append('N/A')
                    row.append('N/A')
                    row.append('N/A')
            else:
                deltas, pcts = compute_deltas(a, b)
                for i in range(max_cols):
                    if i < len(a):
                        row.append(format_number(a[i]))
                        row.append(format_number(b[i]))
                        row.append(format_number(deltas[i]))
                        row.append(format_pct(pcts[i]))
                    else:
                        row += ['N/A', 'N/A', 'N/A', 'N/A']
        rows.append(row)
    return rows


def format_number(x: float) -> str:
    # 尽量保持整数不带小数，浮点保留最多6位小数并去掉尾部0
    if x is None:
        return 'N/A'
    try:
        if abs(x - round(x)) < 1e-9:
            return str(int(round(x)))
        else:
            s = f"{x:.6f}".rstrip('0').rstrip('.')
            return s
    except Exception:
        return str(x)


def format_pct(p: Optional[float]) -> str:
    if p is None:
        return 'N/A'
    if p == float('inf'):
        return 'inf%'
    try:
        return f"{p:.2f}%"
    except Exception:
        return str(p)


def parse_args(argv=None):
    p = argparse.ArgumentParser(description='比较两个目录下的 score 文件')
    p.add_argument('--rootA', '-a', required=True, help='目录 A 的根路径')
    p.add_argument('--rootB', '-b', required=True, help='目录 B 的根路径')
    p.add_argument('--file', '-f', default='score.txt', help='要比较的文件名（默认 score.txt）')
    p.add_argument('--out-csv', help='写出 CSV 到指定文件（默认 stdout）')
    p.add_argument('--out-xlsx', help='将结果写入单个 xlsx 文件（需要 openpyxl）')
    return p.parse_args(argv)


def main(argv=None):
    args = parse_args(argv)
    a_path = os.path.join(args.rootA, args.file)
    b_path = os.path.join(args.rootB, args.file)

    a_map = read_score_file(a_path)
    b_map = read_score_file(b_path)

    if not a_map and not b_map:
        print(f"在 {a_path} 和 {b_path} 均未找到可解析的条目", file=sys.stderr)
        sys.exit(2)

    rows = build_rows(a_map, b_map)

    # 输出 CSV
    if args.out_csv:
        try:
            with open(args.out_csv, 'w', encoding='utf-8') as fh:
                for r in rows:
                    fh.write(','.join(r) + '\n')
            print(f"CSV 已写入: {args.out_csv}", file=sys.stderr)
        except Exception as e:
            print(f"写出 CSV 失败: {e}", file=sys.stderr)
            sys.exit(3)
    else:
        for r in rows:
            print(','.join(r))

    # 可选：写入 xlsx
    if args.out_xlsx:
        ok = save_to_excel(args.out_xlsx, rows[0], rows)
        if ok:
            print(f"Excel 已写入: {args.out_xlsx}", file=sys.stderr)


if __name__ == '__main__':
    main()
