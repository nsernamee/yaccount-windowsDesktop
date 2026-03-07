---
name: YAccount Windows桌面端适配方案
overview: 将Flutter记账应用完全适配Windows桌面端，移除手机端相关的条件判断逻辑，保留桌面端特有的初始化配置
todos:
  - id: modify-main-dart
    content: 修改 main.dart，移除平台判断逻辑，直接初始化桌面端
    status: completed
  - id: modify-import-export
    content: 修改 import_export_page.dart，移除桌面端隐藏分享按钮的判断
    status: completed
  - id: optional-cleanup
    content: 可选：简化 desktop_config.dart，移除不再需要的 isDesktop 判断
    status: completed
---

## 用户需求

- 将 Flutter 记账应用完全适配 Windows 桌面端
- 不修改现有功能和页面样式
- 移除之前用于同时适配手机端和桌面端的判断逻辑
- 让代码默认运行在桌面端模式

## 现状分析

项目中存在以下平台判断逻辑需要处理：

1. **main.dart**：桌面端窗口初始化、移动端状态栏/竖屏设置
2. **import_export_page.dart**：桌面端隐藏分享按钮的条件判断
3. **database_helper.dart**：数据库路径选择（合理的兼容逻辑，可保留）
4. **desktop_config.dart**：isDesktop getter 和窗口配置

## 技术方案

### 修改策略

1. 移除所有 `DesktopConfig.isDesktop` 和 `!DesktopConfig.isDesktop` 的条件判断
2. 直接启用桌面端专用代码，移除移动端专用代码
3. 保留数据库路径的平台兼容性（支持未来跨平台编译）
4. 简化 main.dart 入口逻辑，直接初始化桌面端

### 关键修改点

| 文件 | 修改内容 |
| --- | --- |
| main.dart | 移除 `if ()` 和 `if (!DesktopConfig.isDesktopConfig.isDesktopDesktop)` 判断，直接执行桌面端代码 |
| import_export_page.dart | 移除 `if (!DesktopConfig.isDesktop)` 条件，显示分享按钮 |
| desktop_config.dart | 可选：移除 isDesktop 判断相关代码，或保留作为工具类 |


### 实现方式

- 直接修改条件分支，保留功能逻辑不变
- 不改变任何页面样式和业务功能