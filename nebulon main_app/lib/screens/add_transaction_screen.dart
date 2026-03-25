import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../features/transactions/provider/transaction_provider.dart';
import '../features/dashboard/provider/dashboard_provider.dart';
import '../features/analytics/provider/analytics_provider.dart';
import '../features/transactions/model/transaction_model.dart';
import '../theme/app_theme.dart';
import '../core/utils/error_handler.dart';
import '../core/widgets/success_overlay.dart';

class AddTransactionScreen extends ConsumerStatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  ConsumerState<AddTransactionScreen> createState() =>
      _AddTransactionScreenState();
}

class _AddTransactionScreenState extends ConsumerState<AddTransactionScreen> {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _descController = TextEditingController();
  String _selectedType = 'expense';
  String _selectedCategory = 'Food';
  DateTime _selectedDate = DateTime.now();
  bool _isSubmitting = false;
  bool _showSuccessOverlay = false;

  final List<_CategoryItem> _categories = [
    _CategoryItem('Food', Icons.restaurant_rounded, Color(0xFFFF6B6B)),
    _CategoryItem('Transport', Icons.directions_car_rounded, Color(0xFF4ECDC4)),
    _CategoryItem('Shopping', Icons.shopping_bag_rounded, Color(0xFF845EC2)),
    _CategoryItem('Entertainment', Icons.movie_rounded, Color(0xFFFF9671)),
    _CategoryItem('Salary', Icons.payments_rounded, Color(0xFF00C9A7)),
    _CategoryItem('Freelance', Icons.laptop_rounded, Color(0xFF0081CF)),
    _CategoryItem('Rent', Icons.home_rounded, Color(0xFFC34A36)),
    _CategoryItem('Health', Icons.medical_services_rounded, Color(0xFF4D8076)),
    _CategoryItem('Other', Icons.more_horiz_rounded, Color(0xFF808080)),
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF5B5DF5)),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _submit() async {
    if (_titleController.text.trim().isEmpty ||
        _amountController.text.trim().isEmpty) {
      ErrorHandler.showError(context, 'Title and amount are required.');
      return;
    }

    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      ErrorHandler.showError(context, 'Enter a valid amount.');
      return;
    }

    setState(() => _isSubmitting = true);
    HapticFeedback.mediumImpact();

    final tx = TransactionModel(
      title: _titleController.text.trim(),
      amount: amount,
      type: _selectedType,
      category: _selectedCategory,
      description: _descController.text.trim(),
      account: 'Primary',
      createdAt: _selectedDate,
    );

    final success = await ref
        .read(transactionProvider.notifier)
        .addTransaction(tx);

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (success) {
      ref.read(dashboardProvider.notifier).loadDashboard();
      ref.read(analyticsProvider.notifier).loadAnalytics();
      setState(() => _showSuccessOverlay = true);
    } else {
      ErrorHandler.showError(context, 'Failed to save. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0F1117) : const Color(0xFFF7F8FC);
    final cardColor = isDark ? const Color(0xFF1A1D2E) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final subtextColor = isDark ? Colors.white54 : const Color(0xFF94A3B8);
    final borderColor = isDark
        ? Colors.white.withOpacity(0.08)
        : const Color(0xFFE2E8F0);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          _selectedType == 'income' ? 'New Income' : 'New Expense',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: textColor,
          ),
        ),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.close_rounded, color: subtextColor),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),

                // ── Type Toggle ──
                _buildTypeToggle(cardColor, borderColor),
                const SizedBox(height: 24),

                // ── Amount ──
                _buildAmountSection(
                  cardColor,
                  borderColor,
                  textColor,
                  subtextColor,
                ),
                const SizedBox(height: 20),

                // ── Title ──
                _buildInputCard(
                  cardColor: cardColor,
                  borderColor: borderColor,
                  textColor: textColor,
                  subtextColor: subtextColor,
                  label: 'Title',
                  hint: 'e.g. Coffee, Groceries, Salary...',
                  icon: Icons.edit_rounded,
                  controller: _titleController,
                ),
                const SizedBox(height: 16),

                // ── Category ──
                _buildLabel('Category', textColor),
                const SizedBox(height: 10),
                _buildCategoryChips(cardColor, borderColor, textColor),
                const SizedBox(height: 20),

                // ── Date ──
                _buildLabel('Date', textColor),
                const SizedBox(height: 10),
                _buildDateCard(cardColor, borderColor, textColor, subtextColor),
                const SizedBox(height: 16),

                // ── Notes ──
                _buildInputCard(
                  cardColor: cardColor,
                  borderColor: borderColor,
                  textColor: textColor,
                  subtextColor: subtextColor,
                  label: 'Notes',
                  hint: 'Optional description...',
                  icon: Icons.notes_rounded,
                  controller: _descController,
                ),
                const SizedBox(height: 32),

                // ── Submit ──
                _buildSubmitButton(),
                const SizedBox(height: 80),
              ],
            ),
          ),
          if (_showSuccessOverlay)
            SuccessOverlay(
              message: 'Transaction Saved!',
              onComplete: () => Navigator.pop(context),
            ),
        ],
      ),
    );
  }

  // ─────────────────────────── WIDGETS ───────────────────────────

  Widget _buildLabel(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildTypeToggle(Color cardColor, Color borderColor) {
    final isExpense = _selectedType == 'expense';
    return Container(
      height: 44,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: borderColor),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            alignment: isExpense ? Alignment.centerLeft : Alignment.centerRight,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF5B5DF5), Color(0xFF7C3AED)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
          Row(
            children: [
              _toggleTab('Expense', isExpense, true),
              _toggleTab('Income', !isExpense, false),
            ],
          ),
        ],
      ),
    );
  }

  Widget _toggleTab(String label, bool isActive, bool isLeft) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _selectedType = isLeft ? 'expense' : 'income');
        },
        child: Container(
          color: Colors.transparent,
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isActive ? Colors.white : const Color(0xFF94A3B8),
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAmountSection(
    Color cardColor,
    Color borderColor,
    Color textColor,
    Color subtextColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          Text(
            'AMOUNT',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: subtextColor,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '₹',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w300,
                  color: const Color(0xFF5B5DF5),
                ),
              ),
              const SizedBox(width: 4),
              IntrinsicWidth(
                child: TextField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                    letterSpacing: -1,
                  ),
                  decoration: InputDecoration(
                    hintText: '0',
                    hintStyle: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w800,
                      color: subtextColor.withOpacity(0.3),
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    isDense: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d+\.?\d{0,2}'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInputCard({
    required Color cardColor,
    required Color borderColor,
    required Color textColor,
    required Color subtextColor,
    required String label,
    required String hint,
    required IconData icon,
    required TextEditingController controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label, textColor),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child: TextField(
            controller: controller,
            style: TextStyle(color: textColor, fontSize: 14),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: subtextColor, fontSize: 14),
              prefixIcon: Icon(icon, size: 18, color: const Color(0xFF5B5DF5)),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryChips(
    Color cardColor,
    Color borderColor,
    Color textColor,
  ) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _categories.map((cat) {
        final isSelected = _selectedCategory == cat.name;
        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _selectedCategory = cat.name);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? cat.color.withOpacity(0.15) : cardColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isSelected ? cat.color : borderColor,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  cat.icon,
                  size: 16,
                  color: isSelected ? cat.color : const Color(0xFF94A3B8),
                ),
                const SizedBox(width: 6),
                Text(
                  cat.name,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? cat.color : textColor,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDateCard(
    Color cardColor,
    Color borderColor,
    Color textColor,
    Color subtextColor,
  ) {
    return GestureDetector(
      onTap: _selectDate,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_today_rounded,
              size: 18,
              color: Color(0xFF5B5DF5),
            ),
            const SizedBox(width: 12),
            Text(
              DateFormat('EEEE, MMM dd, yyyy').format(_selectedDate),
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: textColor,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 20,
              color: subtextColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: _isSubmitting
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF5B5DF5)),
            )
          : Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF5B5DF5), Color(0xFF7C3AED)],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF5B5DF5).withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.check_circle_outline_rounded,
                      size: 18,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Save ${_selectedType == 'income' ? 'Income' : 'Expense'}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: Colors.white,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _CategoryItem {
  final String name;
  final IconData icon;
  final Color color;
  const _CategoryItem(this.name, this.icon, this.color);
}
