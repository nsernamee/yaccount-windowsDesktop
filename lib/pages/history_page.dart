import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../providers/transaction_provider.dart';
import '../models/transaction_model.dart';
import '../utils/constants.dart';
import '../utils/date_utils.dart';
import '../widgets/category_selector.dart';
import '../widgets/common_widgets.dart';

/// 历史记录页面
class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final ScrollController _scrollController = ScrollController();
  String _filterType = 'all'; // 使用 'all' 而不是 null
  DateTime? _startDate;
  DateTime? _endDate;
  String _timeFilterText = '全部';

  // 获取可选的年份列表（从2020到当前年份）
  List<int> get _availableYears {
    final currentYear = DateTime.now().year;
    return List.generate(currentYear - 2019, (i) => currentYear - i);
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TransactionProvider>().loadTransactions(
        refresh: true,
        filterType: _filterType,
        startDate: _startDate,
        endDate: _endDate,
      );
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<TransactionProvider>().loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: const Text('历史记录'),
        backgroundColor: Colors.white,
        foregroundColor: AppConstants.textPrimary,
        elevation: 0,
        actions: [
          // 类型筛选按钮
          PopupMenuButton<String>(
            key: ValueKey(_filterType),
            icon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.filter_list),
                if (_filterType != 'all')
                  Container(
                    margin: const EdgeInsets.only(left: 4),
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFF3C8488),
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
            onSelected: (value) {
              setState(() => _filterType = value);
              _loadData();
            },
            itemBuilder: (context) => [
              _buildPopupMenuItem('all', '全部', _filterType),
              _buildPopupMenuItem('expense', '仅支出', _filterType),
              _buildPopupMenuItem('income', '仅收入', _filterType),
            ],
          ),
          // 时间筛选按钮
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.date_range),
                if (_startDate != null || _endDate != null)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF3C8488),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: () => _showDateRangePicker(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Consumer<TransactionProvider>(
        builder: (context, provider, _) {
          if (provider.transactions.isEmpty && !provider.isLoading) {
            return const EmptyState(
              icon: Icons.receipt_long,
              message: '暂无记录\n添加你的第一笔账目吧',
            );
          }

          return RefreshIndicator(
            onRefresh: () => provider.loadTransactions(
              refresh: true,
              filterType: _filterType,
              startDate: _startDate,
              endDate: _endDate,
            ),
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: provider.transactions.length + (provider.hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == provider.transactions.length) {
                  return LoadMoreIndicator(
                    isLoading: provider.isLoading,
                    hasMore: provider.hasMore,
                  );
                }

                final transaction = provider.transactions[index];
                final showDateHeader = index == 0 ||
                    !AppDateUtils.isSameDay(
                      transaction.date,
                      provider.transactions[index - 1].date,
                    );

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (showDateHeader)
                      Padding(
                        padding: const EdgeInsets.only(top: 16, bottom: 8),
                        child: Text(
                          AppDateUtils.getRelativeDate(transaction.date),
                          style: const TextStyle(
                            color: AppConstants.textSecondary,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    _TransactionItem(
                      transaction: transaction,
                      onDelete: () => _deleteTransaction(transaction),
                      onEdit: () => _editTransaction(transaction),
                    ),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }

  Future<void> _deleteTransaction(TransactionModel transaction) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除这条记录吗？'),
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
      await context.read<TransactionProvider>().deleteTransaction(transaction.id);
    }
  }

  void _editTransaction(TransactionModel transaction) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditTransactionSheet(transaction: transaction),
    );
  }

  // 辅助方法：构建类型筛选菜单项
  PopupMenuItem<String> _buildPopupMenuItem(String value, String text, String currentValue) {
    final isSelected = value == currentValue;
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          if (isSelected)
            const Icon(Icons.check, size: 18, color: Color(0xFF3C8488))
          else
            const SizedBox(width: 18),
          const SizedBox(width: 8),
          Text(text),
        ],
      ),
    );
  }

  // 显示日期范围选择器
  Future<void> _showDateRangePicker(BuildContext context) async {
    final now = DateTime.now();
    final currentYear = now.year;
    int initialYear = _startDate?.year ?? currentYear;
    int initialMonth = _startDate?.month ?? now.month;

    // result: null=取消, 0=清除筛选, -1=全年, 其他=选择月份
    // 同时返回选中的年份（通过回调获取）
    final result = await showModalBottomSheet<Map<String, int?>>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _DateFilterSheet(
        initialYear: initialYear,
        initialMonth: initialMonth,
        startDate: _startDate,
        endDate: _endDate,
      ),
    );

    if (result != null && mounted) {
      final type = result['type']; // null=取消, 0=清除, -1=全年, 其他=月份
      final selectedYear = result['year'] ?? currentYear;

      setState(() {
        if (type == 0) {
          // 清除筛选
          _startDate = null;
          _endDate = null;
          _timeFilterText = '全部';
        } else if (type == -1) {
          // 选择年份（全年）
          _startDate = DateTime(selectedYear, 1, 1);
          _endDate = DateTime(selectedYear, 12, 31);
          _timeFilterText = '${selectedYear}年';
        } else if (type != null) {
          // 选择月份
          final month = type;
          _startDate = DateTime(selectedYear, month, 1);
          _endDate = DateTime(selectedYear, month + 1, 0);
          _timeFilterText = '${selectedYear}年$month月';
        }
      });
      _loadData();
    }
  }

  // 加载数据
  void _loadData() {
    context.read<TransactionProvider>().loadTransactions(
      refresh: true,
      filterType: _filterType,
      startDate: _startDate,
      endDate: _endDate,
    );
  }
}

/// 日期筛选底部弹窗
class _DateFilterSheet extends StatefulWidget {
  final int initialYear;
  final int initialMonth;
  final DateTime? startDate;
  final DateTime? endDate;

  const _DateFilterSheet({
    required this.initialYear,
    required this.initialMonth,
    this.startDate,
    this.endDate,
  });

  @override
  State<_DateFilterSheet> createState() => _DateFilterSheetState();
}

class _DateFilterSheetState extends State<_DateFilterSheet> {
  late int _selectedYear;
  late int _selectedMonth;

  @override
  void initState() {
    super.initState();
    _selectedYear = widget.initialYear;
    _selectedMonth = widget.initialMonth;
  }

  List<int> get _availableYears {
    final currentYear = DateTime.now().year;
    return List.generate(currentYear - 2019, (i) => currentYear - i);
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final currentYear = now.year;
    final isCurrentYear = _selectedYear == currentYear;
    final maxMonth = isCurrentYear ? now.month : 12;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 顶部标题
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey[200]!),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '选择时间',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (widget.startDate != null || widget.endDate != null)
                  TextButton(
                    onPressed: () => Navigator.pop(context, {'type': 0, 'year': null}),
                    child: const Text(
                      '清除筛选',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
              ],
            ),
          ),
          // 年月选择器
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // 年份选择
                Expanded(
                  child: Container(
                    height: 150,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListView.builder(
                      itemCount: _availableYears.length,
                      itemBuilder: (context, index) {
                        final year = _availableYears[index];
                        final isSelected = year == _selectedYear;
                        return InkWell(
                          onTap: () {
                            setState(() {
                              _selectedYear = year;
                              if (_selectedMonth > (year == currentYear ? now.month : 12)) {
                                _selectedMonth = year == currentYear ? now.month : 12;
                              }
                            });
                          },
                          child: Container(
                            alignment: Alignment.center,
                            color: isSelected ? const Color(0xFF3C8488).withValues(alpha: 0.1) : null,
                            child: Text(
                              '${year}年',
                              style: TextStyle(
                                color: isSelected ? const Color(0xFF3C8488) : null,
                                fontWeight: isSelected ? FontWeight.bold : null,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // 月份选择
                Expanded(
                  child: Container(
                    height: 150,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListView.builder(
                      itemCount: maxMonth,
                      itemBuilder: (context, index) {
                        final month = index + 1;
                        final isSelected = month == _selectedMonth;
                        return InkWell(
                          onTap: () {
                            setState(() {
                              _selectedMonth = month;
                            });
                          },
                          child: Container(
                            alignment: Alignment.center,
                            color: isSelected ? const Color(0xFF3C8488).withValues(alpha: 0.1) : null,
                            child: Text(
                              '${month}月',
                              style: TextStyle(
                                color: isSelected ? const Color(0xFF3C8488) : null,
                                fontWeight: isSelected ? FontWeight.bold : null,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          // 快捷选项
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, {'type': -1, 'year': _selectedYear}),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[200],
                      foregroundColor: AppConstants.textPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('全年'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, {'type': _selectedMonth, 'year': _selectedYear}),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3C8488),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('确认'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _TransactionItem extends StatefulWidget {
  final TransactionModel transaction;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const _TransactionItem({
    required this.transaction,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  State<_TransactionItem> createState() => _TransactionItemState();
}

class _TransactionItemState extends State<_TransactionItem> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final isExpense = widget.transaction.type == 'expense';
    final color = isExpense ? AppConstants.expenseColor : AppConstants.incomeColor;

    return Slidable(
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            onPressed: (_) => widget.onEdit(),
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            icon: Icons.edit,
            label: '编辑',
          ),
          SlidableAction(
            onPressed: (_) => widget.onDelete(),
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            icon: Icons.delete,
            label: '删除',
          ),
        ],
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CategoryIcon(categoryId: widget.transaction.category),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getCategoryName(widget.transaction.category),
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 16,
                          ),
                        ),
                        if (widget.transaction.note != null && widget.transaction.note!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              widget.transaction.note!,
                              style: const TextStyle(
                                color: AppConstants.textSecondary,
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Text(
                    '${isExpense ? '-' : '+'}¥${AppConstants.formatAmountRaw(widget.transaction.amount)}',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      setState(() => _isExpanded = !_isExpanded);
                    },
                    child: Icon(
                      _isExpanded ? Icons.visibility : Icons.visibility_outlined,
                      size: 20,
                      color: AppConstants.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (_isExpanded)
              Container(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow('金额', '${AppConstants.formatAmountRaw(widget.transaction.amount)} ${context.read<CurrencyManager>().current.symbol}'),
                    const SizedBox(height: 8),
                    _buildDetailRow('类型', isExpense ? '支出' : '收入'),
                    const SizedBox(height: 8),
                    _buildDetailRow('分类', _getCategoryName(widget.transaction.category)),
                    const SizedBox(height: 8),
                    _buildDetailRow('日期', AppDateUtils.formatChineseDate(widget.transaction.date)),
                    if (widget.transaction.note != null && widget.transaction.note!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _buildDetailRow('备注', widget.transaction.note!, isMultiline: true),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isMultiline = false}) {
    return Row(
      crossAxisAlignment: isMultiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 50,
          child: Text(
            label,
            style: const TextStyle(
              color: AppConstants.textSecondary,
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: AppConstants.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
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
      'other': '其他',
      'living': '生活费',
      'salary': '薪水',
      'investment': '投资',
      'income_other': '其他',
    };
    return categories[categoryId] ?? '其他';
  }
}

/// 编辑交易页面
class _EditTransactionSheet extends StatefulWidget {
  final TransactionModel transaction;

  const _EditTransactionSheet({required this.transaction});

  @override
  State<_EditTransactionSheet> createState() => _EditTransactionSheetState();
}

class _EditTransactionSheetState extends State<_EditTransactionSheet> {
  late String _transactionType;
  late TextEditingController _amountController;
  late TextEditingController _noteController;
  late String _selectedCategory;
  late DateTime _selectedDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _transactionType = widget.transaction.type;
    _amountController = TextEditingController(
      text: widget.transaction.amount.toString(),
    );
    _noteController = TextEditingController(text: widget.transaction.note ?? '');
    _selectedCategory = widget.transaction.category;
    _selectedDate = widget.transaction.date;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(20),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '编辑记录',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildAmountInput(),
            const SizedBox(height: 20),
            _buildDateSelector(),
            const SizedBox(height: 20),
            _buildCategorySelector(),
            const SizedBox(height: 20),
            _buildNoteInput(),
            const SizedBox(height: 24),
            _buildSaveButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountInput() {
    return     Consumer<CurrencyManager>(
      builder: (context, currencyManager, _) {
        return TextField(
          controller: _amountController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: '金额',
            prefixText: '${currencyManager.current.symbol} ',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      },
    );
  }

  Widget _buildDateSelector() {
    return GestureDetector(
      onTap: _selectDate,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today),
            const SizedBox(width: 12),
            Text(AppDateUtils.formatChineseDate(_selectedDate)),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Widget _buildCategorySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('分类', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        CategorySelector(
          selectedCategory: _selectedCategory,
          transactionType: _transactionType,
          onCategorySelected: (c) => setState(() => _selectedCategory = c),
        ),
      ],
    );
  }

  Widget _buildNoteInput() {
    return TextField(
      controller: _noteController,
      maxLines: 2,
      decoration: InputDecoration(
        labelText: '备注',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveTransaction,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppConstants.primaryColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text('保存修改', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
      ),
    );
  }

  Future<void> _saveTransaction() async {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入有效金额'), backgroundColor: Color(0xFFE17055)),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final updated = widget.transaction.copyWith(
        amount: amount,
        type: _transactionType,
        category: _selectedCategory,
        note: _noteController.text.isEmpty ? null : _noteController.text,
        date: _selectedDate,
      );

      await context.read<TransactionProvider>().updateTransaction(updated);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('修改成功'), backgroundColor: Color(0xFF00B894)),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
