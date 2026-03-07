import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../database/database_helper.dart';
import '../models/budget_model.dart';

/// 预算数据Provider
class BudgetProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper();
  final Uuid _uuid = const Uuid();

  List<BudgetModel> _budgets = [];
  BudgetModel? _totalBudget;
  bool _isLoading = false;

  List<BudgetModel> get budgets => _budgets;
  BudgetModel? get totalBudget => _totalBudget;
  bool get isLoading => _isLoading;

  /// 获取当前月份
  int get currentMonth {
    final now = DateTime.now();
    return now.year * 100 + now.month;
  }

  /// 初始化并加载预算
  Future<void> initialize() async {
    await loadBudgets(currentMonth);
  }

  /// 加载指定月份的预算
  Future<void> loadBudgets(int month) async {
    _isLoading = true;
    notifyListeners();

    try {
      _budgets = await _db.getBudgets(month);
      _totalBudget = _budgets.where((b) => b.category == 'total').firstOrNull;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 设置总预算
  Future<void> setTotalBudget(double amount, int month) async {
    final existing = _budgets.where((b) => b.category == 'total').firstOrNull;

    final budget = BudgetModel(
      id: existing?.id ?? _uuid.v4(),
      category: 'total',
      amount: amount,
      month: month,
      createdAt: existing?.createdAt ?? DateTime.now(),
    );

    await _db.setBudget(budget);
    await loadBudgets(month);
  }

  /// 设置分类预算
  Future<void> setCategoryBudget(String category, double amount, int month) async {
    final existing = _budgets.where((b) => b.category == category).firstOrNull;

    final budget = BudgetModel(
      id: existing?.id ?? _uuid.v4(),
      category: category,
      amount: amount,
      month: month,
      createdAt: existing?.createdAt ?? DateTime.now(),
    );

    await _db.setBudget(budget);
    await loadBudgets(month);
  }

  /// 删除预算
  Future<void> deleteBudget(String id) async {
    await _db.deleteBudget(id);
    await loadBudgets(currentMonth);
  }

  /// 计算预算使用率
  double calculateUsageRate(double spent, double? budget) {
    if (budget == null || budget <= 0) return 0;
    return (spent / budget * 100).clamp(0, 100);
  }

  /// 获取预算使用率颜色
  /// <70% 绿色, 70-90% 黄色, >90% 红色
  int getUsageColor(double rate) {
    if (rate < 70) return 0xFF00B894; // 绿色
    if (rate < 90) return 0xFFFDCB6E; // 黄色
    return 0xFFE17055; // 红色
  }
}
