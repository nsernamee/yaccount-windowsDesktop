import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/constants.dart';

/// 统一高度的一行统计卡片
class StatCardRow extends StatelessWidget {
  final Widget leftCard;
  final Widget rightCard;

  const StatCardRow({
    required this.leftCard,
    required this.rightCard,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: leftCard),
          const SizedBox(width: 12),
          Expanded(child: rightCard),
        ],
      ),
    );
  }
}

/// 统计卡片组件
class StatCard extends StatelessWidget {
  final String title;
  final double amount;
  final Color color;
  final IconData icon;

  const StatCard({
    super.key,
    required this.title,
    required this.amount,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<CurrencyManager>(
      builder: (context, currencyManager, _) {
        final symbol = currencyManager.current.symbol;
        final amountStr = '${AppConstants.formatAmount(amount)} $symbol';

        // 根据金额长度动态计算字体大小
        double getAmountFontSize() {
          if (amountStr.length <= 8) return 20;      // 99999.99 ¥
          if (amountStr.length <= 10) return 18;    // 9999999.99 ¥
          if (amountStr.length <= 12) return 16;     // 999999999.99 ¥
          return 14;                                // 更长的情况
        }

        return Container(
          constraints: const BoxConstraints(
            minHeight: 100,  // 最小高度,确保足够空间
          ),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,  // 统一纯白色背景
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,  // 内容垂直居中
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppConstants.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                amountStr,
                style: TextStyle(
                  color: color,
                  fontSize: getAmountFontSize(),  // 动态字体大小
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,  // 防止换行
              ),
            ],
          ),
        );
      },
    );
  }
}

/// 预算进度条组件
class BudgetProgressBar extends StatelessWidget {
  final double spent;
  final double budget;
  final String? label;

  const BudgetProgressBar({
    super.key,
    required this.spent,
    required this.budget,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    final rate = budget > 0 ? (spent / budget * 100).clamp(0.0, 100.0) : 0.0;
    final color = _getColor(rate);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label!,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppConstants.textSecondary,
                  ),
                ),
                Consumer<CurrencyManager>(
                  builder: (context, currencyManager, _) {
                    final symbol = currencyManager.current.symbol;
                    return Text(
                      '${spent.toStringAsFixed(2)} $symbol / ${budget.toStringAsFixed(2)} $symbol',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppConstants.textSecondary,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        Container(
          height: 8,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(4),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: rate / 100,
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Color _getColor(double rate) {
    if (rate < 70) return AppConstants.budgetGreen;
    if (rate < 90) return AppConstants.budgetYellow;
    return AppConstants.budgetRed;
  }
}

/// 空状态组件
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final VoidCallback? onAction;
  final String? actionText;

  const EmptyState({
    super.key,
    required this.icon,
    required this.message,
    this.onAction,
    this.actionText,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            if (onAction != null && actionText != null) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: onAction,
                child: Text(actionText!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 加载更多组件
class LoadMoreIndicator extends StatelessWidget {
  final bool isLoading;
  final bool hasMore;

  const LoadMoreIndicator({
    super.key,
    required this.isLoading,
    required this.hasMore,
  });

  @override
  Widget build(BuildContext context) {
    if (!hasMore) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(
          child: Text(
            '没有更多了',
            style: TextStyle(color: AppConstants.textSecondary),
          ),
        ),
      );
    }

    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return const SizedBox.shrink();
  }
}
