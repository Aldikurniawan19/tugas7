class TransactionModel {
  final int? id;
  final String type;
  final double amount;
  final String category;
  final String? description;
  final String transactionDate;
  final String? createdAt;

  TransactionModel({
    this.id,
    required this.type,
    required this.amount,
    required this.category,
    this.description,
    required this.transactionDate,
    this.createdAt,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'],
      type: json['type'] ?? '',
      amount: double.tryParse(json['amount'].toString()) ?? 0,
      category: json['category'] ?? '',
      description: json['description'],
      transactionDate: json['transaction_date'] ?? '',
      createdAt: json['created_at'],
    );
  }

  Map<String, String> toJson() {
    return {
      'type': type,
      'amount': amount.toString(),
      'category': category,
      'description': description ?? '',
      'transaction_date': transactionDate,
    };
  }
}
