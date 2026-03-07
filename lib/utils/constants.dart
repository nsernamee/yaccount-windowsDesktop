import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

/// 应用常量
class AppConstants {
  // 主题色
  static const Color primaryColor = Color(0xFF6C5CE7);
  static const Color expenseColor = Color(0xFFE17055);
  static const Color incomeColor = Color(0xFF00B894);
  static const Color backgroundColor = Color(0xFFF8F9FA);
  static const Color cardColor = Colors.white;
  static const Color textPrimary = Color(0xFF2D3436);
  static const Color textSecondary = Color(0xFF636E72);

  // 预算颜色
  static const Color budgetGreen = Color(0xFF00B894);
  static const Color budgetYellow = Color(0xFFFDCB6E);
  static const Color budgetRed = Color(0xFFE17055);

  // 分页大小
  static const int pageSize = 20;

  // 图表颜色（与分类顺序和颜色一致）
  static const List<Color> chartColors = [
    Color(0xFFFF6B6B),  // 1. 餐饮 - 红
    Color(0xFF4ECDC4),  // 2. 交通 - 青
    Color(0xFFFFE66D),  // 3. 消费 - 黄
    Color(0xFFFCBAD3),  // 4. 医疗 - 粉
    Color(0xFF636E72),  // 5. 其他 - 灰
    Color(0xFF6C5CE7),  // 6. 生活费 - 紫
    Color(0xFF00B894),  // 7. 薪水 - 绿
    Color(0xFFFFAA00),  // 8. 投资 - 橙
    Color(0xFF636E72),  // 9. 收入其他 - 灰
  ];

  /// 格式化金额，超过8位时使用科学计数法（如 ¥1.23M、¥12.5K）
  static String formatAmount(double amount) {
    if (amount.abs() >= 100000000) {
      // 1亿及以上，使用Y（亿）
      return '${(amount / 100000000).toStringAsFixed(2)}Y';
    } else if (amount.abs() >= 1000000) {
      // 100万及以上，使用M（百万）
      return '${(amount / 1000000).toStringAsFixed(2)}M';
    } else if (amount.abs() >= 1000) {
      // 1000及以上，使用K（千）
      return '${(amount / 1000).toStringAsFixed(1)}K';
    } else {
      // 1000以下，显示小数
      return amount.toStringAsFixed(2);
    }
  }

  /// 格式化金额，保留原始数值，使用千位分隔符（不四舍五入）
  /// 超过百亿时使用Y单位
  static String formatAmountRaw(double amount) {
    if (amount.abs() >= 10000000000) {
      // 百亿及以上，使用Y（亿）
      return '${(amount / 100000000).toStringAsFixed(2)}Y';
    }
    final formatter = NumberFormat('#,##0.00');
    return formatter.format(amount);
  }

  /// 首页本月结余专用格式化函数，扩大显示范围
  /// 1万亿以上显示特殊文案，1亿以下使用千位分隔符，1亿及以上使用Y（亿）
  /// 注意：返回的字符串不包含符号，符号由调用处单独处理
  static String formatAmountCompact(double amount) {
    final absAmount = amount.abs();
    if (absAmount >= 1000000000000) {
      // 1万亿及以上，不显示具体数字
      return amount >= 0 ? "你已经富可敌国" : "钱对你已经失去意义";
    } else if (absAmount >= 100000000) {
      // 1亿及以上，使用Y（亿）
      return '${(absAmount / 100000000).toStringAsFixed(2)}Y';
    } else {
      // 1亿以下，使用千位分隔符
      return NumberFormat('#,##0.00').format(absAmount);
    }
  }
}

/// 交易类型
class TransactionType {
  static const String expense = 'expense';
  static const String income = 'income';
}

/// 货币类型
class Currency {
  final String code;
  final String symbol;
  final String name;

  const Currency({
    required this.code,
    required this.symbol,
    required this.name,
  });

  static const List<Currency> supportedCurrencies = [
    Currency(code: 'CNY', symbol: '¥', name: '人民币'),
    Currency(code: 'USD', symbol: '\$', name: '美元'),
    Currency(code: 'EUR', symbol: '€', name: '欧元'),
    Currency(code: 'GBP', symbol: '£', name: '英镑'),
  ];
}

/// 货币管理器，使用 ChangeNotifier 实现全局状态管理
class CurrencyManager extends ChangeNotifier {
  static const String _storageKey = 'selected_currency';
  static CurrencyManager? _instance;

  Currency _currentCurrency = Currency.supportedCurrencies[0];

  CurrencyManager() {
    load();
  }

  static CurrencyManager get instance {
    _instance ??= CurrencyManager();
    return _instance!;
  }

  Currency get current => _currentCurrency;

  /// 加载保存的货币设置
  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final code = prefs.getString(_storageKey) ?? 'CNY';
      _currentCurrency = Currency.supportedCurrencies.firstWhere(
        (c) => c.code == code,
        orElse: () => Currency.supportedCurrencies[0],
      );
      notifyListeners();
    } catch (e) {
      // 如果加载失败，使用默认货币（人民币）
      _currentCurrency = Currency.supportedCurrencies[0];
    }
  }

  /// 保存并切换货币
  Future<void> setCurrency(Currency currency) async {
    try {
      _currentCurrency = currency;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, currency.code);
      notifyListeners();
    } catch (e) {
      // 如果保存失败，仍然更新当前货币，但无法持久化
      _currentCurrency = currency;
      notifyListeners();
    }
  }
}

/// 便捷访问当前货币
Currency get currentCurrency => CurrencyManager.instance.current;
