#!/usr/bin/env python3
"""
递归查找 `simulator_err.txt` 文件，提取指定字段的第 N 个匹配数字，并计算差值。

示例用法：
  python3 compute_field_diff.py --root /path/to/perf-report-kmhv3 --field TotalTime --occurrence 2

参数说明：
  --root       根目录，递归查找 `simulator_err.txt`（默认当前目录）
  --field      字段名（脚本会匹配类似 `FieldName: 123.45` 或 `FieldName = 123.45` 的行）
  --occurrence 要取第几个匹配（默认 2，即第二个匹配）
  --glob       限定文件名（默认 simulator_err.txt）
  --sep        输出分隔符（默认逗号，用于 CSV 输出）

输出：
  - 列表形式显示每个找到值的文件路径和值
  - 逐对打印相邻文件的差值（value_i - value_{i-1}）
  - 还提供相对于第一个文件的差值

如果某文件没有足够的匹配项，会被跳过，并在末尾列出被跳过的文件。
"""

import argparse
import os
import re
import sys
from typing import List, Tuple, Optional

NUM_RE = r'[-+]?(?:\d+\.?\d*|\.\d+)(?:[eE][-+]?\d+)?'  # 支持浮点与指数形式，且要求至少有一位数字

# 在此设置默认的字段列表（以列表形式），当没有通过命令行或文件指定时使用。
# 例如：DEFAULT_FIELDS = ['l2prefetchSentBOP', 'l2prefetchRecvBOP']
DEFAULT_FIELDS: List[str] = ['l2prefetchSentBOP']


def build_file_map(root: str, filename_glob: str = 'simulator_err.txt') -> dict:
    """在 root 下递归查找 filename_glob，并返回从 root 的相对目录 -> 绝对文件路径 的映射。

    例如，如果文件是 /root/x/y/simulator_err.txt，则映射键为 'x/y' (或 '.' 表示 root 本身)，
    值为绝对路径 '/root/x/y/simulator_err.txt'。
    """
    fmap = {}
    root = os.path.abspath(root)
    for dirpath, _, filenames in os.walk(root):
        for fn in filenames:
            if fn == filename_glob:
                full = os.path.join(dirpath, fn)
                reldir = os.path.relpath(dirpath, root)
                # normalize reldir: use '.' for root itself
                if reldir == '.':
                    reldir = ''
                fmap[reldir] = full
    return fmap


def extract_nth_value_from_file(path: str, field: str, occurrence: int) -> Optional[float]:
    # 匹配形式：FieldName : number 或 FieldName = number 或 FieldName\s+number
    # 忽略大小写
    # 使用非贪婪匹配行内的数字
    # 先判断该行是否包含字段（不区分大小写），再从该行提取数字。
    field_re = re.compile(re.escape(field), re.IGNORECASE)
    num_re = re.compile(NUM_RE)
    values = []
    try:
        with open(path, 'r', encoding='utf-8', errors='ignore') as f:
            for line in f:
                m_field = field_re.search(line)
                if m_field:
                    # 优先匹配字段名后紧跟的数字（允许有逗号、冒号、等号或箭头等分隔符）
                    post_pattern = re.compile(rf'{re.escape(field)}\s*(?:[:=,]|->)?\s*({NUM_RE})', re.IGNORECASE)
                    pm = post_pattern.search(line, m_field.start())
                    if pm:
                        try:
                            values.append(float(pm.group(1)))
                        except ValueError:
                            pass
                    else:
                        # 如果没有直接跟随的数字，则只提取字段名之后出现的数字（排除字段前的数字，例如 time=...）
                        for it in num_re.finditer(line):
                            if it.start() >= m_field.end():
                                try:
                                    values.append(float(it.group(0)))
                                except ValueError:
                                    continue
                        # 如果仍然没有找到（例如数字在字段之前），则不记录任何值
    except Exception as e:
        print(f"无法读取文件 {path}: {e}", file=sys.stderr)
        return None

    if len(values) >= occurrence:
        return values[occurrence - 1]
    return None


def build_subdir_rows(rel: str, fmap: dict, fields: List[str]) -> Tuple[List[str], List[List[str]]]:
    """为单个子目录构建要写入 Excel 的表头和行。

    返回 (header, rows_for_sub)，其中 rows_for_sub 的第一行应为 header。
    每个后续行格式为 [field, base, feature, delta, pct]
    """
    header = ['field', 'base', 'feature', 'delta', 'pct']
    rows_for_sub = [header]
    # fmap: field -> (a_val, b_val, delta, pct)
    for fld in fields:
        a_val, b_val, delta, pct = fmap.get(fld, (None, None, None, None))
        a_s = '' if a_val is None else str(int(round(a_val)))
        b_s = '' if b_val is None else str(int(round(b_val)))
        d_s = '' if delta is None else str(int(round(delta)))
        if pct is None:
            p_s = ''
        elif pct == float('inf'):
            p_s = 'inf%'
        else:
            p_s = f"{int(round(pct))}%"

        rows_for_sub.append([fld, a_s, b_s, d_s, p_s])

    return header, rows_for_sub


def save_to_excel(path: str, header: List[str], rows_data: List[List[str]]) -> bool:
    """将表头和行写入指定的 xlsx 文件。返回是否成功。

    参数:
      path: 输出文件路径
      header: 表头列表
      rows_data: 包含 header 在内的所有行
    """
    try:
        from openpyxl import Workbook
    except Exception as e:
        print(f"要保存为 Excel，请先安装 openpyxl：pip install openpyxl\n导入错误：{e}", file=sys.stderr)
        return False

    wb = Workbook()
    ws = wb.active
    # rows_data 的第一行通常是 header
    for row in rows_data:
        ws.append(row)

    # 可选：调整列宽（简单估算）
    for i, col in enumerate(ws.columns, start=1):
        max_len = 0
        for cell in col:
            try:
                val = str(cell.value) if cell.value is not None else ''
            except Exception:
                val = ''
            if len(val) > max_len:
                max_len = len(val)
        adjusted_width = (max_len + 2)
        try:
            ws.column_dimensions[ws.cell(row=1, column=i).column_letter].width = adjusted_width
        except Exception:
            # 某些合并单元格或特殊列可能导致 column_letter 无效，忽略该错误
            pass

    try:
        wb.save(path)
        return True
    except Exception as e:
        print(f"保存 Excel 失败：{e}", file=sys.stderr)
        return False


def print_csv_rows(rows: List[List[str]], sep: str = ',') -> None:
    """将 rows（每行为字符串列表）打印为 CSV 风格到 stdout，使用指定分隔符。"""
    for r in rows:
        print(sep.join(r))


def parse_args(argv=None):
    p = argparse.ArgumentParser(description='比较两个目录 A/B 中同名子目录下的 simulator_err.txt，提取字段的第 N 个匹配并计算 B - A 差值')
    p.add_argument('--rootA', '-a', required=True, help='目录 A 的根路径')
    p.add_argument('--rootB', '-b', required=True, help='目录 B 的根路径')
    p.add_argument('--field', '-f', help='单个字段名（已弃用，优先使用 --fields）')
    p.add_argument('--fields', help='逗号分隔的字段名列表，例如 "FieldA,FieldB"（优先级最高）')
    p.add_argument('--fields-file', help='包含字段名的文件，每行一个字段（优先级次之）')
    p.add_argument('--occurrence', '-n', type=int, default=2, help='取第 N 个匹配（默认 2）')
    p.add_argument('--glob', default='simulator_err.txt', help='要匹配的文件名（默认 simulator_err.txt）')
    p.add_argument('--sep', default=',', help='输出分隔符（默认 ","）')
    p.add_argument('--out-xlsx', help='将结果保存为 Excel 文件（.xlsx），需要安装 openpyxl')
    p.add_argument('--out-dir', help='将每个子目录的比较结果分别保存为单独的 xlsx 文件到该目录（按子目录命名）')
    return p.parse_args(argv)


def collect_rows(rootA: str, rootB: str, fields: List[str], glob: str, occurrence: int):
    """收集并返回比较数据。

    返回 (common, only_a, only_b, rows, skipped)
    rows 每个元素为 (rel, a_path, b_path, field_map)
    skipped 为列表 (side, rel, field, reason)
    """
    amap = build_file_map(rootA, glob)
    bmap = build_file_map(rootB, glob)

    keys_a = set(amap.keys())
    keys_b = set(bmap.keys())
    common = sorted(keys_a & keys_b)
    only_a = sorted(keys_a - keys_b)
    only_b = sorted(keys_b - keys_a)

    rows = []
    skipped = []

    for rel in common:
        a_path = amap[rel]
        b_path = bmap[rel]
        field_map = {}
        for fld in fields:
            a_val = extract_nth_value_from_file(a_path, fld, occurrence)
            b_val = extract_nth_value_from_file(b_path, fld, occurrence)
            if a_val is None:
                skipped.append(('A', rel or '.', fld, 'A 文件没有足够的匹配或解析失败'))
            if b_val is None:
                skipped.append(('B', rel or '.', fld, 'B 文件没有足够的匹配或解析失败'))

            delta = None
            pct = None
            if a_val is not None and b_val is not None:
                delta = b_val - a_val
                try:
                    if a_val == 0:
                        if b_val == 0:
                            pct = 0.0
                        else:
                            pct = float('inf')
                    else:
                        pct = (delta / a_val) * 100.0
                except Exception:
                    pct = None

            field_map[fld] = (a_val, b_val, delta, pct)

        rows.append((rel, a_path, b_path, field_map))

    return common, only_a, only_b, rows, skipped


def build_out_rows(rows: List[Tuple[str, str, str, dict]], fields: List[str], sep: str = ',') -> List[List[str]]:
    """根据 rows 和 fields 构建 CSV 行（包含 header）。返回 out_rows。
    """
    hdr_parts = ['relpath', 'A_file', 'B_file']
    for fld in fields:
        safe = fld.replace(sep, '_')
        hdr_parts += [f'A_{safe}', f'B_{safe}', f'{safe}_delta', f'{safe}_pct']

    out_rows = [hdr_parts]
    for rel, a_path, b_path, fmap in rows:
        rel_display = rel or '.'
        parts = [rel_display, a_path, b_path]
        for fld in fields:
            a_val, b_val, delta, pct = fmap.get(fld, (None, None, None, None))
            if a_val is None:
                parts.append('')
            else:
                try:
                    parts.append(str(int(round(a_val))))
                except Exception:
                    parts.append(str(a_val))

            if b_val is None:
                parts.append('')
            else:
                try:
                    parts.append(str(int(round(b_val))))
                except Exception:
                    parts.append(str(b_val))

            if delta is None:
                parts.append('')
            else:
                try:
                    parts.append(str(int(round(delta))))
                except Exception:
                    parts.append(str(delta))

            if pct is None:
                parts.append('')
            elif pct == float('inf'):
                parts.append('inf%')
            else:
                try:
                    parts.append(f"{int(round(pct))}%")
                except Exception:
                    parts.append(str(pct))

        out_rows.append(parts)

    return out_rows


def write_per_subdir_xlsx(out_dir: str, rows: List[Tuple[str, str, str, dict]], fields: List[str]):
    os.makedirs(out_dir, exist_ok=True)
    for rel, a_path, b_path, fmap in rows:
        rel_display = rel or '.'
        if rel in ('.', ''):
            fname = 'root'
        else:
            fname = rel.replace(os.sep, '__').replace('/', '__')
            fname = re.sub(r'[^0-9A-Za-z._\-]+', '_', fname)

        out_path = os.path.join(out_dir, f"{fname}.xlsx")
        header, rows_for_sub = build_subdir_rows(rel, fmap, fields)
        ok = save_to_excel(out_path, header, rows_for_sub)
        if ok:
            print(f"已为子目录 {rel_display} 保存文件: {out_path}", file=sys.stderr)


def main(argv=None):
    p = argparse.ArgumentParser(description='比较两个目录 A/B 中同名子目录下的 simulator_err.txt，提取字段的第 N 个匹配并计算 B - A 差值')
    p.add_argument('--rootA', '-a', required=True, help='目录 A 的根路径')
    p.add_argument('--rootB', '-b', required=True, help='目录 B 的根路径')
    p.add_argument('--field', '-f', help='单个字段名（已弃用，优先使用 --fields）')
    p.add_argument('--fields', help='逗号分隔的字段名列表，例如 "FieldA,FieldB"（优先级最高）')
    p.add_argument('--fields-file', help='包含字段名的文件，每行一个字段（优先级次之）')
    p.add_argument('--occurrence', '-n', type=int, default=2, help='取第 N 个匹配（默认 2）')
    p.add_argument('--glob', default='simulator_err.txt', help='要匹配的文件名（默认 simulator_err.txt）')
    p.add_argument('--sep', default=',', help='输出分隔符（默认 ","）')
    p.add_argument('--out-xlsx', help='将结果保存为 Excel 文件（.xlsx），需要安装 openpyxl')
    p.add_argument('--out-dir', help='将每个子目录的比较结果分别保存为单独的 xlsx 文件到该目录（按子目录命名）')
    args = p.parse_args(argv)

    amap = build_file_map(args.rootA, args.glob)
    bmap = build_file_map(args.rootB, args.glob)

    if not amap and not bmap:
        print(f'在 {args.rootA} 和 {args.rootB} 下均未找到任何 {args.glob} 文件', file=sys.stderr)
        sys.exit(2)

    # 找到在两侧都存在的相对子目录
    keys_a = set(amap.keys())
    keys_b = set(bmap.keys())
    common = sorted(keys_a & keys_b)
    only_a = sorted(keys_a - keys_b)
    only_b = sorted(keys_b - keys_a)

    # 解析 fields 参数，优先级： --fields > --fields-file > --field > DEFAULT_FIELDS
    fields: List[str] = []
    if args.fields:
        fields = [f.strip() for f in args.fields.split(',') if f.strip()]
    elif args.fields_file:
        try:
            fields = []
            with open(args.fields_file, 'r', encoding='utf-8') as fh:
                for ln in fh:
                    s = ln.strip()
                    # 以 '#' 开头的行视为注释，忽略
                    if not s or s.startswith('#'):
                        continue
                    fields.append(s)
        except Exception as e:
            print(f'无法读取 fields 文件 {args.fields_file}: {e}', file=sys.stderr)
            sys.exit(3)
    elif args.field:
        # 保留向后兼容
        fields = [args.field.strip()]
    else:
        # 使用脚本内的默认字段列表（可以在文件顶部的 DEFAULT_FIELDS 中修改）
        fields = list(DEFAULT_FIELDS)

    if not fields:
        print('字段列表为空：请通过 --fields/--fields-file/--field 指定字段，或在脚本中设置 DEFAULT_FIELDS。', file=sys.stderr)
        sys.exit(3)

    rows = []  # (relpath, a_path, b_path, {field: (a_val,b_val,delta,pct_or_flag)})
    skipped = []  # (side, relpath, field, reason)

    for rel in common:
        a_path = amap[rel]
        b_path = bmap[rel]
        field_map = {}
        for fld in fields:
            a_val = extract_nth_value_from_file(a_path, fld, args.occurrence)
            b_val = extract_nth_value_from_file(b_path, fld, args.occurrence)
            if a_val is None:
                skipped.append(('A', rel or '.', fld, 'A 文件没有足够的匹配或解析失败'))
            if b_val is None:
                skipped.append(('B', rel or '.', fld, 'B 文件没有足够的匹配或解析失败'))

            delta = None
            pct = None
            if a_val is not None and b_val is not None:
                delta = b_val - a_val
                # 变化率：相对于 A 的百分比 (B-A)/A * 100
                try:
                    if a_val == 0:
                        if b_val == 0:
                            pct = 0.0
                        else:
                            pct = float('inf')
                    else:
                        pct = (delta / a_val) * 100.0
                except Exception:
                    pct = None

            field_map[fld] = (a_val, b_val, delta, pct)

        rows.append((rel, a_path, b_path, field_map))

    # 输出 CSV 表头
    # 输出动态表头：relpath,A_file,B_file,然后每个字段4列：A_field,B_field,field_delta,field_pct
    hdr_parts = ['relpath', 'A_file', 'B_file']
    for fld in fields:
        safe = fld.replace(args.sep, '_')
        hdr_parts += [f'A_{safe}', f'B_{safe}', f'{safe}_delta', f'{safe}_pct']
    # 收集输出行，便于同时写到 stdout、CSV 或 Excel
    out_rows = []
    out_rows.append(hdr_parts)

    for rel, a_path, b_path, fmap in rows:
        rel_display = rel or '.'
        parts = [rel_display, a_path, b_path]
        for fld in fields:
            a_val, b_val, delta, pct = fmap.get(fld, (None, None, None, None))
            # 显示为整数（四舍五入），百分比带上百分号且为整数
            if a_val is None:
                parts.append('')
            else:
                try:
                    parts.append(str(int(round(a_val))))
                except Exception:
                    parts.append(str(a_val))

            if b_val is None:
                parts.append('')
            else:
                try:
                    parts.append(str(int(round(b_val))))
                except Exception:
                    parts.append(str(b_val))

            if delta is None:
                parts.append('')
            else:
                try:
                    parts.append(str(int(round(delta))))
                except Exception:
                    parts.append(str(delta))

            # pct: represent inf as 'inf%'; otherwise round to integer percent and append '%'
            if pct is None:
                parts.append('')
            elif pct == float('inf'):
                parts.append('inf%')
            else:
                try:
                    parts.append(f"{int(round(pct))}%")
                except Exception:
                    parts.append(str(pct))

        out_rows.append(parts)

    # 打印到 stdout（CSV 风格）
    print_csv_rows(out_rows, args.sep)

    

    if args.out_xlsx:
        ok = save_to_excel(args.out_xlsx, out_rows[0], out_rows)
        if ok:
            print(f"已保存 Excel 到: {args.out_xlsx}", file=sys.stderr)

    # 如果指定了 out-dir，则为每个子目录写单独的 xlsx 文件，文件名基于子目录名
    if args.out_dir:
        out_dir = os.path.abspath(args.out_dir)
        try:
            os.makedirs(out_dir, exist_ok=True)
        except Exception as e:
            print(f"无法创建输出目录 {out_dir}: {e}", file=sys.stderr)
            sys.exit(4)

        # 为每个子目录生成独立的表：每行对应一个 field，列为 field, base, feature, delta, pct
        for rel, a_path, b_path, fmap in rows:
            rel_display = rel or '.'
            # sanitize filename
            if rel in ('.', ''):
                fname = 'root'
            else:
                fname = rel.replace(os.sep, '__').replace('/', '__')
                fname = re.sub(r'[^0-9A-Za-z._\-]+', '_', fname)

            out_path = os.path.join(out_dir, f"{fname}.xlsx")

            # build header and rows for this subdir
            header = ['field', 'base', 'feature', 'delta', 'pct']
            rows_for_sub = [header]
            for fld in fields:
                a_val, b_val, delta, pct = fmap.get(fld, (None, None, None, None))
                a_s = '' if a_val is None else str(int(round(a_val)))
                b_s = '' if b_val is None else str(int(round(b_val)))
                d_s = '' if delta is None else str(int(round(delta)))
                if pct is None:
                    p_s = ''
                elif pct == float('inf'):
                    p_s = 'inf%'
                else:
                    p_s = f"{int(round(pct))}%"

                rows_for_sub.append([fld, a_s, b_s, d_s, p_s])

            ok = save_to_excel(out_path, header, rows_for_sub)
            if ok:
                print(f"已为子目录 {rel_display} 保存文件: {out_path}", file=sys.stderr)

    # 摘要
    print('\nSummary:', file=sys.stderr)
    print(f'  total common subdirs: {len(common)}', file=sys.stderr)
    print(f'  compared entries (common subdirs): {len(rows)}', file=sys.stderr)
    print(f'  only in A: {len(only_a)}; only in B: {len(only_b)}', file=sys.stderr)
    if only_a:
        print('\nOnly in A:', file=sys.stderr)
        for r in only_a:
            print(f'  {r or "."}', file=sys.stderr)
    if only_b:
        print('\nOnly in B:', file=sys.stderr)
        for r in only_b:
            print(f'  {r or "."}', file=sys.stderr)

    if skipped:
        print('\nSkipped items (missing value or parse error):', file=sys.stderr)
        for side, rel, fld, reason in skipped:
            print(f'  [{side}] {rel} | field={fld} -- {reason}', file=sys.stderr)


if __name__ == '__main__':
    main()
