import 'package:flutter/material.dart';
import '../models/transaction_model.dart';
import '../services/transaction_service.dart';
import 'transaction_form_page.dart';

class TransactionPage extends StatefulWidget {
  @override
  _TransactionPageState createState() => _TransactionPageState();
}

class _TransactionPageState extends State<TransactionPage>
    with SingleTickerProviderStateMixin {
  List<TransactionModel> _transactions = [];
  Map<String, dynamic> _summary = {
    'total_income': 0.0,
    'total_expense': 0.0,
    'balance': 0.0,
  };
  bool _isLoading = true;
  late TabController _tabController;

  // Colors
  static const Color _primaryColor = Color(0xFF5465FF);
  static const Color _incomeColor = Color(0xFF00C853);
  static const Color _expenseColor = Color(0xFFE63946);
  static const Color _bgColor = Color(0xFFF5F7FA);
  static const Color _cardColor = Color(0xFFFFFFFF);
  static const Color _darkText = Color(0xFF1A1D29);

  String? _currentFilter;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    switch (_tabController.index) {
      case 0:
        _currentFilter = null;
        break;
      case 1:
        _currentFilter = 'income';
        break;
      case 2:
        _currentFilter = 'expense';
        break;
    }
    _loadTransactions();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    await Future.wait([_loadSummary(), _loadTransactions()]);
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _loadSummary() async {
    try {
      final summary = await TransactionService.getSummary();
      if (mounted) setState(() => _summary = summary);
    } catch (e) {
      // silently fail
    }
  }

  Future<void> _loadTransactions() async {
    try {
      final transactions =
          await TransactionService.getTransactions(type: _currentFilter);
      if (mounted) setState(() => _transactions = transactions);
    } catch (e) {
      // silently fail
    }
  }

  void _navigateToForm({TransactionModel? transaction}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            TransactionFormPage(transaction: transaction),
      ),
    );
    if (result == true) {
      _loadData();
    }
  }

  void _deleteTransaction(TransactionModel transaction) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          "Hapus Transaksi",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text("Apakah Anda yakin ingin menghapus transaksi ini?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              "Batal",
              style: TextStyle(color: _darkText.withOpacity(0.6)),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _expenseColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child:
                const Text("Hapus", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await TransactionService.deleteTransaction(transaction.id!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text("Transaksi berhasil dihapus"),
              backgroundColor: _primaryColor,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
          );
          _loadData();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Gagal menghapus: ${e.toString().replaceFirst('Exception: ', '')}"),
              backgroundColor: _expenseColor,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  String _formatCurrency(double amount) {
    String formatted = amount.toStringAsFixed(0);
    String result = '';
    int count = 0;
    for (int i = formatted.length - 1; i >= 0; i--) {
      count++;
      result = formatted[i] + result;
      if (count % 3 == 0 && i != 0) {
        result = '.$result';
      }
    }
    return 'Rp $result';
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'gaji':
        return Icons.work_rounded;
      case 'bonus':
        return Icons.card_giftcard_rounded;
      case 'investasi':
        return Icons.trending_up_rounded;
      case 'freelance':
        return Icons.laptop_mac_rounded;
      case 'makan & minum':
        return Icons.restaurant_rounded;
      case 'transportasi':
        return Icons.directions_car_rounded;
      case 'belanja':
        return Icons.shopping_bag_rounded;
      case 'tagihan':
        return Icons.receipt_long_rounded;
      case 'hiburan':
        return Icons.movie_rounded;
      case 'kesehatan':
        return Icons.medical_services_rounded;
      case 'pendidikan':
        return Icons.school_rounded;
      default:
        return Icons.attach_money_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        title: const Text(
          "Pencatatan Uang",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: _primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: "Semua"),
            Tab(text: "Masuk"),
            Tab(text: "Keluar"),
          ],
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: _primaryColor))
          : RefreshIndicator(
              color: _primaryColor,
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildSummaryCards(),
                  const SizedBox(height: 20),
                  _buildTransactionHeader(),
                  const SizedBox(height: 12),
                  _buildTransactionList(),
                ],
              ),
            ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80.0),
        child: FloatingActionButton.extended(
          onPressed: () => _navigateToForm(),
          backgroundColor: _primaryColor,
          icon: const Icon(Icons.add_rounded, color: Colors.white),
          label: const Text(
            "Tambah",
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.w600),
          ),
          elevation: 4,
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Column(
      children: [
        // Balance Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF5465FF), Color(0xFF788BFF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: _primaryColor.withOpacity(0.3),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    "Total Saldo",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                _formatCurrency(
                    (_summary['balance'] as num?)?.toDouble() ?? 0),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Income & Expense row
        Row(
          children: [
            Expanded(
              child: _buildMiniCard(
                icon: Icons.arrow_downward_rounded,
                label: "Pemasukan",
                amount: (_summary['total_income'] as num?)?.toDouble() ?? 0,
                color: _incomeColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMiniCard(
                icon: Icons.arrow_upward_rounded,
                label: "Pengeluaran",
                amount: (_summary['total_expense'] as num?)?.toDouble() ?? 0,
                color: _expenseColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMiniCard({
    required IconData icon,
    required String label,
    required double amount,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _darkText.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: _darkText.withOpacity(0.6),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _formatCurrency(amount),
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          "Riwayat Transaksi",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: _darkText,
          ),
        ),
        Text(
          "${_transactions.length} transaksi",
          style: TextStyle(
            fontSize: 13,
            color: _darkText.withOpacity(0.5),
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionList() {
    if (_transactions.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          children: [
            Icon(
              Icons.receipt_long_rounded,
              size: 64,
              color: _darkText.withOpacity(0.15),
            ),
            const SizedBox(height: 16),
            Text(
              "Belum ada transaksi",
              style: TextStyle(
                fontSize: 16,
                color: _darkText.withOpacity(0.5),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "Tekan tombol + untuk menambahkan",
              style: TextStyle(
                fontSize: 13,
                color: _darkText.withOpacity(0.35),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: _transactions.map((t) => _buildTransactionItem(t)).toList(),
    );
  }

  Widget _buildTransactionItem(TransactionModel transaction) {
    final isIncome = transaction.type == 'income';
    final color = isIncome ? _incomeColor : _expenseColor;
    final sign = isIncome ? '+' : '-';

    return Dismissible(
      key: Key(transaction.id.toString()),
      background: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: _primaryColor,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        child: const Icon(Icons.edit_rounded, color: Colors.white),
      ),
      secondaryBackground: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: _expenseColor,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_rounded, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          _navigateToForm(transaction: transaction);
          return false;
        } else {
          _deleteTransaction(transaction);
          return false;
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: _cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: _darkText.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _getCategoryIcon(transaction.category),
              color: color,
              size: 22,
            ),
          ),
          title: Text(
            transaction.category,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: _darkText,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              transaction.description?.isNotEmpty == true
                  ? transaction.description!
                  : transaction.transactionDate,
              style: TextStyle(
                fontSize: 12,
                color: _darkText.withOpacity(0.5),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "$sign${_formatCurrency(transaction.amount)}",
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                transaction.transactionDate,
                style: TextStyle(
                  fontSize: 11,
                  color: _darkText.withOpacity(0.4),
                ),
              ),
            ],
          ),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          onTap: () => _navigateToForm(transaction: transaction),
        ),
      ),
    );
  }
}
