import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../features/transactions/provider/transaction_provider.dart';
import '../features/transactions/model/transaction_model.dart';
import '../theme/app_theme.dart';
import '../core/utils/error_handler.dart';
import '../widgets/gradient_button.dart';
import '../core/widgets/success_overlay.dart';
import '../core/widgets/premium_pressable.dart';


class AddTransactionScreen extends ConsumerStatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  ConsumerState<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends ConsumerState<AddTransactionScreen> {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _descController = TextEditingController();
  String _selectedType = 'expense';
  String _selectedCategory = 'Food';
  String _selectedAccount = 'Primary';
  DateTime _selectedDate = DateTime.now();
  bool _isSubmitting = false;
  bool _showSuccessOverlay = false;


  final Map<String, IconData> _categoryIcons = {
    'Food': Icons.restaurant,
    'Transport': Icons.directions_car,
    'Shopping': Icons.shopping_bag,
    'Entertainment': Icons.movie,
    'Salary': Icons.payments,
    'Freelance': Icons.laptop,
    'Rent': Icons.home,
    'Health': Icons.medical_services,
    'Other': Icons.category,
  };

  final _accounts = ['Primary', 'Savings', 'Business', 'Credit Card'];

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
            colorScheme: ColorScheme.light(
              primary: _selectedType == 'income' ? AppTheme.emerald : AppTheme.rose,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _submit() async {
    if (_titleController.text.trim().isEmpty || _amountController.text.trim().isEmpty) {
      ErrorHandler.showError(context, 'Please fill in title and amount.');
      return;
    }

    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      ErrorHandler.showError(context, 'Please enter a valid amount.');
      return;
    }

    setState(() => _isSubmitting = true);
    HapticFeedback.heavyImpact();

    final tx = TransactionModel(
      title: _titleController.text.trim(),
      amount: amount,
      type: _selectedType,
      category: _selectedCategory,
      description: _descController.text.trim(),
      account: _selectedAccount,
      createdAt: _selectedDate,

    );

    final success = await ref.read(transactionProvider.notifier).addTransaction(tx);

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (success) {
      setState(() => _showSuccessOverlay = true);
    } else {
      ErrorHandler.showError(context, 'Vault insertion failed. Try again.');
    }
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accentColor = _selectedType == 'income' ? AppTheme.emerald : AppTheme.rose;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              accentColor.withValues(alpha: 0.08),
              AppTheme.background,
              AppTheme.background,
            ],
          ),
        ),
        child: Stack(
          children: [
            Column(
              children: [
                _buildAppBar(context, accentColor),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        _buildTypeToggle(accentColor),
                        const SizedBox(height: 40),
                        _buildAmountInput(accentColor),
                        const SizedBox(height: 40),
                        _buildSectionLabel('Transaction Details'),
                        _buildInputField(
                          controller: _titleController,
                          hint: 'What was this for?',
                          icon: Icons.edit_note,
                          accentColor: accentColor,
                        ),
                        const SizedBox(height: 16),
                        _buildDatePicker(accentColor),
                        const SizedBox(height: 32),
                        _buildSectionLabel('Select Category'),
                        _buildCategoryGrid(accentColor),
                        const SizedBox(height: 32),
                        _buildSectionLabel('Account Source'),
                        _buildAccountSelector(accentColor),
                        const SizedBox(height: 32),
                        _buildInputField(
                          controller: _descController,
                          hint: 'Add a note (optional)...',
                          icon: Icons.description_outlined,
                          maxLines: 2,
                          accentColor: accentColor,
                        ),
                        const SizedBox(height: 48),
                        _isSubmitting
                            ? Center(child: CircularProgressIndicator(color: accentColor))
                            : GradientButton(
                                text: 'Secure ${toBeginningOfSentenceCase(_selectedType)}',
                                onPressed: _submit,
                              ),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (_showSuccessOverlay)
              SuccessOverlay(
                message: 'Transaction Secured!',
                onComplete: () => Navigator.pop(context),
              ),
          ],
        ),
      ),

    );
  }

  Widget _buildAppBar(BuildContext context, Color accentColor) {
    return Container(
      padding: const EdgeInsets.only(top: 60, bottom: 20, left: 16, right: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: AppTheme.indigo, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          Text(
            'New ${toBeginningOfSentenceCase(_selectedType)}',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppTheme.indigo,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildTypeToggle(Color accentColor) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.borderLight.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          _buildTypeOption('Expense', 'expense', AppTheme.rose),
          _buildTypeOption('Income', 'income', AppTheme.emerald),
        ],
      ),
    );
  }

  Widget _buildTypeOption(String label, String value, Color color) {
    final isSelected = _selectedType == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _selectedType = value);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? color : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            boxShadow: isSelected
                ? [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))]
                : [],
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppTheme.textSecondary,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.normal,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAmountInput(Color accentColor) {
    return Column(
      children: [
        Text('AMOUNT', style: AppTheme.lightTheme.textTheme.labelSmall),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text('₹', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: accentColor)),
            const SizedBox(width: 8),
            IntrinsicWidth(
              child: TextField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 56,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.indigo,
                  letterSpacing: -2,
                ),
                decoration: const InputDecoration(
                  hintText: '0.00',
                  hintStyle: TextStyle(color: AppTheme.divider),
                  border: InputBorder.none,
                ),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        label.toUpperCase(),
        style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(letterSpacing: 1.5),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required Color accentColor,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderLight.withValues(alpha: 0.05)),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon, color: accentColor, size: 22),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildDatePicker(Color accentColor) {
    return GestureDetector(
      onTap: _selectDate,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: accentColor.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: accentColor.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, color: accentColor, size: 20),
            const SizedBox(width: 12),
            Text(
              DateFormat('EEEE, MMM dd, yyyy').format(_selectedDate),
              style: TextStyle(color: AppTheme.indigo, fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            Icon(Icons.edit, color: accentColor, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryGrid(Color accentColor) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.1,
      ),
      itemCount: _categoryIcons.length,
      itemBuilder: (context, index) {
        final category = _categoryIcons.keys.elementAt(index);
        final icon = _categoryIcons[category]!;
        final isSelected = _selectedCategory == category;

        return GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            setState(() => _selectedCategory = category);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isSelected ? accentColor.withValues(alpha: 0.1) : AppTheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isSelected ? accentColor : Colors.transparent),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: isSelected ? accentColor : AppTheme.textSecondary, size: 28),
                const SizedBox(height: 8),
                Text(
                  category,
                  style: TextStyle(
                    fontSize: 12,
                    color: isSelected ? accentColor : AppTheme.textSecondary,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAccountSelector(Color accentColor) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _accounts.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final account = _accounts[index];
          final isSelected = _selectedAccount == account;
          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _selectedAccount = account);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.indigo : AppTheme.surface,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Center(
                child: Text(
                  account,
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppTheme.textSecondary,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
