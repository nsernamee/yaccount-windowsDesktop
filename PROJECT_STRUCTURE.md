# YAccount 项目结构文档

## 1. 项目概述

YAccount 是一款本地记账 Flutter 应用，支持 Android 和 iOS 平台，采用 SQLite 本地数据库存储数据，确保用户隐私安全。

### 主要功能
- 记账：支持支出/收入记录，分类管理
- 统计：今日/本周/本月/本年收支统计，图表可视化
- 预算：月度预算设置和进度跟踪
- 导入导出：支持 CSV/Excel 格式数据导出和导入
- 多货币：支持人民币、美元、欧元、英镑

### 技术特点
- 状态管理：Provider
- 本地存储：SQLite (sqflite)
- 图表：fl_chart
- 数据格式：CSV、Excel

---

## 2. 环境要求

- Flutter SDK: ^3.11.1
- Dart SDK: ^3.11.1
- Android SDK: 最新稳定版
- Xcode: 最新稳定版（iOS 开发用）

---

## 3. 项目目录结构

```
yaccount/
├── lib/
│   ├── main.dart                 # 应用入口
│   ├── database/
│   │   └── database_helper.dart  # SQLite 数据库操作封装
│   ├── models/
│   │   ├── transaction_model.dart  # 交易记录模型
│   │   ├── budget_model.dart       # 预算模型
│   │   └── category_model.dart    # 分类模型
│   ├── pages/
│   │   ├── home_page.dart         # 首页（主页 + 导航）
│   │   ├── add_transaction_page.dart  # 添加/编辑交易
│   │   ├── history_page.dart      # 历史记录
│   │   ├── statistics_page.dart   # 统计分析
│   │   ├── budget_page.dart       # 预算管理
│   │   ├── import_export_page.dart # 导入导出
│   │   └── settings_page.dart    # 设置
│   ├── providers/
│   │   ├── app_provider.dart      # 应用全局状态
│   │   ├── transaction_provider.dart  # 交易数据管理
│   │   └── budget_provider.dart   # 预算数据管理
│   ├── utils/
│   │   ├── constants.dart         # 常量配置（颜色、货币等）
│   │   └── date_utils.dart        # 日期工具函数
│   └── widgets/
│       ├── common_widgets.dart     # 通用组件
│       └── category_selector.dart  # 分类选择器
├── android/                      # Android 平台配置
├── ios/                          # iOS 平台配置
├── pubspec.yaml                  # 项目依赖配置
└── analysis_options.yaml         # 代码规范配置
```

---

## 4. 依赖配置 (pubspec.yaml)

### 核心依赖

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter

  # 数据库
  sqflite: ^2.4.2           # SQLite 数据库
  path: ^1.9.1              # 路径处理

  # 状态管理
  provider: ^6.1.2          # Provider 状态管理

  # 图表
  fl_chart: ^0.70.2         # 图表库

  # 文件处理
  path_provider: ^2.1.5      # 应用目录访问
  share_plus: ^10.1.4        # 系统分享
  file_picker: ^8.3.7        # 文件选择

  # 数据处理
  csv: ^6.0.0               # CSV 解析
  excel: ^4.0.6             # Excel 处理
  intl: ^0.20.2             # 国际化数字/日期格式
  uuid: ^4.5.1              # UUID 生成

  # 安全
  crypto: ^3.0.6             # 加密（用于数据库密钥派生）
  flutter_secure_storage: ^9.2.4  # 安全存储

  # UI
  flutter_slidable: ^3.1.2   # 滑动操作组件
  shared_preferences: ^2.3.5 # 轻量级存储

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0
  sqflite_common_ffi: ^2.3.4+1  # 测试用
```

---

## 5. 数据模型

### 5.1 交易记录 (TransactionModel)

```dart
class TransactionModel {
  final String id;           // UUID 唯一标识
  final double amount;       // 金额
  final String type;         // 'expense' 或 'income'
  final String category;     // 分类 ID
  final String? note;        // 备注（可选）
  final DateTime date;       // 交易日期
  final DateTime createdAt;  // 创建时间
}
```

### 5.2 预算 (BudgetModel)

```dart
class BudgetModel {
  final String id;           // UUID 唯一标识
  final String category;     // 分类 ID（'total' 表示总预算）
  final double amount;       // 预算金额
  final int month;           // 月份（1-12）
  final DateTime createdAt;  // 创建时间
}
```

### 5.3 分类 (CategoryModel)

```dart
class CategoryModel {
  final String id;           // 分类 ID
  final String name;         // 分类名称
  final String icon;         // 图标名称
  final int colorValue;      // 颜色值
}
```

### 默认分类

**支出分类：**
| ID | 名称 | 图标 | 颜色 |
|----|------|------|------|
| food | 餐饮 | restaurant | #FF6B6B |
| transport | 交通 | directions_car | #4ECDC4 |
| shopping | 消费 | shopping_bag | #FFE66D |
| medical | 医疗 | local_hospital | #FCBAD3 |
| other | 其他 | more_horiz | #636E72 |

**收入分类：**
| ID | 名称 | 图标 | 颜色 |
|----|------|------|------|
| living | 生活费 | account_balance_wallet | #6C5CE7 |
| salary | 薪水 | work | #00B894 |
| investment | 投资 | trending_up | #FDCB6E |
| other | 其他 | more_horiz | #636E72 |

---

## 6. 数据库设计

### 6.1 数据库配置

- 数据库名称：`yaccount.db`
- 数据库版本：`1`
- 数据库文件位置：应用文档目录

### 6.2 表结构

#### transactions（交易记录表）

```sql
CREATE TABLE transactions (
  id TEXT PRIMARY KEY,           -- UUID
  amount REAL NOT NULL,         -- 金额
  type TEXT NOT NULL,           -- 'expense' 或 'income'
  category TEXT NOT NULL,       -- 分类 ID
  note TEXT,                    -- 备注
  date TEXT NOT NULL,           -- 日期 (yyyy-MM-dd)
  created_at TEXT NOT NULL      -- 创建时间 (ISO8601)
);

-- 索引
CREATE INDEX idx_transaction_date ON transactions(date);
CREATE INDEX idx_transaction_type ON transactions(type);
CREATE INDEX idx_transaction_category ON transactions(category);
```

#### budgets（预算表）

```sql
CREATE TABLE budgets (
  id TEXT PRIMARY KEY,           -- UUID
  category TEXT NOT NULL,        -- 分类 ID 或 'total'
  amount REAL NOT NULL,          -- 预算金额
  month INTEGER NOT NULL,        -- 月份
  created_at TEXT NOT NULL,      -- 创建时间
  UNIQUE(category, month)        -- 分类和月份唯一约束
);
```

#### categories（分类表）

```sql
CREATE TABLE categories (
  id TEXT PRIMARY KEY,           -- 分类 ID
  name TEXT NOT NULL,           -- 分类名称
  icon TEXT NOT NULL,            -- 图标名称
  color_value INTEGER NOT NULL   -- 颜色值
);
```

#### settings（设置表）

```sql
CREATE TABLE settings (
  key TEXT PRIMARY KEY,          -- 设置键
  value TEXT NOT NULL            -- 设置值
);
```

---

## 7. 核心模块说明

### 7.1 入口文件 (main.dart)

**功能：** 应用启动入口，初始化和配置

**主要职责：**
- 初始化 Flutter 绑定
- 配置系统 UI（状态栏、屏幕方向）
- 设置 MultiProvider 全局状态管理
- 配置 MaterialApp（主题、本地化）
- 处理启动画面和初始化流程

**关键代码结构：**
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(...);
  SystemChrome.setPreferredOrientations([...]);
  runApp(const YAccountApp());
}

class YAccountApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppProvider()..initialize()),
        ChangeNotifierProvider(create: (_) => TransactionProvider()),
        ChangeNotifierProvider(create: (_) => BudgetProvider()),
        ChangeNotifierProvider(create: (_) => CurrencyManager.instance),
      ],
      child: MaterialApp(
        // 主题配置
        // 本地化配置
        home: const _AppWrapper(),
      ),
    );
  }
}
```

### 7.2 数据库操作 (database_helper.dart)

**功能：** SQLite 数据库的 CRUD 操作封装

**主要职责：**
- 单例模式管理数据库连接
- 交易记录的增删改查
- 预算管理
- 统计数据查询
- 设置存储

**核心方法：**
```dart
class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  
  // 获取数据库实例
  Future<Database> get database async {...}
  
  // 交易 CRUD
  Future<int> insertTransaction(TransactionModel transaction);
  Future<List<TransactionModel>> getTransactions({int page, int pageSize, String? type, DateTime? startDate, DateTime? endDate});
  Future<int> updateTransaction(TransactionModel transaction);
  Future<int> deleteTransaction(String id);
  Future<void> insertTransactionsBatch(List<TransactionModel> transactions);  // 批量插入（事务优化）
  
  // 统计查询
  Future<Map<String, double>> getStatistics({required DateTime startDate, required DateTime endDate});
  Future<Map<String, double>> getCategoryStatistics({...});
  Future<List<Map<String, dynamic>>> getMonthlyStatistics(int months);
  Future<Map<String, double>> getDailyExpenseTrend({...});
  
  // 预算 CRUD
  Future<void> setBudget(BudgetModel budget);
  Future<BudgetModel?> getBudget(int month, {String? category});
  Future<List<BudgetModel>> getBudgets(int month);
}
```

### 7.3 状态管理 (providers/)

**AppProvider：** 应用全局状态
- 数据库就绪状态
- 初始化完成状态

**TransactionProvider：** 交易数据管理
- 交易列表管理（分页加载）
- 统计数据（今日/本周/本月/本年）
- 增删改查操作
- 批量导入

**BudgetProvider：** 预算数据管理
- 预算设置
- 预算进度计算

**CurrencyManager：** 货币管理
- 当前货币切换
- 货币偏好持久化（SharedPreferences）

### 7.4 页面模块 (pages/)

| 页面 | 功能 |
|------|------|
| home_page.dart | 首页，包含底部导航和主页内容（收支概览、快速记账、预算进度） |
| add_transaction_page.dart | 添加/编辑交易记录 |
| history_page.dart | 历史记录列表，支持分页加载和筛选 |
| statistics_page.dart | 统计分析，饼图、柱状图、折线图 |
| budget_page.dart | 预算管理，设置月度预算 |
| import_export_page.dart | 数据导入导出（CSV/Excel） |
| settings_page.dart | 设置页面 |

### 7.5 工具函数 (utils/)

**constants.dart：**
- 主题颜色配置
- 金额格式化函数（`formatAmount`、`formatAmountRaw`、`formatAmountCompact`）
- 货币类定义
- 货币管理器

**date_utils.dart：**
- 日期格式化
- 日期计算

---

## 8. 实现方法详解

### 8.1 状态管理

采用 **Provider** 方案，使用 `ChangeNotifier` 实现响应式状态管理。

```dart
// 在 main.dart 中配置
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => TransactionProvider()),
    // ...
  ],
  child: MyApp(),
)

// 在页面中使用
Consumer<TransactionProvider>(
  builder: (context, provider, _) {
    return Text('${provider.monthStats['expense']}');
  },
)
```

### 8.2 分页加载

历史记录采用分页加载优化性能：

```dart
// TransactionProvider 中
static const int _pageSize = 20;
Future<void> loadTransactions({bool refresh = false, ...}) async {
  if (refresh) {
    _currentPage = 0;
    _transactions = [];
  }
  final newTransactions = await _db.getTransactions(
    page: _currentPage,
    pageSize: _pageSize,
    ...
  );
  _transactions.addAll(newTransactions);
  _currentPage++;
}
```

### 8.3 数据导入导出

**导出流程：**
1. 从数据库获取所有交易记录
2. 转换为 CSV/Excel 格式
3. 保存到应用文档目录
4. 用户选择保存或分享

**导入流程：**
1. 用户选择 CSV/Excel 文件
2. 解析文件内容
3. 显示导入模式选择（增量追加/覆盖替换）
4. 批量插入数据库

**分类映射：**
```dart
String _mapCategory(String category) {
  final mapping = {
    '餐饮': 'food',
    '交通': 'transport',
    '消费': 'shopping',
    '医疗': 'medical',
    '生活费': 'living',
    '薪水': 'salary',
    '投资': 'investment',
    '其他': 'other',
  };
  return mapping[category] ?? category;
}
```

### 8.4 金额格式化

提供三种格式化函数：

| 函数 | 用途 | 规则 |
|------|------|------|
| `formatAmount` | 通用格式化 | 1000+，显示 K/M/Y |
| `formatAmountRaw` | 历史记录显示 | 保留原始数值，千位分隔符 |
| `formatAmountCompact` | 首页结余 | 1万亿+显示特殊文案 |

### 8.5 图表实现

使用 **fl_chart** 库：

- **饼图 (PieChart)：** 分类支出占比
- **柱状图 (BarChart)：** 月度收支对比
- **折线图 (LineChart)：** 每日/每月支出趋势

---

## 9. 关键技术选型

| 技术 | 选型 | 理由 |
|------|------|------|
| 状态管理 | Provider | 简单易用，官方推荐 |
| 数据库 | sqflite | SQLite 本地存储，离线可用，保护隐私 |
| 图表 | fl_chart | 功能丰富，性能好 |
| 导入导出 | csv + excel | 通用格式，方便用户 |
| 国际化 | flutter_localizations | 官方支持 |

---

## 10. 运行和构建命令

### 10.1 开发运行

```bash
# 获取依赖
flutter pub get

# 运行应用
flutter run
```

### 10.2 构建 APK

```bash
# Debug 包
flutter build apk --debug

# Release 包
flutter build apk --release
```

### 10.3 构建 iOS

```bash
# iOS 模拟器
flutter build ios --simulator --no-codesign

# iOS 真机（需要签名）
flutter build ios --release
```

### 10.4 输出路径

- Android: `build/app/outputs/flutter-apk/app-release.apk`
- iOS: `build/ios/iphoneos/Runner.app`

---

## 11. 版本信息

当前版本：**1.3.0**

版本格式：`major.minor.patch+build`

- major：主版本号
- minor：次版本号
- patch：补丁版本号
- build：构建号

### v1.3.0 更新内容

- **UI 全新绿色主题**：将原有紫色系主题完全替换为绿色系主题（主色 #00B894）
- **日期选择器配色**：添加/编辑交易页面的日期选择器使用绿色主题
- **提示框配色统一**：所有 SnackBar 提示框使用绿色/红色主题（成功/失败）
- **对话框按钮配色**：添加预算、导入导出等对话框按钮使用绿色系
- **刷新指示器配色**：首页下拉刷新指示器使用青绿色 (#42898D)
- **分类图标修复**：修复历史记录页面薪水分类图标显示不一致问题
- **预算卡片增强**：分类预算卡片增加"已花费/剩余"金额显示
- **统计页面优化**：饼图左侧增加 16px 边距，改善视觉平衡
- **导出功能优化**：导出文件直接保存到系统下载目录（使用 getDownloadsDirectory）

---

## 12. 注意事项

1. **数据库加密**：当前版本未启用加密（如需启用，可使用 `sqflite_sqlcipher` 替代 `sqflite`）
2. **Web 平台**：不支持 Web 平台，运行时会有相应提示
3. **网络访问**：导入导出功能不依赖网络，纯本地操作
4. **数据备份**：建议定期使用导入导出功能备份数据
