import 'package:flutter/foundation.dart';
import '../database/database_helper.dart';

/// 全局应用状态Provider
class AppProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper();

  bool _isInitialized = false;
  bool _isDbReady = false;

  bool get isInitialized => _isInitialized;
  bool get isDbReady => _isDbReady;

  /// 初始化应用
  Future<void> initialize() async {
    if (_isInitialized) return;

    // 初始化数据库
    await _db.reinitialize();
    _isDbReady = true;
    _isInitialized = true;
    notifyListeners();
  }

  /// 获取数据库实例
  DatabaseHelper get database => _db;
}
