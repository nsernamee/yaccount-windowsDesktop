---
name: 金额科学计数法显示优化
overview: 金额过长时使用科学计数法显示（如¥1.23M），其他保持方案一
todos:
  - id: add-format-function
    content: 在 constants.dart 添加科学计数法格式化函数
    status: completed
  - id: update-statcard
    content: 更新 StatCard 组件使用科学计数法
    status: completed
    dependencies:
      - add-format-function
  - id: update-budgetbar
    content: 更新 BudgetProgressBar 使用科学计数法
    status: completed
    dependencies:
      - add-format-function
  - id: update-homepage
    content: 更新首页余额显示使用科学计数法
    status: completed
    dependencies:
      - add-format-function
  - id: update-budgetpage
    content: 更新预算页面金额显示（3处）
    status: completed
    dependencies:
      - add-format-function
  - id: update-historypage
    content: 更新历史记录金额显示
    status: completed
    dependencies:
      - add-format-function
---

## 用户需求

- 首页本月结余：扩大显示范围，只在超过1亿时使用科学计数法
- 其他页面保持原有科学计数法规则（1000以上用K，100万以上用M，1亿以上用Y）

## 技术方案

在 constants.dart 中添加两个格式化函数：
- `formatAmountCompact`：首页本月结余专用（1000以下正常显示，千位分隔符显示到99万，100万以上用M，1亿以上用Y）
- `formatAmount`：其他页面使用（现有规则，1000以上用K）

## 修改文件清单

1. lib/utils/constants.dart - 添加新的格式化函数
2. lib/pages/home_page.dart - 首页余额显示使用新函数