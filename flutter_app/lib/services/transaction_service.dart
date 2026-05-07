import '../models/transaction_model.dart';
import 'api_service.dart';

class TransactionService {
  /// GET /api/transactions — List semua transaksi user
  static Future<List<TransactionModel>> getTransactions({String? type}) async {
    String endpoint = 'transactions';
    if (type != null) {
      endpoint += '?type=$type';
    }
    final data = await ApiService.get(endpoint);
    final List list = data['data'] ?? [];
    return list.map((json) => TransactionModel.fromJson(json)).toList();
  }

  /// POST /api/transactions — Tambah transaksi baru
  static Future<TransactionModel> createTransaction(TransactionModel transaction) async {
    final data = await ApiService.authPost('transactions', transaction.toJson());
    return TransactionModel.fromJson(data['data']);
  }

  /// PUT /api/transactions/{id} — Update transaksi
  static Future<TransactionModel> updateTransaction(int id, TransactionModel transaction) async {
    final data = await ApiService.put('transactions/$id', transaction.toJson());
    return TransactionModel.fromJson(data['data']);
  }

  /// DELETE /api/transactions/{id} — Hapus transaksi
  static Future<void> deleteTransaction(int id) async {
    await ApiService.delete('transactions/$id');
  }

  /// GET /api/transactions/summary — Ringkasan
  static Future<Map<String, dynamic>> getSummary() async {
    final data = await ApiService.get('transactions/summary');
    return data['data'];
  }
}
