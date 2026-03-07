import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/transaction_provider.dart';
import '../utils/constants.dart';
import '../utils/date_utils.dart';
import '../models/category_model.dart';

/// 视图模式枚举
enum ViewMode {
  monthly,
  yearly,
}

/// 统计页面
class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  late DateTime _selectedDate;
  ViewMode _viewMode = ViewMode.monthly;
  late PageController _pieChartPageController;
  int _currentPiePage = 0;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _pieChartPageController = PageController();
  }

  @override
  void dispose() {
    _pieChartPageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: const Text('统计'),
        backgroundColor: Colors.white,
        foregroundColor: AppConstants.textPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: _selectDate,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildViewModeSelector(),
            const SizedBox(height: 16),
            _buildDateSelector(),
            const SizedBox(height: 20),
            _buildPieChart(),
            const SizedBox(height: 24),
            _buildBarChart(),
            const SizedBox(height: 24),
            _buildLineChart(),
          ],
        ),
      ),
    );
  }

  Widget _buildViewModeSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildModeChip(ViewMode.monthly, '月份视图'),
          ),
          Expanded(
            child: _buildModeChip(ViewMode.yearly, '年份视图'),
          ),
        ],
      ),
    );
  }

  Widget _buildModeChip(ViewMode mode, String label) {
    final isSelected = _viewMode == mode;
    return GestureDetector(
      onTap: () {
        setState(() => _viewMode = mode);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? const Color(0xFF3C8488) : Colors.grey[600],
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDateSelector() {
    if (_viewMode == ViewMode.monthly) {
      return _buildMonthSelector();
    } else {
      return _buildYearSelector();
    }
  }

  Widget _buildMonthSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3C8488), Color(0xFF9EE1D8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, color: Colors.white),
            onPressed: () {
              setState(() {
                _selectedDate = DateTime(
                  _selectedDate.year,
                  _selectedDate.month - 1,
                );
              });
            },
          ),
          Expanded(
            child: Text(
              AppDateUtils.formatMonth(_selectedDate),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, color: Colors.white),
            onPressed: _selectedDate.month < DateTime.now().month ||
                    _selectedDate.year < DateTime.now().year
                ? () {
                    setState(() {
                      _selectedDate = DateTime(
                        _selectedDate.year,
                        _selectedDate.month + 1,
                      );
                    });
                  }
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildMonthHeader() {
    // 此方法不再使用,已删除
    return const SizedBox.shrink();
  }

  Widget _buildYearSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3C8488), Color(0xFF9EE1D8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, color: Colors.white),
            onPressed: _selectedDate.year > 2020
                ? () {
                    setState(() {
                      _selectedDate = DateTime(_selectedDate.year - 1, 1);
                    });
                  }
                : null,
          ),
          Expanded(
            child: Text(
              '${_selectedDate.year}年',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, color: Colors.white),
            onPressed: _selectedDate.year < DateTime.now().year
                ? () {
                    setState(() {
                      _selectedDate = DateTime(_selectedDate.year + 1, 1);
                    });
                  }
                : null,
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDatePickerMode: _viewMode == ViewMode.monthly
          ? DatePickerMode.year
          : DatePickerMode.year,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF3C8488),
              onPrimary: Colors.white,
              secondary: Color(0xFF9EE1D8),
              onSecondary: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (_viewMode == ViewMode.monthly) {
          _selectedDate = picked!;
        } else {
          _selectedDate = DateTime(picked!.year, 1, 1);
        }
      });
    }
  }

  Widget _buildPieChart() {
    return Container(
      height: 270,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 支出/收入切换
          Expanded(
            child: IndexedStack(
              index: _currentPiePage,
              children: [
                // 支出分类
                _buildPieChartContent('支出分类', _getCategoryStats(type: 'expense')),
                // 收入分类
                _buildPieChartContent('收入分类', _getCategoryStats(type: 'income')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeButton(String label, int index) {
    final isSelected = _currentPiePage == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentPiePage = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF3C8488) : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppConstants.textSecondary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildPieChartContent(String title, Future<Map<String, double>> dataFuture) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 标题和切换按钮在同一行
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Row(
              children: [
                _buildTypeButton('支出', 0),
                const SizedBox(width: 8),
                _buildTypeButton('收入', 1),
              ],
            ),
          ],
        ),
        const SizedBox(height: 10),
        FutureBuilder<Map<String, double>>(
          future: dataFuture,
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const SizedBox(
                height: 200,
                child: Center(child: Text('暂无数据')),
              );
            }

            final data = snapshot.data!;
            final total = data.values.fold(0.0, (a, b) => a + b);

            return SizedBox(
              height: 190,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 30),
                    child: Center(
                      child: SizedBox(
                        width: 180,
                        child: PieChart(
                          PieChartData(
                            sectionsSpace: 1,
                            centerSpaceRadius: 25,
                            sections: data.entries.map((entry) {
                              final index = data.keys.toList().indexOf(entry.key);
                              final color = AppConstants.chartColors[
                                  index % AppConstants.chartColors.length];
                              return PieChartSectionData(
                                value: entry.value,
                                color: color,
                                radius: 45,
                                title: '${(entry.value / total * 100).toStringAsFixed(0)}%',
                                titleStyle: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 1),
                  Expanded(
                    flex: 1,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: data.entries.map((entry) {
                          final index = data.keys.toList().indexOf(entry.key);
                          final color = AppConstants.chartColors[
                              index % AppConstants.chartColors.length];
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _getCategoryName(entry.key),
                                    style: const TextStyle(fontSize: 12),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Future<Map<String, double>> _getCategoryStats({String type = 'expense'}) async {
    final provider = context.read<TransactionProvider>();

    if (_viewMode == ViewMode.monthly) {
      final startDate = DateTime(_selectedDate.year, _selectedDate.month, 1);
      final endDate = DateTime(_selectedDate.year, _selectedDate.month + 1, 0);
      return await provider.getCategoryStats(
        startDate: startDate,
        endDate: endDate,
        type: type,
      );
    } else {
      // 年度视图：统计全年分类支出
      final startDate = DateTime(_selectedDate.year, 1, 1);
      final endDate = DateTime(_selectedDate.year + 1, 1, 0);
      return await provider.getCategoryStats(
        startDate: startDate,
        endDate: endDate,
        type: type,
      );
    }
  }

  Widget _buildBarChart() {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _viewMode == ViewMode.monthly ? '近6个月收支对比' : '年度12个月收支对比',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _getMonthlyStats(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('暂无数据'));
                }

                final data = snapshot.data!;
                return BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: _getMaxY(data),
                    barGroups: data.asMap().entries.map((entry) {
                      return BarChartGroupData(
                        x: entry.key,
                        barRods: [
                          BarChartRodData(
                            toY: (entry.value['income'] as num).toDouble(),
                            color: AppConstants.incomeColor,
                            width: 12,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(4),
                            ),
                          ),
                          BarChartRodData(
                            toY: (entry.value['expense'] as num).toDouble(),
                            color: AppConstants.expenseColor,
                            width: 12,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(4),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                    titlesData: FlTitlesData(
                      leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            if (value.toInt() >= data.length) return const Text('');
                            return Text(
                              '${data[value.toInt()]['month']}',
                              style: const TextStyle(fontSize: 10),
                            );
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    gridData: const FlGridData(show: false),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _LegendItem(color: AppConstants.incomeColor, label: '收入'),
              const SizedBox(width: 24),
              _LegendItem(color: AppConstants.expenseColor, label: '支出'),
            ],
          ),
        ],
      ),
    );
  }

  double _getMaxY(List<Map<String, dynamic>> data) {
    double max = 0;
    for (final item in data) {
      final income = (item['income'] as num).toDouble();
      final expense = (item['expense'] as num).toDouble();
      if (income > max) max = income;
      if (expense > max) max = expense;
    }
    return max * 1.2;
  }

  Future<List<Map<String, dynamic>>> _getMonthlyStats() async {
    final provider = context.read<TransactionProvider>();

    if (_viewMode == ViewMode.monthly) {
      // 月度视图：显示近6个月
      return await provider.getMonthlyStats(6);
    } else {
      // 年度视图：显示1-12月
      return await provider.getYearlyStats(_selectedDate.year);
    }
  }

  Widget _buildLineChart() {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _viewMode == ViewMode.monthly ? '本月每日支出趋势' : '年度月度支出趋势',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: FutureBuilder<Map<String, double>>(
              future: _getDailyTrend(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('暂无数据'));
                }

                final data = snapshot.data!;
                final spots = <FlSpot>[];

                if (_viewMode == ViewMode.monthly) {
                  // 月度视图：显示当月每天
                  final daysInMonth = DateTime(
                    _selectedDate.year,
                    _selectedDate.month + 1,
                    0,
                  ).day;
                  for (int i = 1; i <= daysInMonth; i++) {
                    final date =
                        '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${i.toString().padLeft(2, '0')}';
                    spots.add(FlSpot(
                      i.toDouble(),
                      data[date] ?? 0,
                    ));
                  }
                } else {
                  // 年度视图：显示12个月的支出
                  for (int i = 1; i <= 12; i++) {
                    final monthKey = '$i月';
                    spots.add(FlSpot(
                      i.toDouble(),
                      data[monthKey] ?? 0,
                    ));
                  }
                }

                return LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: _getLineMaxY(spots) / 4,
                    ),
                    titlesData: FlTitlesData(
                      leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: _viewMode == ViewMode.monthly ? 7 : 2,
                          getTitlesWidget: (value, meta) {
                            if (_viewMode == ViewMode.monthly) {
                              return Text(
                                '${value.toInt()}日',
                                style: const TextStyle(fontSize: 10),
                              );
                            } else {
                              return Text(
                                '${value.toInt()}月',
                                style: const TextStyle(fontSize: 10),
                              );
                            }
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    minY: 0,
                    maxY: _getLineMaxY(spots),
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        color: AppConstants.expenseColor,
                        barWidth: 3,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          color: AppConstants.expenseColor.withValues(alpha: 0.1),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  double _getLineMaxY(List<FlSpot> spots) {
    double max = 0;
    for (final spot in spots) {
      if (spot.y > max) max = spot.y;
    }
    return max > 0 ? max * 1.2 : 1000;
  }

  Future<Map<String, double>> _getDailyTrend() async {
    final provider = context.read<TransactionProvider>();

    if (_viewMode == ViewMode.monthly) {
      // 月度视图：获取当月每日趋势
      return await provider.getDailyTrend(
        year: _selectedDate.year,
        month: _selectedDate.month,
      );
    } else {
      // 年度视图：获取年度月度趋势（12个数据点）
      return await provider.getYearlyMonthlyTrend(_selectedDate.year);
    }
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

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
