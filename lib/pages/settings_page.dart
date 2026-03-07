import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../utils/constants.dart';

/// 设置页面
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: const Text('设置'),
        backgroundColor: Colors.white,
        foregroundColor: AppConstants.textPrimary,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildEncryptionNotice(),
          const SizedBox(height: 16),
          _buildSection(
            title: '数据管理',
            children: [
              _SettingsTile(
                icon: Icons.delete_outline,
                title: '清空所有数据',
                subtitle: '删除所有账目记录',
                onTap: () => _showClearDataDialog(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSection(
            title: '关于',
            children: [
              const _SettingsTile(
                icon: Icons.info_outline,
                title: '版本',
                subtitle: '1.3.0',
              ),
              _SettingsTile(
                icon: Icons.code,
                title: '关于 YAccount',
                subtitle: '本地记账，安全隐私',
                onTap: () => _showAboutDialog(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEncryptionNotice() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFB74D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, size: 20, color: const Color(0xFFF57C00)),
              const SizedBox(width: 8),
              const Text(
                '桌面端说明',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFF57C00),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Windows 桌面端暂不支持数据库加密功能。',
            style: TextStyle(fontSize: 13, color: AppConstants.textPrimary),
          ),
          const SizedBox(height: 6),
          const Text(
            '如需使用加密功能保护数据隐私，请下载手机端应用。',
            style: TextStyle(fontSize: 13, color: AppConstants.textPrimary),
          ),
          const SizedBox(height: 6),
          const Text(
            '• 桌面端数据存储在本地应用目录中',
            style: TextStyle(fontSize: 12, color: AppConstants.textSecondary),
          ),
          const Text(
            '• 请使用系统级加密（如 BitLocker）保护设备安全',
            style: TextStyle(fontSize: 12, color: AppConstants.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({required String title, required List<Widget> children}) {
    return Container(
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
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                color: AppConstants.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  void _showClearDataDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清空数据'),
        content: const Text(
          '此操作将删除所有账目数据，且不可恢复！\n\n请确认是否继续？',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              await context.read<AppProvider>().database.deleteAllData();
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('数据已清空'), backgroundColor: Color(0xFF00B894)),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('确认删除'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF3C8488),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.account_balance_wallet, color: Colors.white),
            ),
            const SizedBox(width: 12),
            const Text('YAccount'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('版本：1.3.0'),
            SizedBox(height: 12),
            Text(
              '一款安全、隐私的本地记账应用。\n\n特点：',
              style: TextStyle(color: AppConstants.textSecondary),
            ),
            SizedBox(height: 8),
            Text('• 数据完全本地存储'),
            Text('• 无网络权限，确保隐私'),
            Text('• 轻量级，包体积小'),
            Text('• 请自行保护设备安全'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF3C8488)),
      title: Text(title),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 12),
      ),
      trailing: trailing ?? (onTap != null ? const Icon(Icons.chevron_right) : null),
      onTap: onTap,
    );
  }
}
