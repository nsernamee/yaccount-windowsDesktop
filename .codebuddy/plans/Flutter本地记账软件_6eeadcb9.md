---
name: Flutter本地记账软件
overview: 开发一款本地记账App，支持支出/收入录入、SQLite加密存储、实时统计、图表分析、预算管理、导入导出，确保性能优化（冷启动1.5秒、60fps列表、包大小<15MB）
todos:
  - id: init-flutter-project
    content: 初始化Flutter项目，配置pubspec.yaml依赖
    status: completed
  - id: create-database-helper
    content: 创建数据库帮助类，含建表SQL、索引、CRUD封装
    status: completed
    dependencies:
      - init-flutter-project
  - id: create-data-models
    content: 创建Transaction、Budget、Category数据模型
    status: completed
    dependencies:
      - create-database-helper
  - id: create-providers
    content: 创建Provider状态管理层
    status: completed
    dependencies:
      - create-data-models
  - id: build-home-page
    content: 构建首页，展示今日/周/月统计和预算进度
    status: completed
    dependencies:
      - create-providers
  - id: build-add-transaction-page
    content: 构建交易录入页面，支持支出/收入切换
    status: completed
    dependencies:
      - build-home-page
  - id: build-history-page
    content: 构建历史记录页面，实现分页加载
    status: completed
    dependencies:
      - build-add-transaction-page
  - id: build-statistics-page
    content: 构建统计页面，实现饼图/柱状图/折线图
    status: completed
    dependencies:
      - build-history-page
  - id: build-budget-page
    content: 构建预算管理页面
    status: completed
    dependencies:
      - build-statistics-page
  - id: build-import-export-page
    content: 构建导入导出页面，支持CSV和Excel
    status: completed
    dependencies:
      - build-budget-page
  - id: build-settings-page
    content: 构建设置页面，实现密码加密功能
    status: completed
    dependencies:
      - build-import-export-page
  - id: optimize-performance
    content: 性能优化：列表懒加载、数据库索引、内存管理
    status: completed
    dependencies:
      - build-settings-page
  - id: configure-build
    content: 配置Android/iOS打包签名和代码剪裁
    status: completed
    dependencies:
      - optimize-performance
---

## 产品概述

一款本地记账移动应用（Android/iOS），支持支出和收入记录、数据加密存储、实时统计、图表分析、预算管理和导入导出功能。

## 核心功能

1. **双模块录入**：主界面分"支出"和"收入"模块，包含金额输入、备注输入、保存按钮，日期自动获取且可修改
2. **数据存储**：SQLite数据库（sqflite + sqflite_sqlcipher加密），按日期存储每笔记录（类型、金额、备注、分类）
3. **实时统计**：首页展示今日、本周、本月总收入、总支出和结余，新增记录自动刷新
4. **历史记录**：按日期倒序分页显示（每页20条），支持删除和修改操作
5. **月度统计图表**：饼图（支出分类占比）、柱状图（近6个月收支对比）、折线图（当月每日支出趋势），支持月份切换
6. **预算管理**：为每月总支出和各分类设置预算，进度条颜色提醒（<70%绿，70-90%黄，>90%红）
7. **导入导出**：支持CSV和Excel格式导出，支持导入本软件导出的文件（增量或覆盖模式可选）

## 性能要求

- 冷启动1.5秒内完成界面渲染，数据库异步初始化
- 历史记录列表懒加载分页（20条/页），滑动帧率60fps
- 图表使用fl_chart绘制，数据预聚合后渲染
- 及时关闭数据库游标避免内存泄漏
- 数据库优化：transaction_date字段索引、批量操作使用事务、查询只取必要字段
- Release包大小控制在15MB以内

## 数据安全

- 数据库加密可选（用户设置密码派生密钥，不设置则不加密）
- 不申请网络权限，数据完全不外传
- 关键操作（删除所有数据等）需二次确认

## 技术栈确认

- 应用密码：可选（设置则加密，不设置则不加密）
- 导出格式：CSV + Excel
- 分类体系：支出/收入共用同一套分类
- 导入来源：仅支持本软件导出文件的导入

## 技术栈

- 框架：Flutter 3.x
- 数据库：sqflite + sqflite_sqlcipher（加密）
- 图表库：fl_chart
- 状态管理：Provider
- 文件处理：csv、excel、path_provider

## 技术架构

### 系统架构

- 分层架构：UI层 → 业务逻辑层 → 数据层
- 组件结构：App → 页面组件 → 可复用组件

### 核心模块

- **数据库模块**：DatabaseHelper封装CRUD操作，支持加密/非加密切换
- **模型层**：Transaction、Budget、Category数据模型
- **Provider层**：TransactionProvider、BudgetProvider、AppProvider状态管理
- **页面层**：HomePage、AddTransactionPage、HistoryPage、StatisticsPage、BudgetPage、ImportExportPage、SettingsPage

### 目录结构

```
lib/
├── main.dart                    # 应用入口，异步初始化数据库
├── database/
│   └── database_helper.dart     # 数据库操作封装，含加密逻辑
├── models/
│   ├── transaction_model.dart   # 交易记录模型
│   ├── category_model.dart      # 分类模型
│   └── budget_model.dart        # 预算模型
├── providers/
│   ├── app_provider.dart        # 全局状态（密码设置等）
│   ├── transaction_provider.dart # 交易数据管理
│   └── budget_provider.dart     # 预算数据管理
├── pages/
│   ├── home_page.dart           # 首页（今日/周/月统计）
│   ├── add_transaction_page.dart # 添加交易页面
│   ├── history_page.dart        # 历史记录（分页）
│   ├── statistics_page.dart     # 统计图表
│   ├── budget_page.dart         # 预算管理
│   ├── import_export_page.dart  # 导入导出
│   └── settings_page.dart       # 设置（密码等）
├── widgets/                     # 可复用组件
├── utils/
│   ├── constants.dart           # 常量定义
│   └── date_utils.dart          # 日期工具
└── services/
    ├── export_service.dart      # 导出服务
    └── import_service.dart       # 导入服务
```

## 实现要点

### 数据库优化

- 建表SQL含索引：CREATE INDEX idx_transaction_date ON transactions(transaction_date)
- 批量插入使用事务：db.transaction
- 查询优化：SELECT id, amount, type, category, note, date FROM transactions WHERE...

### 性能优化

- 冷启动：FutureBuilder异步加载，数据库初始化不阻塞UI
- 列表分页：LIMIT 20 OFFSET page*20
- 图表数据聚合：SQL GROUP BY预计算，减少数据传输
- 内存管理：使用完Cursor立即close()

### 打包配置

- Android：proguard-rules.pro启用混淆，flutter build apk --release
- iOS：Xcode配置签名，flutter build ios --release
- 代码剪裁：pubspec.yaml配置tree-shaking

# Agent Extensions

本项目为全新创建，无需使用任何扩展。