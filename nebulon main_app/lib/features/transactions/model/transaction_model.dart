import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

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
  final String syncStatus; // 'PENDING' or 'SYNCED'
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
    this.syncStatus = 'SYNCED',
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
    String? syncStatus,
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
      syncStatus: syncStatus ?? this.syncStatus,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    final rawType = (json['type'] ?? 'expense').toString().toLowerCase();
    String mappedType = 'expense';
    if (rawType == 'income' || rawType == 'credit') {
      mappedType = 'income';
    } else if (rawType == 'expense' || rawType == 'debit') {
      mappedType = 'expense';
    }

    return TransactionModel(
      id: json['id']?.toString(),
      userId: json['user_id']?.toString(),
      title: json['title'] ?? 'Untitled',
      amount: (json['amount'] ?? 0).toDouble(),
      type: mappedType,
      category: json['category'] ?? 'Other',
      description: json['description'],
      account: json['account'] ?? 'Primary',
      status: json['status'] ?? 'completed',
      syncStatus: json['sync_status'] ?? 'SYNCED',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id ?? const Uuid().v4(),
    'title': title,
    'amount': amount,
    'type': type == 'income' ? 'CREDIT' : 'DEBIT',
    'category': category,
    'description': description ?? '',
    'account': account,
    'sync_status': syncStatus,
  };

  bool get isExpense => type == 'expense';
  bool get isIncome => type == 'income';

  String get formattedAmount => isExpense
      ? '-₹${amount.toStringAsFixed(0)}'
      : '+₹${amount.toStringAsFixed(0)}';
  String get timeAgo {
    if (createdAt == null) return '';
    final diff = DateTime.now().difference(createdAt!);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
