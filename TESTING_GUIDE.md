# YAccount 本地记账软件 - 测试指南

## 环境要求

- Flutter SDK 3.11.1 或更高版本
- Android Studio / Xcode (用于设备测试)
- 测试设备或模拟器

## 测试步骤

### 1. 安装依赖

```bash
cd d:/repository/yaccount
flutter pub get
```

### 2. 运行单元测试

```bash
flutter test
```

测试覆盖以下功能:
- ✅ App启动测试
- ✅ 首页UI元素测试
- ✅ 添加交易页面测试
- ✅ 历史记录页面测试
- ✅ 统计页面测试
- ✅ 预算页面测试
- ✅ 设置页面测试

### 3. 运行设备测试

#### Android 设备/模拟器

```bash
flutter devices  # 查看可用设备
flutter run -d <device_id>
```

#### iOS 模拟器 (仅限 macOS)

```bash
open -a Simulator  # 打开iOS模拟器
flutter run
```

## 功能测试清单

### 核心功能测试

- [ ] **交易录入**
  - [ ] 切换支出/收入标签
  - [ ] 输入金额
  - [ ] 选择分类
  - [ ] 输入备注
  - [ ] 修改日期
  - [ ] 保存交易

- [ ] **首页统计**
  - [ ] 今日收支统计显示正确
  - [ ] 本周收支统计显示正确
  - [ ] 本月收支统计显示正确
  - [ ] 预算进度条显示正确
  - [ ] 预算颜色警告(绿/黄/红)

- [ ] **历史记录**
  - [ ] 按日期倒序显示
  - [ ] 分页加载(每次20条)
  - [ ] 滑动删除功能
  - [ ] 编辑功能

- [ ] **统计图表**
  - [ ] 饼图: 支出分类占比
  - [ ] 柱状图: 近6个月收支对比
  - [ ] 折线图: 当月每日支出趋势
  - [ ] 月份切换功能

- [ ] **预算管理**
  - [ ] 设置月度总预算
  - [ ] 设置分类预算
  - [ ] 预算使用率实时更新
  - [ ] 预算超支提醒

- [ ] **导入导出**
  - [ ] 导出CSV文件
  - [ ] 导出Excel文件
  - [ ] 导入CSV文件
  - [ ] 导入Excel文件
  - [ ] 增量导入选项
  - [ ] 覆盖导入选项

- [ ] **设置功能**
  - [ ] 设置应用密码
  - [ ] 修改应用密码
  - [ ] 关闭应用密码
  - [ ] 查看关于信息
  - [ ] 清空所有数据(二次确认)

### 性能测试

- [ ] **冷启动速度**
  - [ ] 首次启动时间 < 1.5秒
  - [ ] 数据库异步初始化不阻塞UI

- [ ] **列表性能**
  - [ ] 历史记录滑动帧率稳定在 60fps
  - [ ] 大量数据时仍保持流畅

- [ ] **图表性能**
  - [ ] 图表渲染流畅
  - [ ] 数据切换无明显卡顿

### 安全测试

- [ ] **数据加密**
  - [ ] 设置密码后数据库加密
  - [ ] 不设置密码则不加密
  - [ ] 密码错误无法打开应用

- [ ] **网络权限**
  - [ ] Android无网络权限
  - [ ] iOS无网络权限

### 数据完整性测试

- [ ] **CRUD操作**
  - [ ] 创建交易记录
  - [ ] 读取交易记录
  - [ ] 更新交易记录
  - [ ] 删除交易记录

- [ ] **批量操作**
  - [ ] 批量导入数据
  - [ ] 事务回滚

- [ ] **数据库索引**
  - [ ] 日期查询使用索引
  - [ ] 查询性能优化

## 打包测试

### Android 打包

```bash
# Debug版本
flutter build apk --debug

# Release版本 (会进行代码混淆和压缩)
flutter build apk --release

# 检查APK大小
ls -lh build/app/outputs/flutter-apk/
```

**预期结果**: Release APK 大小应小于 15MB

### iOS 打包

```bash
# Debug版本
flutter build ios --debug

# Release版本
flutter build ios --release

# 检查包大小
# 在 Xcode 中查看 archive 产物
```

## 已知问题

目前测试环境可能遇到的问题:
1. Flutter SDK 未正确安装或未添加到 PATH
2. 模拟器/设备未启动
3. 首次运行需要较长时间编译

## 解决方案

### Flutter SDK 未安装

```bash
# 下载 Flutter SDK
# 访问 https://flutter.dev/docs/get-started/install

# 添加到环境变量 (Windows)
setx PATH "%PATH%;C:\flutter\bin"

# 验证安装
flutter doctor
```

### 模拟器启动失败

**Android**:
- 打开 Android Studio
- AVD Manager → 创建模拟器 → 启动

**iOS**:
```bash
open -a Simulator
```

## 测试报告模板

```
测试日期: YYYY-MM-DD
测试设备: XXX (OS版本)
测试结果: PASS/FAIL

功能测试:
- 交易录入: ✓
- 首页统计: ✓
- ...

性能测试:
- 冷启动: 1.2秒 (目标 <1.5秒) ✓
- 列表帧率: 58-60fps ✓
- ...

问题记录:
1. [问题描述]
   - 复现步骤:
   - 期望结果:
   - 实际结果:

建议:
[改进建议]
```

---

**注意**: 由于当前环境缺少 Flutter SDK 配置,建议在配置好 Flutter 环境后执行上述测试命令。
