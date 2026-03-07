import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../models/transaction_model.dart';
import '../models/budget_model.dart';
import '../models/category_model.dart';
import '../platform/desktop_config.dart';

// 条件导入：桌面端（Windows/Mac/Linux）导入 sqflite_common_ffi
import 'package:sqflite_common_ffi/sqflite_ffi.dart' if (dart.library.io) '';

/// 数据库帮助类
class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  /// 数据库名称
  static const String _dbName = 'yaccount.db';
  static const int _dbVersion = 1;

  /// 获取数据库实例
  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  /// 初始化数据库
  Future<Database> _initDatabase() async {
    String path;

    if (Platform.isAndroid || Platform.isIOS) {
      // 移动平台使用 path_provider
      final documentsDirectory = await getApplicationDocumentsDirectory();
      path = join(documentsDirectory.path, _dbName);
    } else if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      // 桌面平台使用应用数据目录
      final appDataDir = await getApplicationSupportDirectory();
      path = join(appDataDir.path, _dbName);
    } else {
      // 其他平台使用临时目录
      final tempDir = Directory.systemTemp;
      path = join(tempDir.path, _dbName);
    }

    // 使用全局 databaseFactory（桌面端已在 DesktopConfig 中初始化为 FFI）
    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// 初始化数据库（首次创建）
  Future<void> _onCreate(Database db, int version) async {
    // 创建交易记录表
    await db.execute('''
      CREATE TABLE transactions (
        id TEXT PRIMARY KEY,
        amount REAL NOT NULL,
        type TEXT NOT NULL,
        category TEXT NOT NULL,
        note TEXT,
        date TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    // 创建索引优化查询性能
    await db.execute(
      'CREATE INDEX idx_transaction_date ON transactions(date)',
    );
    await db.execute(
      'CREATE INDEX idx_transaction_type ON transactions(type)',
    );
    await db.execute(
      'CREATE INDEX idx_transaction_category ON transactions(category)',
    );

    // 创建预算表
    await db.execute('''
      CREATE TABLE budgets (
        id TEXT PRIMARY KEY,
        category TEXT NOT NULL,
        amount REAL NOT NULL,
        month INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        UNIQUE(category, month)
      )
    ''');

    // 创建分类表
    await db.execute('''
      CREATE TABLE categories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        icon TEXT NOT NULL,
        color_value INTEGER NOT NULL
      )
    ''');

    // 插入默认分类
    for (final category in DefaultCategories.categories) {
      await db.insert('categories', category.toMap());
    }

    // 创建设置表
    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
  }

  /// 数据库升级
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // 未来版本升级逻辑
  }

  /// 重新初始化数据库
  Future<void> reinitialize() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
    _database = await _initDatabase();
  }

  // ========== 交易记录 CRUD ==========

  /// 插入交易记录
  Future<int> insertTransaction(TransactionModel transaction) async {
    final db = await database;
    return await db.insert('transactions', transaction.toMap());
  }

  /// 批量插入交易记录（使用事务优化性能）
  Future<void> insertTransactionsBatch(List<TransactionModel> transactions) async {
    final db = await database;
    await db.transaction((txn) async {
      for (final transaction in transactions) {
        await txn.insert('transactions', transaction.toMap());
      }
    });
  }

  /// 更新交易记录
  Future<int> updateTransaction(TransactionModel transaction) async {
    final db = await database;
    return await db.update(
      'transactions',
      transaction.toMap(),
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
  }

  /// 删除交易记录
  Future<int> deleteTransaction(String id) async {
    final db = await database;
    return await db.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// 批量删除交易记录
  Future<int> deleteTransactions(List<String> ids) async {
    final db = await database;
    final placeholders = List.filled(ids.length, '?').join(',');
    return await db.delete(
      'transactions',
      where: 'id IN ($placeholders)',
      whereArgs: ids,
    );
  }

  /// 查询所有交易记录（分页）
  Future<List<TransactionModel>> getTransactions({
    int page = 0,
    int pageSize = 20,
    String? type,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await database;
    final where = <String>[];
    final whereArgs = <dynamic>[];

    if (type != null) {
      where.add('type = ?');
      whereArgs.add(type);
    }
    print('数据库查询: where=${where.isNotEmpty ? where.join(' AND ') : '无筛选条件'}, whereArgs=$whereArgs');
    if (startDate != null) {
      where.add('date >= ?');
      whereArgs.add(startDate.toIso8601String().split('T')[0]);
    }
    if (endDate != null) {
      where.add('date <= ?');
      whereArgs.add(endDate.toIso8601String().split('T')[0]);
    }

    // 优化：只查询需要的字段
    final results = await db.query(
      'transactions',
      columns: ['id', 'amount', 'type', 'category', 'note', 'date', 'created_at'],
      where: where.isNotEmpty ? where.join(' AND ') : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'date DESC, created_at DESC',
      limit: pageSize,
      offset: page * pageSize,
    );

    return results.map((map) => TransactionModel.fromMap(map)).toList();
  }

  /// 获取交易记录总数
  Future<int> getTransactionCount({String? type, DateTime? startDate, DateTime? endDate}) async {
    final db = await database;
    final where = <String>[];
    final whereArgs = <dynamic>[];

    if (type != null) {
      where.add('type = ?');
      whereArgs.add(type);
    }
    if (startDate != null) {
      where.add('date >= ?');
      whereArgs.add(startDate.toIso8601String().split('T')[0]);
    }
    if (endDate != null) {
      where.add('date <= ?');
      whereArgs.add(endDate.toIso8601String().split('T')[0]);
    }

    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM transactions${where.isNotEmpty ? ' WHERE ${where.join(' AND ')}' : ''}',
      whereArgs.isNotEmpty ? whereArgs : null,
    );
    return result.first['count'] as int;
  }

  /// 获取今日/本周/本月统计
  Future<Map<String, double>> getStatistics({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final db = await database;
    final start = startDate.toIso8601String().split('T')[0];
    final end = endDate.toIso8601String().split('T')[0];

    final results = await db.rawQuery('''
      SELECT type, SUM(amount) as total
      FROM transactions
      WHERE date >= ? AND date <= ?
      GROUP BY type
    ''', [start, end]);

    final stats = <String, double>{
      'expense': 0,
      'income': 0,
    };

    for (final row in results) {
      final type = row['type'] as String;
      final total = (row['total'] as num?)?.toDouble() ?? 0;
      stats[type] = total;
    }

    return stats;
  }

  /// 获取按分类统计（用于饼图）
  Future<Map<String, double>> getCategoryStatistics({
    required DateTime startDate,
    required DateTime endDate,
    String type = 'expense',
  }) async {
    final db = await database;
    final start = startDate.toIso8601String().split('T')[0];
    final end = endDate.toIso8601String().split('T')[0];

    final results = await db.rawQuery('''
      SELECT category, SUM(amount) as total
      FROM transactions
      WHERE date >= ? AND date <= ? AND type = ?
      GROUP BY category
      ORDER BY total DESC
    ''', [start, end, type]);

    final stats = <String, double>{};
    for (final row in results) {
      final category = row['category'] as String;
      final total = (row['total'] as num?)?.toDouble() ?? 0;
      stats[category] = total;
    }

    return stats;
  }

  /// 获取近N个月的收支对比（用于柱状图）
  Future<List<Map<String, dynamic>>> getMonthlyStatistics(int months) async {
    final db = await database;
    final now = DateTime.now();
    final results = <Map<String, dynamic>>[];

    for (int i = months - 1; i >= 0; i--) {
      final date = DateTime(now.year, now.month - i, 1);
      final start = DateTime(date.year, date.month, 1);
      final end = DateTime(date.year, date.month + 1, 0);

      final stats = await getStatistics(startDate: start, endDate: end);
      results.add({
        'month': date.month,
        'year': date.year,
        'expense': stats['expense'] ?? 0,
        'income': stats['income'] ?? 0,
      });
    }

    return results;
  }

  /// 获取年度统计数据
  Future<Map<String, double>> getYearStatistics() async {
    final now = DateTime.now();
    final start = DateTime(now.year, 1, 1);
    final end = DateTime(now.year + 1, 1, 0);
    return await getStatistics(startDate: start, endDate: end);
  }

  /// 获取当月每日支出趋势（用于折线图）
  Future<Map<String, double>> getDailyExpenseTrend({
    required int year,
    required int month,
  }) async {
    final db = await database;
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 0);

    final results = await db.rawQuery('''
      SELECT date, SUM(amount) as total
      FROM transactions
      WHERE date >= ? AND date <= ? AND type = 'expense'
      GROUP BY date
      ORDER BY date
    ''', [
      start.toIso8601String().split('T')[0],
      end.toIso8601String().split('T')[0],
    ]);

    final trend = <String, double>{};
    for (final row in results) {
      final date = row['date'] as String;
      final total = (row['total'] as num?)?.toDouble() ?? 0;
      trend[date] = total;
    }

    return trend;
  }

  /// 获取年度统计（1-12月）
  Future<List<Map<String, dynamic>>> getYearlyStatistics(int year) async {
    final db = await database;
    final results = <Map<String, dynamic>>[];

    for (int month = 1; month <= 12; month++) {
      final start = DateTime(year, month, 1);
      final end = DateTime(year, month + 1, 0);

      final stats = await getStatistics(
        startDate: start,
        endDate: end,
      );

      results.add({
        'month': '$month月',
        'year': year,
        'monthNum': month,
        'income': stats['income'] ?? 0,
        'expense': stats['expense'] ?? 0,
      });
    }

    return results;
  }

  /// 获取年度月度趋势（用于年度折线图）
  Future<Map<String, double>> getYearlyMonthlyTrend(int year) async {
    final db = await database;
    final start = DateTime(year, 1, 1);
    final end = DateTime(year + 1, 1, 0);

    final results = await db.rawQuery('''
      SELECT strftime('%m', date) as month, SUM(amount) as total
      FROM transactions
      WHERE date >= ? AND date <= ? AND type = 'expense'
      GROUP BY month
      ORDER BY month
    ''', [
      start.toIso8601String().split('T')[0],
      end.toIso8601String().split('T')[0],
    ]);

    final trend = <String, double>{};
    for (final row in results) {
      final month = int.parse(row['month'] as String);
      final total = (row['total'] as num?)?.toDouble() ?? 0;
      trend['${month}月'] = total;
    }

    return trend;
  }

  // ========== 预算 CRUD ==========

  /// 设置预算
  Future<void> setBudget(BudgetModel budget) async {
    final db = await database;
    await db.insert(
      'budgets',
      budget.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// 获取指定月份的预算
  Future<BudgetModel?> getBudget(int month, {String? category}) async {
    final db = await database;
    final results = await db.query(
      'budgets',
      where: category != null ? 'month = ? AND category = ?' : 'month = ? AND category = ?',
      whereArgs: category != null ? [month, category] : [month, 'total'],
    );

    if (results.isEmpty) return null;
    return BudgetModel.fromMap(results.first);
  }

  /// 获取指定月份所有预算
  Future<List<BudgetModel>> getBudgets(int month) async {
    final db = await database;
    final results = await db.query(
      'budgets',
      where: 'month = ?',
      whereArgs: [month],
    );

    return results.map((map) => BudgetModel.fromMap(map)).toList();
  }

  /// 删除预算
  Future<int> deleteBudget(String id) async {
    final db = await database;
    return await db.delete(
      'budgets',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ========== 设置 CRUD ==========

  /// 保存设置
  Future<void> setSetting(String key, String value) async {
    final db = await database;
    await db.insert(
      'settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// 获取设置
  Future<String?> getSetting(String key) async {
    final db = await database;
    final results = await db.query(
      'settings',
      where: 'key = ?',
      whereArgs: [key],
    );

    if (results.isEmpty) return null;
    return results.first['value'] as String;
  }

  /// 删除所有数据
  Future<void> deleteAllData() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('transactions');
      await txn.delete('budgets');
    });
  }

  /// 关闭数据库
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
