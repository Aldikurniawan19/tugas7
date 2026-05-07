import 'package:flutter/material.dart';
import '../models/transaction_model.dart';
import '../services/transaction_service.dart';

class TransactionFormPage extends StatefulWidget {
  final TransactionModel? transaction;

  const TransactionFormPage({super.key, this.transaction});

  @override
  _TransactionFormPageState createState() => _TransactionFormPageState();
}

class _TransactionFormPageState extends State<TransactionFormPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  String _selectedType = 'income';
  String? _selectedCategory;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  bool get _isEditing => widget.transaction != null;

  // Colors
  static const Color _primaryColor = Color(0xFF5465FF);
  static const Color _incomeColor = Color(0xFF00C853);
  static const Color _expenseColor = Color(0xFFE63946);
  static const Color _bgColor = Color(0xFFF5F7FA);
  static const Color _cardColor = Color(0xFFFFFFFF);
  static const Color _darkText = Color(0xFF1A1D29);

  final List<String> _incomeCategories = [
    'Gaji',
    'Bonus',
    'Investasi',
    'Freelance',
    'Lainnya',
  ];

  final List<String> _expenseCategories = [
    'Makan & Minum',
    'Transportasi',
    'Belanja',
    'Tagihan',
    'Hiburan',
    'Kesehatan',
    'Pendidikan',
    'Lainnya',
  ];

  List<String> get _categories =>
      _selectedType == 'income' ? _incomeCategories : _expenseCategories;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final t = widget.transaction!;
      _selectedType = t.type;
      _amountController.text = t.amount.toStringAsFixed(0);
      _selectedCategory = t.category;
      _descriptionController.text = t.description ?? '';
      try {
        _selectedDate = DateTime.parse(t.transactionDate);
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: _primaryColor,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: _darkText,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Pilih kategori terlebih dahulu"),
          backgroundColor: _expenseColor,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final transaction = TransactionModel(
      type: _selectedType,
      amount: double.tryParse(_amountController.text) ?? 0,
      category: _selectedCategory!,
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      transactionDate:
          "${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}",
    );

    try {
      if (_isEditing) {
        await TransactionService.updateTransaction(
            widget.transaction!.id!, transaction);
      } else {
        await TransactionService.createTransaction(transaction);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing
                ? "Transaksi berhasil diperbarui"
                : "Transaksi berhasil ditambahkan"),
            backgroundColor: _primaryColor,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                "Gagal: ${e.toString().replaceFirst('Exception: ', '')}"),
            backgroundColor: _expenseColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        title: Text(
          _isEditing ? "Edit Transaksi" : "Tambah Transaksi",
          style:
              const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: _primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Type selector
              _buildSectionLabel("Jenis Transaksi"),
              const SizedBox(height: 8),
              _buildTypeSelector(),
              const SizedBox(height: 24),

              // Amount
              _buildSectionLabel("Jumlah (Rp)"),
              const SizedBox(height: 8),
              _buildAmountField(),
              const SizedBox(height: 24),

              // Category
              _buildSectionLabel("Kategori"),
              const SizedBox(height: 8),
              _buildCategorySelector(),
              const SizedBox(height: 24),

              // Date
              _buildSectionLabel("Tanggal"),
              const SizedBox(height: 8),
              _buildDatePicker(),
              const SizedBox(height: 24),

              // Description
              _buildSectionLabel("Keterangan (opsional)"),
              const SizedBox(height: 8),
              _buildDescriptionField(),
              const SizedBox(height: 36),

              // Submit button
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: _darkText,
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Container(
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
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedType = 'income';
                  // Reset category if current one is not in income list
                  if (_selectedCategory != null &&
                      !_incomeCategories.contains(_selectedCategory)) {
                    _selectedCategory = null;
                  }
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: _selectedType == 'income'
                      ? _incomeColor
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.arrow_downward_rounded,
                      color: _selectedType == 'income'
                          ? Colors.white
                          : _darkText.withOpacity(0.4),
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "Pemasukan",
                      style: TextStyle(
                        color: _selectedType == 'income'
                            ? Colors.white
                            : _darkText.withOpacity(0.4),
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedType = 'expense';
                  if (_selectedCategory != null &&
                      !_expenseCategories.contains(_selectedCategory)) {
                    _selectedCategory = null;
                  }
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: _selectedType == 'expense'
                      ? _expenseColor
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.arrow_upward_rounded,
                      color: _selectedType == 'expense'
                          ? Colors.white
                          : _darkText.withOpacity(0.4),
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "Pengeluaran",
                      style: TextStyle(
                        color: _selectedType == 'expense'
                            ? Colors.white
                            : _darkText.withOpacity(0.4),
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountField() {
    return Container(
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
      child: TextFormField(
        controller: _amountController,
        keyboardType: TextInputType.number,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: _darkText,
        ),
        validator: (value) {
          if (value == null || value.isEmpty) return 'Jumlah wajib diisi';
          final amount = double.tryParse(value);
          if (amount == null || amount <= 0) return 'Masukkan jumlah yang valid';
          return null;
        },
        decoration: InputDecoration(
          hintText: "0",
          hintStyle: TextStyle(color: _darkText.withOpacity(0.25)),
          prefixIcon: Container(
            padding: const EdgeInsets.all(12),
            child: Text(
              "Rp",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: _primaryColor,
              ),
            ),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: _primaryColor, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: _expenseColor, width: 1),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: _expenseColor, width: 2),
          ),
        ),
      ),
    );
  }

  Widget _buildCategorySelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _categories.map((category) {
        final isSelected = _selectedCategory == category;
        final activeColor =
            _selectedType == 'income' ? _incomeColor : _expenseColor;
        return GestureDetector(
          onTap: () => setState(() => _selectedCategory = category),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? activeColor : _cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? activeColor : _darkText.withOpacity(0.1),
                width: 1.5,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: activeColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : [],
            ),
            child: Text(
              category,
              style: TextStyle(
                color: isSelected ? Colors.white : _darkText.withOpacity(0.7),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDatePicker() {
    return GestureDetector(
      onTap: _pickDate,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.calendar_today_rounded,
                color: _primaryColor,
                size: 18,
              ),
            ),
            const SizedBox(width: 14),
            Text(
              "${_selectedDate.day.toString().padLeft(2, '0')}/${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.year}",
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: _darkText,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.arrow_drop_down_rounded,
              color: _darkText.withOpacity(0.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDescriptionField() {
    return Container(
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
      child: TextFormField(
        controller: _descriptionController,
        maxLines: 3,
        style: const TextStyle(fontSize: 14, color: _darkText),
        decoration: InputDecoration(
          hintText: "Contoh: Beli makan siang di kantin",
          hintStyle: TextStyle(color: _darkText.withOpacity(0.3)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: _primaryColor, width: 2),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _submit,
      style: ElevatedButton.styleFrom(
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 4,
        shadowColor: _primaryColor.withOpacity(0.4),
      ),
      child: _isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
          : Text(
              _isEditing ? "Simpan Perubahan" : "Tambah Transaksi",
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
    );
  }
}
