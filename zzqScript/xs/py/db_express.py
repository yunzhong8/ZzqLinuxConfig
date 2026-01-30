import sqlite3
import os
import csv
from typing import List, Dict, Optional
import openpyxl  # 用于生成 Excel 文件
from openpyxl.styles import Font, Alignment  # 简单美化 Excel 格式
import argparse
import logging
import sys


class SQLiteDBParser:
    """SQLite 数据库文件解析器（支持批量遍历所有表 + CSV/Excel 双导出）"""

    def __init__(self, db_path: str, verbose: bool = True, log_file: Optional[str] = None):
        """
        初始化解析器
        :param db_path: .db 文件的路径
        :param verbose: 是否在终端打印少量重要信息
        :param log_file: 日志文件路径，默认 ./db_express.log
        """
        self.db_path = db_path
        self.conn = None
        self.cursor = None
        # 是否打印少量重要信息到终端
        self.verbose = verbose

        # 校验文件是否存在
        if not os.path.exists(db_path):
            raise FileNotFoundError(f"数据库文件不存在：{db_path}")

        # 校验是否为 SQLite 数据库（简单校验）
        with open(db_path, 'rb') as f:
            header = f.read(16)
            if header != b'SQLite format 3\x00':
                raise ValueError(f"文件 {db_path} 不是有效的 SQLite 数据库")

        # 设置 logger
        self.logger = None
        self.setup_logger(log_file)

    def setup_logger(self, log_file: Optional[str] = None):
        """配置文件日志（可选路径），若已配置则覆盖旧配置"""
        if log_file is None:
            log_file = os.path.join(os.getcwd(), "db_express.log")
        logger = logging.getLogger(f"SQLiteDBParser_{id(self)}")
        logger.setLevel(logging.DEBUG)
        # 移除旧处理器
        for h in list(logger.handlers):
            logger.removeHandler(h)
        fh = logging.FileHandler(log_file, encoding='utf-8')
        fh.setLevel(logging.DEBUG)
        fmt = logging.Formatter("%(asctime)s %(levelname)s: %(message)s")
        fh.setFormatter(fmt)
        logger.addHandler(fh)
        logger.propagate = False
        self.logger = logger

    def _dbg(self, *args):
        """详细日志，仅写入日志文件"""
        msg = " ".join(str(a) for a in args)
        if self.logger:
            self.logger.debug(msg)
        else:
            if self.verbose:
                print(msg)

    def _info(self, *args):
        """重要信息：既输出到终端也写入 info 日志"""
        msg = " ".join(str(a) for a in args)
        # terminal
        if self.verbose:
            print(msg)
        # log
        if self.logger:
            self.logger.info(msg)

    def _error(self, *args):
        """错误信息：输出到 stderr 并写入错误日志"""
        msg = " ".join(str(a) for a in args)
        print(msg, file=sys.stderr)
        if self.logger:
            self.logger.error(msg)

    def connect(self):
        """连接数据库"""
        try:
            self.conn = sqlite3.connect(self.db_path)
            # 设置行工厂，让查询结果以字典形式返回（更易读）
            self.conn.row_factory = sqlite3.Row
            self.cursor = self.conn.cursor()
            self._info(f"✅ 成功连接到数据库：{self.db_path}")
            self._dbg(f"打开数据库：{self.db_path}")
        except sqlite3.Error as e:
            raise ConnectionError(f"连接数据库失败：{e}")

    def close(self):
        """关闭数据库连接"""
        if self.conn:
            self.conn.close()
            self._info("✅ 数据库连接已关闭")
            self._dbg("数据库连接已释放")

    def get_all_tables(self) -> List[str]:
        """获取数据库中所有表名"""
        if not self.cursor:
            raise RuntimeError("请先调用 connect() 连接数据库")

        self.cursor.execute("""
            SELECT name FROM sqlite_master 
            WHERE type='table' AND name NOT LIKE 'sqlite_%'
        """)
        tables = [row['name'] for row in self.cursor.fetchall()]
        self._dbg(f"数据库中包含表：{tables}")
        return tables

    def get_table_structure(self, table_name: str) -> List[Dict]:
        """获取指定表的结构（字段名、类型、是否主键等）"""
        if not self.cursor:
            raise RuntimeError("请先调用 connect() 连接数据库")

        self.cursor.execute(f"PRAGMA table_info({table_name})")
        structure = []
        for row in self.cursor.fetchall():
            structure.append({
                "字段名": row['name'],
                "类型": row['type'],
                "是否可为空": "否" if row['notnull'] else "是",
                "默认值": row['dflt_value'],
                "是否主键": "是" if row['pk'] else "否"
            })

        self._dbg(f"表 {table_name} 结构: {structure}")
        return structure

    def get_table_row_count(self, table_name: str) -> int:
        """获取表的总行数（快速判断是否有数据）"""
        if not self.cursor:
            raise RuntimeError("请先调用 connect() 连接数据库")

        self.cursor.execute(f"SELECT COUNT(*) FROM {table_name}")
        count = self.cursor.fetchone()[0]
        self._dbg(f"表 {table_name} 总行数：{count}")
        return count

    def query_table_data(self, table_name: str, limit: Optional[int] = 10) -> List[Dict]:
        """查询表中的数据（默认返回前10行）"""
        if not self.cursor:
            raise RuntimeError("请先调用 connect() 连接数据库")

        query_sql = f"SELECT * FROM {table_name}"
        if limit:
            query_sql += f" LIMIT {limit}"

        self.cursor.execute(query_sql)
        rows = self.cursor.fetchall()
        data = [dict(row) for row in rows]

        if data:
            self._dbg(f"表 {table_name} 前 {len(data)} 行: {data[:min(len(data),5)]} ...")
        else:
            self._dbg(f"表 {table_name} 无数据")
        return data

    def export_table_to_csv(self, table_name: str, csv_dir: str):
        """将表数据导出为 CSV 文件（按表名生成独立文件）"""
        os.makedirs(csv_dir, exist_ok=True)
        csv_path = os.path.join(csv_dir, f"{table_name}.csv")

        data = self.query_table_data(table_name, limit=None)
        if not data:
            self._dbg(f"表 {table_name} 无数据，跳过 CSV 导出")
            return

        with open(csv_path, 'w', newline='', encoding='utf-8') as f:
            writer = csv.DictWriter(f, fieldnames=data[0].keys())
            writer.writeheader()
            writer.writerows(data)

        self._info(f"💾 表 {table_name} CSV 已导出到：{csv_path}")
        self._dbg(f"CSV 写入完成：{csv_path}")

    def export_table_to_excel(self, table_name: str, excel_dir: str):
        """将表数据导出为 Excel 文件（按表名生成独立文件，简单美化格式）"""
        os.makedirs(excel_dir, exist_ok=True)

        data = self.query_table_data(table_name, limit=None)
        if not data:
            self._dbg(f"表 {table_name} 无数据，跳过 Excel 导出")
            return

        # Excel 每个 sheet/文件最大行数（含表头）
        EXCEL_MAX_ROWS = 1048576
        # 数据行最大数量（减去表头）
        CHUNK_SIZE = EXCEL_MAX_ROWS - 1

        headers = list(data[0].keys())
        total_rows = len(data)

        if total_rows <= CHUNK_SIZE:
            # 单文件导出
            excel_path = os.path.join(excel_dir, f"{table_name}.xlsx")
            wb = openpyxl.Workbook()
            ws = wb.active
            ws.title = table_name[:31]  # sheet 名称长度限制

            # 写表头
            for col_idx, header in enumerate(headers, 1):
                cell = ws.cell(row=1, column=col_idx, value=header)
                cell.font = Font(bold=True)
                cell.alignment = Alignment(horizontal='center')

            # 写数据
            for row_idx, row_data in enumerate(data, 2):
                for col_idx, key in enumerate(headers, 1):
                    ws.cell(row=row_idx, column=col_idx, value=row_data.get(key))

            # 自动调整列宽（尝试性，不保证完美）
            for col in ws.columns:
                max_length = 0
                try:
                    col_letter = col[0].column_letter
                except Exception:
                    continue
                for cell in col:
                    try:
                        if cell.value is not None and len(str(cell.value)) > max_length:
                            max_length = len(str(cell.value))
                    except Exception:
                        pass
                adjusted_width = min(max_length + 2, 50)
                ws.column_dimensions[col_letter].width = adjusted_width

            wb.save(excel_path)
            self._info(f"💾 表 {table_name} Excel 已导出到：{excel_path}")
            self._dbg(f"Excel 写入完成：{excel_path}")
        else:
            # 分块导出为多个文件，避免单文件超出 Excel 最大行数限制
            parts = (total_rows + CHUNK_SIZE - 1) // CHUNK_SIZE
            base_name = table_name
            for i in range(parts):
                start = i * CHUNK_SIZE
                end = min(start + CHUNK_SIZE, total_rows)
                part_data = data[start:end]
                part_suffix = f"_part{i+1}"
                excel_path = os.path.join(excel_dir, f"{base_name}{part_suffix}.xlsx")

                wb = openpyxl.Workbook()
                ws = wb.active
                # sheet 名称不能太长
                ws.title = (base_name + part_suffix)[:31]

                # 写表头
                for col_idx, header in enumerate(headers, 1):
                    cell = ws.cell(row=1, column=col_idx, value=header)
                    cell.font = Font(bold=True)
                    cell.alignment = Alignment(horizontal='center')

                # 写块数据
                for row_idx, row_data in enumerate(part_data, 2):
                    for col_idx, key in enumerate(headers, 1):
                        ws.cell(row=row_idx, column=col_idx, value=row_data.get(key))

                # 可选：调整列宽（尝试性）
                for col in ws.columns:
                    max_length = 0
                    try:
                        col_letter = col[0].column_letter
                    except Exception:
                        continue
                    for cell in col:
                        try:
                            if cell.value is not None and len(str(cell.value)) > max_length:
                                max_length = len(str(cell.value))
                        except Exception:
                            pass
                    adjusted_width = min(max_length + 2, 50)
                    ws.column_dimensions[col_letter].width = adjusted_width

                wb.save(excel_path)
                self._info(f"💾 表 {table_name} Excel 分块已导出到：{excel_path}")
                self._dbg(f"Excel 分块写入完成：{excel_path} (rows {start+1}-{end})")

    def batch_process_all_tables(self, export_dir: str):
        """批量处理所有表：查看结构 → 检查数据量 → 导出 CSV + Excel"""
        csv_dir = os.path.join(export_dir, "csv_files")
        excel_dir = os.path.join(export_dir, "excel_files")

        tables = self.get_all_tables()
        if not tables:
            self._info("⚠️  数据库中无用户表")
            return

        self._info("\n========== 开始批量处理所有表 ==========")
        for table in tables:
            self._dbg(f"---------- 处理表：{table} ----------")
            self.get_table_structure(table)
            row_count = self.get_table_row_count(table)
            if row_count > 0:
                self.export_table_to_csv(table, csv_dir)
                self.export_table_to_excel(table, excel_dir)
            else:
                self._dbg(f"表 {table} 无数据，跳过导出")

        self._info("\n========== 所有表处理完成 ==========")
        self._info(f"\n📁 所有导出文件已保存到：")
        self._info(f"   - CSV 文件：{csv_dir}")
        self._info(f"   - Excel 文件：{excel_dir}")


# ===================== 示例用法 =====================
if __name__ == "__main__":
    cli = argparse.ArgumentParser(description="SQLite 表批量导出为 CSV 和 Excel")
    cli.add_argument("db_path", help="SQLite 数据库文件路径 (.db)")
    cli.add_argument("-o", "--out", dest="export_dir", default="./export",
                     help="导出根目录（默认为./export，下会生成 csv_files 和 excel_files 子目录)")
    cli.add_argument("-q", "--quiet", action='store_true', help="仅在终端显示重要信息（详细信息写入日志）")
    cli.add_argument("--log", dest="log_file", default=None, help="日志文件路径（默认 ./db_express.log）")
    args = cli.parse_args()

    DB_FILE_PATH = args.db_path
    EXPORT_ROOT_DIR = args.export_dir

    try:
        parser = SQLiteDBParser(DB_FILE_PATH, verbose=not args.quiet, log_file=args.log_file)
        parser.connect()
        parser.batch_process_all_tables(EXPORT_ROOT_DIR)

    except Exception as e:
        print(f"❌ 解析失败：{e}", file=sys.stderr)
        # 如果 parser 已初始化，记录到日志
        if 'parser' in locals() and getattr(parser, 'logger', None):
            parser.logger.exception("解析失败")
    finally:
        if 'parser' in locals() and getattr(parser, 'conn', None):
            parser.close()