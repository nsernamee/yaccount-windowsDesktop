/// 预算模型
class BudgetModel {
  final String id;
  final String category; // 'total' 表示总预算，其他为分类预算
  final double amount;
  final int month; // 月份，格式：202601
  final DateTime createdAt;

  BudgetModel({
    required this.id,
    required this.category,
    required this.amount,
    required this.month,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category': category,
      'amount': amount,
      'month': month,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory BudgetModel.fromMap(Map<String, dynamic> map) {
    return BudgetModel(
      id: map['id'] as String,
      category: map['category'] as String,
      amount: (map['amount'] as num).toDouble(),
      month: map['month'] as int,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  BudgetModel copyWith({
    String? id,
    String? category,
    double? amount,
    int? month,
    DateTime? createdAt,
  }) {
    return BudgetModel(
      id: id ?? this.id,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      month: month ?? this.month,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
