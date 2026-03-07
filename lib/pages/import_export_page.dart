import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../providers/transaction_provider.dart';
import '../models/transaction_model.dart';
import '../models/category_model.dart';
import '../utils/constants.dart';

/// 导入导出页面
class ImportExportPage extends StatefulWidget {
  const ImportExportPage({super.key});

  @override
  State<ImportExportPage> createState() => _ImportExportPageState();
}

class _ImportExportPageState extends State<ImportExportPage> {
  bool _isExporting = false;
  bool _isImporting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: const Text('导入导出'),
        backgroundColor: Colors.white,
        foregroundColor: AppConstants.textPrimary,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection(
            title: '导出数据',
            icon: Icons.upload_file,
            children: [
              _ActionTile(
                icon: Icons.table_chart,
                title: '导出为 CSV',
                subtitle: '通用格式，支持大多数软件打开',
                onTap: _exportCsv,
                isLoading: _isExporting,
              ),
              _ActionTile(
                icon: Icons.grid_on,
                title: '导出为 Excel',
                subtitle: '更适合数据分析和处理',
                onTap: _exportExcel,
                isLoading: _isExporting,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSection(
            title: '导入数据',
            icon: Icons.download,
            children: [
              _ActionTile(
                icon: Icons.file_open,
                title: '从 CSV 导入',
                subtitle: '导入 CSV 格式的账本数据',
                onTap: _importCsv,
                isLoading: _isImporting,
              ),
              _ActionTile(
                icon: Icons.table_rows,
                title: '从 Excel 导入',
                subtitle: '导入 Excel 格式的账本数据',
                onTap: _importExcel,
                isLoading: _isImporting,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildDangerSection(),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, color: const Color(0xFF3C8488)),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDangerSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.warning, color: Colors.red),
                SizedBox(width: 8),
                Text(
                  '危险操作',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text('清空所有数据'),
            subtitle: const Text('此操作不可恢复'),
            onTap: _showDeleteAllDialog,
          ),
        ],
      ),
    );
  }

  Future<void> _exportCsv() async {
    setState(() => _isExporting = true);
    try {
      final provider = context.read<TransactionProvider>();
      final transactions = await provider.getAllTransactions();

      if (transactions.isEmpty) {
        _showMessage('没有数据可导出');
        return;
      }

      final csvData = [
        ['日期', '类型', '分类', '金额', '备注'],
        ...transactions.map((t) => [
              DateFormat('yyyy-MM-dd').format(t.date),
              t.type == 'expense' ? '支出' : '收入',
              _getCategoryName(t.category),
              t.amount.toString(),
              t.note ?? '',
            ]),
      ];

      final csv = const ListToCsvConverter().convert(csvData);
      // 添加 BOM (Byte Order Mark) 以解决 Windows Excel 中文乱码问题
      final csvWithBom = '\uFEFF$csv';

      final dateStr = DateFormat('yyyyMMdd').format(DateTime.now());
      await _showExportOptions(csvWithBom, '${dateStr}_账本导出.csv', 'CSV', isText: true);
    } catch (e) {
      _showMessage('导出失败: $e');
    } finally {
      setState(() => _isExporting = false);
    }
  }

  Future<void> _exportExcel() async {
    setState(() => _isExporting = true);
    try {
      final provider = context.read<TransactionProvider>();
      final transactions = await provider.getAllTransactions();

      if (transactions.isEmpty) {
        _showMessage('没有数据可导出');
        return;
      }

      final excel = Excel.createExcel();
      excel.delete('Sheet1');
      final sheet = excel['账本'];

      // 添加表头
      sheet.appendRow([
        TextCellValue('日期'),
        TextCellValue('类型'),
        TextCellValue('分类'),
        TextCellValue('金额'),
        TextCellValue('备注'),
      ]);

      // 添加数据
      for (final t in transactions) {
        sheet.appendRow([
          TextCellValue(DateFormat('yyyy-MM-dd').format(t.date)),
          TextCellValue(t.type == 'expense' ? '支出' : '收入'),
          TextCellValue(_getCategoryName(t.category)),
          DoubleCellValue(t.amount),
          TextCellValue(t.note ?? ''),
        ]);
      }

      final bytes = excel.encode();
      if (bytes == null) throw Exception('编码失败');

      final dateStr = DateFormat('yyyyMMdd').format(DateTime.now());
      await _showExportOptions(bytes, '${dateStr}_账本导出.xlsx', 'Excel', isText: false);
    } catch (e) {
      _showMessage('导出失败: $e');
    } finally {
      setState(() => _isExporting = false);
    }
  }

  Future<void> _importCsv() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );

    if (result == null) return;

    setState(() => _isImporting = true);
    try {
      final file = File(result.files.single.path!);
      final csv = await file.readAsString();
      final rows = const CsvToListConverter().convert(csv);

      if (rows.isEmpty) {
        _showMessage('文件为空');
        return;
      }

      await _showImportModeDialog(() => _processImport(rows));
    } catch (e) {
      _showMessage('导入失败: $e');
    } finally {
      setState(() => _isImporting = false);
    }
  }

  Future<void> _importExcel() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls'],
    );

    if (result == null) return;

    setState(() => _isImporting = true);
    try {
      final file = File(result.files.single.path!);
      final bytes = await file.readAsBytes();
      final excel = Excel.decodeBytes(bytes);
      final sheet = excel.tables.values.first;

      if (sheet.rows.isEmpty) {
        _showMessage('文件为空');
        return;
      }

      final rows = sheet.rows.map((row) {
        return row.map((cell) => cell?.value?.toString() ?? '').toList();
      }).toList();

      await _showImportModeDialog(() => _processImport(rows));
    } catch (e) {
      _showMessage('导入失败: $e');
    } finally {
      setState(() => _isImporting = false);
    }
  }

  Future<void> _processImport(List<List<dynamic>> rows) async {
    final uuid = const Uuid();
    final transactions = <TransactionModel>[];

    // 跳过表头
    for (int i = 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.length < 4) continue;

      try {
        final date = DateTime.tryParse(row[0].toString()) ?? DateTime.now();
        final type = row[1].toString() == '支出' ? 'expense' : 'income';
        final category = row[2].toString();
        final amount = double.tryParse(row[3].toString()) ?? 0;
        final note = row.length > 4 ? row[4].toString() : null;

        if (amount > 0) {
          transactions.add(TransactionModel(
            id: uuid.v4(),
            amount: amount,
            type: type,
            category: _mapCategory(category),
            note: note,
            date: date,
            createdAt: DateTime.now(),
          ));
        }
      } catch (e) {
        // 跳过无效行
      }
    }

    if (transactions.isEmpty) {
      _showMessage('没有有效数据可导入');
      return;
    }

    await context.read<TransactionProvider>().importTransactions(transactions);
    _showMessage('成功导入 ${transactions.length} 条记录');
  }

  String _mapCategory(String category) {
    final mapping = {
      // 支出分类
      '餐饮': 'food',
      '交通': 'transport',
      '消费': 'shopping',
      '医疗': 'medical',
      '其他': 'other',
      // 收入分类
      '生活费': 'living',
      '薪水': 'salary',
      '投资': 'investment',
      '收入其他': 'income_other',
    };
    return mapping[category] ?? category;
  }

  String _getCategoryName(String categoryId) {
    final category = DefaultCategories.categories
        .where((c) => c.id == categoryId)
        .firstOrNull;
    return category?.name ?? categoryId;
  }

  Future<void> _showImportModeDialog(Future<void> Function() onImport) async {
    final mode = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('导入模式'),
        content: const Text('请选择导入模式：'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'cancel'),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, 'merge'),
            child: const Text('增量追加'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, 'replace'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('覆盖替换'),
          ),
        ],
      ),
    );

    if (mode == 'replace') {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('确认覆盖'),
          content: const Text('此操作将删除现有数据，是否继续？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('确认'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;
    }

    await onImport();
  }

  Future<File> _saveFile(String content, String filename) async {
    final dir = await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$filename');
    await file.writeAsString(content, encoding: utf8);
    return file;
  }

  Future<File> _saveFileBytes(List<int> bytes, String filename) async {
    final dir = await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$filename');
    await file.writeAsBytes(bytes);
    return file;
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF00B894),
      ),
    );
  }

  Future<void> _showExportOptions(dynamic data, String filename, String type, {required bool isText}) async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('导出'),
        content: const Text('请选择导出方式:'),
        actions: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context, 'save'),
                  icon: const Icon(Icons.save),
                  label: const Text('保存到本地'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00B894),
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(context, 'cancel'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF00B894),
                ),
                child: const Text('取消'),
              ),
            ],
          ),
        ],
      ),
    );

    if (result == 'cancel') return;

    try {
      if (result == 'save') {
        // 保存到本地
        File file;
        if (isText) {
          file = await _saveFile(data as String, filename);
        } else {
          file = await _saveFileBytes(data as List<int>, filename);
        }
        _showMessage('文件已保存到: ${file.path}');
      }
    } catch (e) {
      _showMessage('操作失败: $e');
    }
  }

  void _showDeleteAllDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认清空'),
        content: const Text(
          '此操作将永久删除所有账目数据，且不可恢复！\n\n请输入 "确认删除" 以确认操作。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      _showMessage('数据已清空');
    }
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isLoading;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: isLoading
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(icon, color: const Color(0xFF3C8488)),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: isLoading ? null : onTap,
    );
  }
}
