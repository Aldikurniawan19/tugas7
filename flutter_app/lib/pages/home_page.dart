import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/transaction_service.dart';
import '../models/user_model.dart';
import '../models/transaction_model.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  User? user;
  List<TransactionModel> _allTransactions = [];
  List<TransactionModel> _expenses = [];
  TransactionModel? _highestExpense;
  Map<String, dynamic> _summary = {
    'total_income': 0.0,
    'total_expense': 0.0,
    'balance': 0.0,
  };
  bool _isLoading = true;

  static const Color _primaryColor = Color(0xFF5465FF);
  static const Color _incomeColor = Color(0xFF00C853);
  static const Color _expenseColor = Color(0xFFE63946);
  static const Color _darkText = Color(0xFF1A1D29);
  static const Color _bgColor = Color(0xFFF5F7FA);
  static const Color _cardColor = Color(0xFFFFFFFF);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final fetchedUser = await AuthService.getUser();
      final transactions = await TransactionService.getTransactions();
      final summary = await TransactionService.getSummary();

      final expenses = transactions.where((t) => t.type == 'expense').toList();

      TransactionModel? highest;
      if (expenses.isNotEmpty) {
        highest = expenses.reduce(
          (curr, next) => curr.amount > next.amount ? curr : next,
        );
      }

      if (mounted) {
        setState(() {
          user = fetchedUser;
          _allTransactions = transactions;
          _expenses = expenses;
          _highestExpense = highest;
          _summary = summary;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
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
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: _primaryColor))
          : RefreshIndicator(
              color: _primaryColor,
              onRefresh: _loadData,
              child: CustomScrollView(
                slivers: [
                  // Gradient header
                  SliverToBoxAdapter(child: _buildHeader()),
                  // Balance card overlapping header
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                      child: _buildBalanceCard(),
                    ),
                  ),
                  // Highest expense
                  if (_highestExpense != null)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                        child: _buildHighestExpenseCard(),
                      ),
                    ),
                  // Expense list header
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Daftar Pengeluaran",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: _darkText,
                            ),
                          ),
                          Text(
                            "${_expenses.length} transaksi",
                            style: TextStyle(
                              fontSize: 13,
                              color: _darkText.withOpacity(0.45),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Expense list
                  _expenses.isEmpty
                      ? SliverToBoxAdapter(child: _buildEmptyState())
                      : SliverPadding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) =>
                                  _buildExpenseItem(_expenses[index]),
                              childCount: _expenses.length,
                            ),
                          ),
                        ),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 56, 24, 50),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF5465FF), Color(0xFF788BFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Halo, ${user?.name.split(' ').first ?? ''}!",
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Ringkasan keuanganmu hari ini",
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.75),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCard() {
    final balance = (_summary['balance'] as num?)?.toDouble() ?? 0;
    final income = (_summary['total_income'] as num?)?.toDouble() ?? 0;
    final expense = (_summary['total_expense'] as num?)?.toDouble() ?? 0;

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _darkText.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Sisa Uang
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_rounded,
                  color: _primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Sisa Uang",
                    style: TextStyle(
                      fontSize: 13,
                      color: _darkText.withOpacity(0.5),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatCurrency(balance),
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: balance >= 0 ? _primaryColor : _expenseColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: _darkText.withOpacity(0.06), height: 1),
          const SizedBox(height: 16),
          // Income & Expense row
          Row(
            children: [
              Expanded(
                child: _buildMiniStat(
                  icon: Icons.arrow_downward_rounded,
                  label: "Pemasukan",
                  amount: income,
                  color: _incomeColor,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: _darkText.withOpacity(0.06),
              ),
              Expanded(
                child: _buildMiniStat(
                  icon: Icons.arrow_upward_rounded,
                  label: "Pengeluaran",
                  amount: expense,
                  color: _expenseColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat({
    required IconData icon,
    required String label,
    required double amount,
    required Color color,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: _darkText.withOpacity(0.45),
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              _formatCurrency(amount),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHighestExpenseCard() {
    final t = _highestExpense!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.local_fire_department_rounded,
              color: _expenseColor,
              size: 22,
            ),
            const SizedBox(width: 6),
            const Text(
              "Pengeluaran Tertinggi",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _darkText,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFE63946), Color(0xFFFF6B6B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: _expenseColor.withOpacity(0.3),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  _getCategoryIcon(t.category),
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.category,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (t.description?.isNotEmpty == true)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          t.description!,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.75),
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    const SizedBox(height: 6),
                    Text(
                      t.transactionDate,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                "-${_formatCurrency(t.amount)}",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 50),
      child: Column(
        children: [
          Icon(
            Icons.receipt_long_rounded,
            size: 56,
            color: _darkText.withOpacity(0.12),
          ),
          const SizedBox(height: 14),
          Text(
            "Belum ada pengeluaran",
            style: TextStyle(
              fontSize: 16,
              color: _darkText.withOpacity(0.45),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Catat pengeluaranmu di tab Keuangan",
            style: TextStyle(fontSize: 13, color: _darkText.withOpacity(0.3)),
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseItem(TransactionModel transaction) {
    return Container(
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _expenseColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            _getCategoryIcon(transaction.category),
            color: _expenseColor,
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
            style: TextStyle(fontSize: 12, color: _darkText.withOpacity(0.5)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              "-${_formatCurrency(transaction.amount)}",
              style: const TextStyle(
                color: _expenseColor,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              transaction.transactionDate,
              style: TextStyle(fontSize: 11, color: _darkText.withOpacity(0.4)),
            ),
          ],
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
