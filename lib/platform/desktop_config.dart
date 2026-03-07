import 'dart:io';
import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// 桌面端配置管理
class DesktopConfig {
  static bool get isDesktop =>
      Platform.isWindows || Platform.isMacOS || Platform.isLinux;

  /// 初始化窗口配置
  static Future<void> initialize() async {
    // 初始化 SQLite FFI（桌面端必需）
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
}
