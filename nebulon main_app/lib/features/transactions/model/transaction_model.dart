class TransactionModel {
  final String? id;
  final String? userId;
  final String title;
  final double amount;
  final String type; // 'income' or 'expense'
  final String category;
  final String? description;
  final String account;
  final String status;
  final DateTime? createdAt;

  const TransactionModel({
    this.id,
    this.userId,
    required this.title,
    required this.amount,
    required this.type,
    this.category = 'Other',
    this.description,
    this.account = 'Primary',
    this.status = 'completed',
    this.createdAt,
  });

  TransactionModel copyWith({
    String? id,
    String? userId,
    String? title,
    double? amount,
    String? type,
    String? category,
    String? description,
    String? account,
    String? status,
    DateTime? createdAt,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      category: category ?? this.category,
      description: description ?? this.description,
      account: account ?? this.account,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id']?.toString(),
      userId: json['user_id']?.toString(),
      title: json['title'] ?? 'Untitled',
      amount: (json['amount'] ?? 0).toDouble(),
      type: json['type'] ?? 'expense',
      category: json['category'] ?? 'Other',
      description: json['description'],
      account: json['account'] ?? 'Primary',
      status: json['status'] ?? 'completed',
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'amount': amount,
        'type': type,
        'category': category,
        'description': description,
        'account': account,
        'status': status,
      };

  bool get isExpense => type == 'expense';
  bool get isIncome => type == 'income';

  String get formattedAmount => isExpense ? '-₹${amount.toStringAsFixed(0)}' : '+₹${amount.toStringAsFixed(0)}';
  String get timeAgo {
    if (createdAt == null) return '';
    final diff = DateTime.now().difference(createdAt!);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
