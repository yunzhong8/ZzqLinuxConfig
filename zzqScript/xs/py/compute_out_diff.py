#!/usr/bin/env python3
"""
比较两个目录 A/B 下相同子目录里的 `simulator_out.txt`，提取 instrCnt, cycleCnt, IPC 三个值，
并输出差值与变化率。

示例：
  python3 scripts/compute_out_diff.py --rootA /path/to/A --rootB /path/to/B --out-dir ./out_xlsx --out-csv compare_out.csv

输出：
 - CSV（stdout 或 --out-csv 指定的文件），列为: relpath,A_file,B_file,A_instrCnt,B_instrCnt,instrCnt_delta,instrCnt_pct,...
 - 可选：为每个相同子目录生成单独的 xlsx 文件（每行一个字段，列为 field,A_value,B_value,delta,pct）

注意：支持带千位分隔符的整数（例如 40,000,000）和小数（IPC）。
"""

import argparse
import os
import re
import sys
from typing import Dict, List, Optional, Tuple

# 匹配带千位分隔符的整数或小数，例如 40,000,000 或 83115719 或 0.481257
NUM_RE = r"[-+]?(?:\d{1,3}(?:,\d{3})*|\d+)(?:\.\d+)?(?:[eE][-+]?\d+)?"

DEFAULT_FIELDS = ['instrCnt', 'cycleCnt', 'IPC']


def build_file_map(root: str, filename: str = 'simulator_out.txt') -> Dict[str, str]:
    fmap = {}
    root = os.path.abspath(root)
    for dirpath, _, filenames in os.walk(root):
        for fn in filenames:
            if fn == filename:
                full = os.path.join(dirpath, fn)
                reldir = os.path.relpath(dirpath, root)
                if reldir == '.':
                    reldir = ''
                fmap[reldir] = full
    return fmap


def _parse_number_token(s: str) -> Optional[float]:
    if s is None:
        return None
    try:
        # 移除千位分隔符
        cleaned = s.replace(',', '')
        return float(cleaned)
    except Exception:
        return None


def extract_values_from_file(path: str, fields: List[str]) -> Dict[str, Optional[float]]:
    """在文件中查找每个字段的第一个数值。返回字段->数值或 None。"""
    results = {f: None for f in fields}
    try:
        text = open(path, 'r', encoding='utf-8', errors='ignore').read()
    except Exception as e:
        print(f"无法读取 {path}: {e}", file=sys.stderr)
        return results

    # 如果多个字段出现在同一行，例如:
    # "instrCnt = 40,000,000, cycleCnt = 83,115,719, IPC = 0.481257"
    # 我们希望在这一行一次性提取所有字段的值。为此先按行扫描，
    # 在包含任一字段名的行上使用一个联合正则来提取所有 name->value 对。
    field_alternation = '|'.join(re.escape(f) for f in fields)
    pair_re = re.compile(rf'(?P<name>{field_alternation})\s*(?:[:=,]|->)?\s*({NUM_RE})', re.IGNORECASE)

    for line in text.splitlines():
        if not line:
            continue
        # 快速判断行内是否包含任一字段名（忽略大小写）
        if not re.search(field_alternation, line, re.IGNORECASE):
            continue
        for m in pair_re.finditer(line):
            name = m.group('name')
            val = _parse_number_token(m.group(2))
            # 标准化字段名匹配（忽略大小写）: 找到 fields 中对应的键
            for fld in fields:
                if name.lower() == fld.lower():
                    if results.get(fld) is None:
                        results[fld] = val
                    break

    # 对于仍未找到的字段，回退到全文搜索每个字段的后续数字（原先逻辑的后备）
    for fld in fields:
        if results.get(fld) is not None:
            continue
        pat = re.compile(rf'{re.escape(fld)}\s*(?:[:=,]|->)?\s*({NUM_RE})', re.IGNORECASE)
        m = pat.search(text)
        if m:
            results[fld] = _parse_number_token(m.group(1))
        else:
            fld_re = re.compile(re.escape(fld), re.IGNORECASE)
            m2 = fld_re.search(text)
            if m2:
                tail = text[m2.end():m2.end() + 200]
                mnum = re.search(NUM_RE, tail)
                if mnum:
                    results[fld] = _parse_number_token(mnum.group(0))

    return results


def build_rows(rootA: str, rootB: str, fields: List[str], filename: str = 'simulator_out.txt'):
    amap = build_file_map(rootA, filename)
    bmap = build_file_map(rootB, filename)
    keys_a = set(amap.keys())
    keys_b = set(bmap.keys())
    common = sorted(keys_a & keys_b)
    only_a = sorted(keys_a - keys_b)
    only_b = sorted(keys_b - keys_a)

    rows = []  # (rel, a_path, b_path, field_map)
    skipped = []

    for rel in common:
        a_path = amap[rel]
        b_path = bmap[rel]
        a_vals = extract_values_from_file(a_path, fields)
        b_vals = extract_values_from_file(b_path, fields)
        fmap = {}
        for f in fields:
            a_v = a_vals.get(f)
            b_v = b_vals.get(f)
            if a_v is None:
                skipped.append(('A', rel or '.', f, 'A missing'))
            if b_v is None:
                skipped.append(('B', rel or '.', f, 'B missing'))
            delta = None
            pct = None
            if a_v is not None and b_v is not None:
                delta = b_v - a_v
                try:
                    if a_v == 0:
                        pct = float('inf') if b_v != 0 else 0.0
                    else:
                        pct = (delta / a_v) * 100.0
                except Exception:
                    pct = None
            fmap[f] = (a_v, b_v, delta, pct)
        rows.append((rel, a_path, b_path, fmap))

    return common, only_a, only_b, rows, skipped


def build_out_rows(rows, fields, sep=','):
    hdr = ['relpath', 'A_file', 'B_file']
    for f in fields:
        safe = f.replace(sep, '_')
        hdr += [f'A_{safe}', f'B_{safe}', f'{safe}_delta', f'{safe}_pct']
    out_rows = [hdr]
    for rel, a_path, b_path, fmap in rows:
        parts = [rel or '.', a_path, b_path]
        for f in fields:
            a_v, b_v, delta, pct = fmap.get(f, (None, None, None, None))
            if a_v is None:
                parts.append('')
            else:
                # instrCnt and cycleCnt 为整数，IPC 保留小数? 用户要求不用小数， but IPC is decimal; we'll show IPC rounded to 6 decimals in CSV and integer in excel? Keep consistent: show instrCnt/cycleCnt integer, IPC float rounded to 6 (but user previously asked no decimals; however for IPC decimals matter). We'll round instrCnt/cycleCnt to int and IPC to 6 decimals.
                if f.lower() in ('ip', 'ipc'):
                    parts.append(f"{a_v:.6f}")
                else:
                    parts.append(str(int(round(a_v))))

            if b_v is None:
                parts.append('')
            else:
                if f.lower() in ('ip', 'ipc'):
                    parts.append(f"{b_v:.6f}")
                else:
                    parts.append(str(int(round(b_v))))

            if delta is None:
                parts.append('')
            else:
                if f.lower() in ('ip', 'ipc'):
                    parts.append(f"{delta:.6f}")
                else:
                    parts.append(str(int(round(delta))))

            if pct is None:
                parts.append('')
            elif pct == float('inf'):
                parts.append('inf%')
            else:
                # 保留两位小数的百分比表示
                try:
                    parts.append(f"{pct:.2f}%")
                except Exception:
                    parts.append(str(pct))
        out_rows.append(parts)
    return out_rows


def save_to_excel(path: str, header: List[str], rows_data: List[List[str]]) -> bool:
    try:
        from openpyxl import Workbook
    except Exception as e:
        print(f"要保存为 Excel，请先安装 openpyxl：pip install openpyxl\n导入错误：{e}", file=sys.stderr)
        return False
    wb = Workbook()
    ws = wb.active
    for row in rows_data:
        ws.append(row)
    # 简单列宽调整
    for i, col in enumerate(ws.columns, start=1):
        max_len = 0
        for cell in col:
            try:
                v = str(cell.value) if cell.value is not None else ''
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


def print_csv_rows(rows: List[List[str]], sep: str = ',') -> None:
    for r in rows:
        print(sep.join(r))


def build_subdir_rows(rel: str, fmap: dict, fields: List[str]) -> Tuple[List[str], List[List[str]]]:
    header = ['field', 'A_value', 'B_value', 'delta', 'pct']
    rows_for_sub = [header]
    for f in fields:
        a_v, b_v, delta, pct = fmap.get(f, (None, None, None, None))
        if a_v is None:
            a_s = ''
        else:
            if f.lower() in ('ip', 'ipc'):
                a_s = f"{a_v:.6f}"
            else:
                a_s = str(int(round(a_v)))
        if b_v is None:
            b_s = ''
        else:
            if f.lower() in ('ip', 'ipc'):
                b_s = f"{b_v:.6f}"
            else:
                b_s = str(int(round(b_v)))
        if delta is None:
            d_s = ''
        else:
            if f.lower() in ('ip', 'ipc'):
                d_s = f"{delta:.6f}"
            else:
                d_s = str(int(round(delta)))
        if pct is None:
            p_s = ''
        elif pct == float('inf'):
            p_s = 'inf%'
        else:
            try:
                p_s = f"{pct:.2f}%"
            except Exception:
                p_s = str(pct)
        rows_for_sub.append([f, a_s, b_s, d_s, p_s])
    return header, rows_for_sub


def write_per_subdir_xlsx(out_dir: str, rows, fields: List[str], out_suffix: Optional[str] = None):
    os.makedirs(out_dir, exist_ok=True)
    for rel, a_path, b_path, fmap in rows:
        fname = 'root' if not rel else rel.replace(os.sep, '__').replace('/', '__')
        fname = re.sub(r'[^0-9A-Za-z._\-]+', '_', fname)
        # sanitize out_suffix and append if provided
        if out_suffix:
            suf = str(out_suffix).strip()
            # remove extension if user passed .xlsx
            if suf.lower().endswith('.xlsx'):
                suf = suf[:-5]
            # sanitize
            suf = re.sub(r'[^0-9A-Za-z._\-]+', '_', suf)
            out_fname = f"{fname}_{suf}.xlsx"
        else:
            out_fname = f"{fname}.xlsx"

        out_path = os.path.join(out_dir, out_fname)
        header, rows_for_sub = build_subdir_rows(rel, fmap, fields)
        ok = save_to_excel(out_path, header, rows_for_sub)
        if ok:
            print(f"已为子目录 {rel or '.'} 保存文件: {out_path}", file=sys.stderr)


def parse_args(argv=None):
    p = argparse.ArgumentParser()
    p.add_argument('--rootA', '-a', required=True)
    p.add_argument('--rootB', '-b', required=True)
    p.add_argument('--fields', help='逗号分隔字段，覆盖默认', default=','.join(DEFAULT_FIELDS))
    p.add_argument('--fields-file', help='字段文件，每行一个，# 开头为注释')
    p.add_argument('--occurrence', '-n', type=int, default=1)
    p.add_argument('--glob', default='simulator_out.txt')
    p.add_argument('--out-csv', help='将合并 CSV 输出到指定文件（默认 stdout）')
    p.add_argument('--out-dir', help='为每个子目录生成 xlsx 文件')
    p.add_argument('--out', help='添加到生成的 excel 文件名中的后缀/标识（例如 run id），会作为文件名的一部分')
    return p.parse_args(argv)


def main(argv=None):
    args = parse_args(argv)
    if args.fields_file:
        fields = []
        try:
            with open(args.fields_file, 'r', encoding='utf-8') as fh:
                for ln in fh:
                    s = ln.strip()
                    if not s or s.startswith('#'):
                        continue
                    fields.append(s)
        except Exception as e:
            print(f"无法读取字段文件 {args.fields_file}: {e}", file=sys.stderr)
            sys.exit(2)
    else:
        fields = [f.strip() for f in args.fields.split(',') if f.strip()]

    common, only_a, only_b, rows, skipped = build_rows(args.rootA, args.rootB, fields, args.glob)

    out_rows = build_out_rows(rows, fields, sep=',')

    # 输出 CSV 到 stdout 或文件
    if args.out_csv:
        try:
            with open(args.out_csv, 'w', encoding='utf-8') as fo:
                for r in out_rows:
                    fo.write(','.join(r) + '\n')
            print(f"已保存合并 CSV 到: {args.out_csv}", file=sys.stderr)
        except Exception as e:
            print(f"写 CSV 失败: {e}", file=sys.stderr)
    else:
        print_csv_rows(out_rows, ',')

    # 为每个子目录写 xlsx（可选）
    if args.out_dir:
        write_per_subdir_xlsx(args.out_dir, rows, fields, out_suffix=args.out)

    # 摘要
    print('\nSummary:', file=sys.stderr)
    print(f'  total common subdirs: {len(common)}', file=sys.stderr)
    print(f'  compared entries: {len(rows)}', file=sys.stderr)
    print(f'  only in A: {len(only_a)}; only in B: {len(only_b)}', file=sys.stderr)
    if skipped:
        print('\nSkipped items:', file=sys.stderr)
        for s in skipped:
            print(f'  {s}', file=sys.stderr)


if __name__ == '__main__':
    main()
