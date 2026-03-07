/// 分类模型
class CategoryModel {
  final String id;
  final String name;
  final String icon;
  final int colorValue;

  CategoryModel({
    required this.id,
    required this.name,
    required this.icon,
    required this.colorValue,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'color_value': colorValue,
    };
  }

  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      id: map['id'] as String,
      name: map['name'] as String,
      icon: map['icon'] as String,
      colorValue: map['color_value'] as int,
    );
  }
}

/// 默认分类列表
class DefaultCategories {
  static List<CategoryModel> get categories => [
    // 支出分类
    CategoryModel(id: 'food', name: '餐饮', icon: 'restaurant', colorValue: 0xFFFF6B6B),
    CategoryModel(id: 'transport', name: '交通', icon: 'directions_car', colorValue: 0xFF4ECDC4),
    CategoryModel(id: 'shopping', name: '消费', icon: 'shopping_bag', colorValue: 0xFFFFE66D),
    CategoryModel(id: 'medical', name: '医疗', icon: 'local_hospital', colorValue: 0xFFFCBAD3),
    CategoryModel(id: 'other', name: '其他', icon: 'more_horiz', colorValue: 0xFF636E72),
    // 收入分类
    CategoryModel(id: 'living', name: '生活费', icon: 'account_balance_wallet', colorValue: 0xFF6C5CE7),
    CategoryModel(id: 'salary', name: '薪水', icon: 'work', colorValue: 0xFF00B894),
    CategoryModel(id: 'investment', name: '投资', icon: 'trending_up', colorValue: 0xFFFFAA00),
    CategoryModel(id: 'income_other', name: '其他', icon: 'more_horiz', colorValue: 0xFF636E72),
  ];
}
