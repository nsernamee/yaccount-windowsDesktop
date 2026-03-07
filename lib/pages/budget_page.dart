import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/budget_provider.dart';
import '../utils/constants.dart';
import '../utils/date_utils.dart';
import '../widgets/common_widgets.dart';
import '../models/budget_model.dart';

/// 预算管理页面
class BudgetPage extends StatefulWidget {
  const BudgetPage({super.key});

  @override
  State<BudgetPage> createState() => _BudgetPageState();
}

class _BudgetPageState extends State<BudgetPage> {
  late int _selectedMonth;

  @override
  void initState() {
    super.initState();
    _selectedMonth = context.read<BudgetProvider>().currentMonth;
    context.read<BudgetProvider>().loadBudgets(_selectedMonth);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: const Text('预算管理'),
        backgroundColor: Colors.white,
        foregroundColor: AppConstants.textPrimary,
        elevation: 0,
      ),
      body: Consumer3<BudgetProvider, TransactionProvider, CurrencyManager>(
        builder: (context, budgetProvider, transactionProvider, currencyManager, _) {
          final monthStats = transactionProvider.monthStats;
          final spent = monthStats['expense'] ?? 0;
          final totalBudget = budgetProvider.totalBudget;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildMonthSelector(),
                const SizedBox(height: 20),
                _buildTotalBudgetCard(spent, totalBudget?.amount ?? 0, budgetProvider, currencyManager),
                const SizedBox(height: 20),
                _buildCategoryBudgets(spent, budgetProvider, transactionProvider),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddBudgetDialog(context),
        backgroundColor: const Color(0xFF9EE1D8),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildMonthSelector() {
    final date = AppDateUtils.fromMonthInt(_selectedMonth);
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () {
              setState(() {
                _selectedMonth = DateTime(
                  _selectedMonth ~/ 100,
                  _selectedMonth % 100 - 1,
                ).year * 100 +
                    DateTime(
                      _selectedMonth ~/ 100,
                      _selectedMonth % 100 - 1,
                    ).month;
              });
              context.read<BudgetProvider>().loadBudgets(_selectedMonth);
            },
          ),
          Text(
            AppDateUtils.formatMonth(AppDateUtils.fromMonthInt(_selectedMonth)),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _selectedMonth < context.read<BudgetProvider>().currentMonth
                ? () {
                    setState(() {
                      _selectedMonth = DateTime(
                        _selectedMonth ~/ 100,
                        _selectedMonth % 100 + 1,
                      ).year * 100 +
                          DateTime(
                            _selectedMonth ~/ 100,
                            _selectedMonth % 100 + 1,
                          ).month;
                    });
                    context.read<BudgetProvider>().loadBudgets(_selectedMonth);
                  }
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildTotalBudgetCard(
    double spent,
    double budget,
    BudgetProvider provider,
    CurrencyManager currencyManager,
  ) {
    final rate = provider.calculateUsageRate(spent, budget);
    final color = Color(provider.getUsageColor(rate));
    final symbol = currencyManager.current.symbol;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3C8488), Color(0xFF9EE1D8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '总预算',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                budget > 0 ? _formatBudgetAmount(budget, symbol) : '未设置',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(          ),
          const Spacer(),
          if (budget > 0) ...[
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.white),
              onPressed: () => _showEditTotalBudgetDialog(context, budget),
              tooltip: '编辑总预算',
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${rate.toStringAsFixed(1)}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
      if (budget > 0) ...[
            const SizedBox(height: 16),
            BudgetProgressBar(spent: spent, budget: budget),
            const SizedBox(height: 8),
            Text(
              '已花费 ${spent.toStringAsFixed(2)} $symbol，剩余 ${(budget - spent).toStringAsFixed(2)} $symbol',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCategoryBudgets(double totalSpent, BudgetProvider provider, TransactionProvider transactionProvider) {
    final categoryBudgets = provider.budgets.where((b) => b.category != 'total');

    // 获取当前月份的开始和结束日期
    final now = AppDateUtils.fromMonthInt(_selectedMonth);
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 0);

    return Consumer<CurrencyManager>(
      builder: (context, currencyManager, _) {
        final symbol = currencyManager.current.symbol;
        return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '分类预算',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        if (categoryBudgets.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Text(
                '点击右下角按钮添加分类预算',
                style: TextStyle(color: AppConstants.textSecondary),
              ),
            ),
          )
        else
          FutureBuilder<Map<String, double>>(
            future: transactionProvider.getCategoryStats(
              startDate: monthStart,
              endDate: monthEnd,
              type: 'expense',
            ),
            builder: (context, snapshot) {
              final categoryStats = snapshot.data ?? {};

              return Column(
                children: categoryBudgets.map((budget) {
                  // 计算该分类已花费
                  final spent = categoryStats[budget.category] ?? 0.0;
                  final rate = provider.calculateUsageRate(spent, budget.amount);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                _getCategoryName(budget.category),
                                style: const TextStyle(fontWeight: FontWeight.w500),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Color(provider.getUsageColor(rate)).withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${rate.toStringAsFixed(1)}%',
                                style: TextStyle(
                                  color: Color(provider.getUsageColor(rate)),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _formatBudgetAmount(budget.amount, symbol),
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 2),
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 20),
                              onPressed: () => _showEditCategoryBudgetDialog(context, budget),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 20),
                              onPressed: () => _deleteBudget(budget.id),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        BudgetProgressBar(spent: spent, budget: budget.amount),
                        const SizedBox(height: 4),
                        Text(
                          '已花费 ${spent.toStringAsFixed(2)} $symbol，剩余 ${(budget.amount - spent).toStringAsFixed(2)} $symbol',
                          style: const TextStyle(color: AppConstants.textSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      );
    },
    );
  }

  String _getCategoryName(String categoryId) {
    final categories = {
      'food': '餐饮',
      'transport': '交通',
      'shopping': '消费',
      'medical': '医疗',
    };
    return categories[categoryId] ?? categoryId;
  }

  void _showAddBudgetDialog(BuildContext context) {
    final isTotal = context.read<BudgetProvider>().totalBudget == null;

    showDialog(
      context: context,
      builder: (context) => _AddBudgetDialog(
        month: _selectedMonth,
        isTotal: isTotal,
      ),
    );
  }

  void _showEditTotalBudgetDialog(BuildContext context, double currentBudget) {
    showDialog(
      context: context,
      builder: (context) => _EditTotalBudgetDialog(
        month: _selectedMonth,
        currentBudget: currentBudget,
      ),
    );
  }

  void _showEditCategoryBudgetDialog(BuildContext context, BudgetModel budget) {
    showDialog(
      context: context,
      builder: (context) => _EditCategoryBudgetDialog(
        month: _selectedMonth,
        budget: budget,
      ),
    );
  }

  Future<void> _deleteBudget(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除这个预算吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await context.read<BudgetProvider>().deleteBudget(id);
    }
  }

  /// 预算金额格式化，超过1亿使用Y（亿）
  String _formatBudgetAmount(double amount, String symbol) {
    if (amount.abs() >= 100000000) {
      return '${(amount / 100000000).toStringAsFixed(2)}Y $symbol';
    }
    return '${AppConstants.formatAmount(amount)} $symbol';
  }
}

class _AddBudgetDialog extends StatefulWidget {
  final int month;
  final bool isTotal;

  const _AddBudgetDialog({required this.month, required this.isTotal});

  @override
  State<_AddBudgetDialog> createState() => _AddBudgetDialogState();
}

class _AddBudgetDialogState extends State<_AddBudgetDialog> {
  final _amountController = TextEditingController();
  String _selectedCategory = 'food';

  final _categories = ['food', 'transport', 'shopping', 'medical'];

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.isTotal ? '设置总预算' : '添加分类预算'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Consumer<CurrencyManager>(
            builder: (context, currencyManager, _) {
              return TextField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: '金额',
                  prefixText: '${currencyManager.current.symbol} ',
                ),
              );
            },
          ),
          if (!widget.isTotal) ...[
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(labelText: '分类'),
              items: _categories.map((c) {
                return DropdownMenuItem(
                  value: c,
                  child: Text(_getCategoryName(c)),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedCategory = value!);
              },
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(foregroundColor: const Color(0xFF00B894)),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: _saveBudget,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00B894),
            foregroundColor: Colors.white,
          ),
          child: const Text('保存'),
        ),
      ],
    );
  }

  String _getCategoryName(String categoryId) {
    final categories = {
      'food': '餐饮',
      'transport': '交通',
      'shopping': '消费',
      'medical': '医疗',
    };
    return categories[categoryId] ?? categoryId;
  }

  Future<void> _saveBudget() async {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入有效金额'), backgroundColor: Color(0xFFE17055)),
      );
      return;
    }

    final provider = context.read<BudgetProvider>();

    if (widget.isTotal) {
      await provider.setTotalBudget(amount, widget.month);
    } else {
      await provider.setCategoryBudget(_selectedCategory, amount, widget.month);
    }

    if (mounted) Navigator.pop(context);
  }
}

class _EditTotalBudgetDialog extends StatefulWidget {
  final int month;
  final double currentBudget;

  const _EditTotalBudgetDialog({required this.month, required this.currentBudget});

  @override
  State<_EditTotalBudgetDialog> createState() => _EditTotalBudgetDialogState();
}

class _EditTotalBudgetDialogState extends State<_EditTotalBudgetDialog> {
  late final TextEditingController _amountController;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.currentBudget.toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('编辑总预算'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Consumer<CurrencyManager>(
            builder: (context, currencyManager, _) {
              return TextField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: '金额',
                  prefixText: '${currencyManager.current.symbol} ',
                ),
              );
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(foregroundColor: const Color(0xFF00B894)),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: _saveBudget,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00B894),
            foregroundColor: Colors.white,
          ),
          child: const Text('保存'),
        ),
      ],
    );
  }

  Future<void> _saveBudget() async {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入有效金额'), backgroundColor: Color(0xFFE17055)),
      );
      return;
    }

    await context.read<BudgetProvider>().setTotalBudget(amount, widget.month);

    if (mounted) Navigator.pop(context);
  }
}

class _EditCategoryBudgetDialog extends StatefulWidget {
  final int month;
  final BudgetModel budget;

  const _EditCategoryBudgetDialog({required this.month, required this.budget});

  @override
  State<_EditCategoryBudgetDialog> createState() => _EditCategoryBudgetDialogState();
}

class _EditCategoryBudgetDialogState extends State<_EditCategoryBudgetDialog> {
  late final TextEditingController _amountController;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.budget.amount.toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  String _getCategoryName(String categoryId) {
    final categories = {
      'food': '餐饮',
      'transport': '交通',
      'shopping': '消费',
      'medical': '医疗',
    };
    return categories[categoryId] ?? categoryId;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('编辑 ${_getCategoryName(widget.budget.category)} 预算'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Consumer<CurrencyManager>(
            builder: (context, currencyManager, _) {
              return TextField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: '金额',
                  prefixText: '${currencyManager.current.symbol} ',
                ),
              );
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(foregroundColor: const Color(0xFF00B894)),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: _saveBudget,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00B894),
            foregroundColor: Colors.white,
          ),
          child: const Text('保存'),
        ),
      ],
    );
  }

  Future<void> _saveBudget() async {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入有效金额'), backgroundColor: Color(0xFFE17055)),
      );
      return;
    }

    await context.read<BudgetProvider>().setCategoryBudget(
          widget.budget.category,
          amount,
          widget.month,
        );

    if (mounted) Navigator.pop(context);
  }
}


