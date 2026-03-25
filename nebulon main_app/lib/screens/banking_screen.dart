import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/profile/provider/bank_provider.dart';
import '../theme/app_theme.dart';
import '../core/widgets/premium_pressable.dart';
import '../core/widgets/shimmer_loader.dart';
import '../core/utils/error_handler.dart';
import 'package:uuid/uuid.dart';

class BankingScreen extends ConsumerStatefulWidget {
  const BankingScreen({super.key});

  @override
  ConsumerState<BankingScreen> createState() => _BankingScreenState();
}

class _BankingScreenState extends ConsumerState<BankingScreen> {
  final _bankNameController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _ifscCodeController = TextEditingController();
  final _holderNameController = TextEditingController();
  final _uuid = const Uuid();

  @override
  void dispose() {
    _bankNameController.dispose();
    _accountNumberController.dispose();
    _ifscCodeController.dispose();
    _holderNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(bankProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text('Banking Center', style: theme.textTheme.headlineMedium),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppTheme.indigo,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(bankProvider.notifier).fetchAccounts(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CONNECTED ACCOUNTS',
                style: AppTheme.lightTheme.textTheme.labelSmall,
              ),
              const SizedBox(height: 16),
              if (state.isLoading)
                _buildSkeleton()
              else if (state.accounts.isEmpty)
                _buildEmptyState()
              else
                ...state.accounts.map((bank) => _buildBankCard(bank)),
              const SizedBox(height: 32),
              PremiumPressable(
                onTap: () => _showAddBankSheet(context),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.indigo.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: AppTheme.indigo.withOpacity(0.1),
                      style: BorderStyle.none,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.add_circle_outline_rounded,
                        color: AppTheme.indigo,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'ADD NEW BANK ACCOUNT',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: AppTheme.indigo,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 120),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBankCard(BankAccount bank) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: bank.isPrimary ? AppTheme.primaryGradient : null,
        color: bank.isPrimary ? null : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                bank.bankName.toUpperCase(),
                style: TextStyle(
                  color: bank.isPrimary
                      ? Colors.white70
                      : AppTheme.textSecondary,
                  letterSpacing: 1.2,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.delete_outline_rounded,
                  color: bank.isPrimary ? Colors.white70 : AppTheme.rose,
                  size: 20,
                ),
                onPressed: () => _confirmDelete(bank),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            bank.accountNumber.replaceAll(RegExp(r'.(?=.{4})'), '•'),
            style: TextStyle(
              color: bank.isPrimary ? Colors.white : AppTheme.indigo,
              fontSize: 20,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'HOLDER NAME',
                    style: TextStyle(
                      color: bank.isPrimary ? Colors.white60 : Colors.black38,
                      fontSize: 8,
                    ),
                  ),
                  Text(
                    bank.holderName,
                    style: TextStyle(
                      color: bank.isPrimary
                          ? Colors.white
                          : AppTheme.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'IFSC CODE',
                    style: TextStyle(
                      color: bank.isPrimary ? Colors.white60 : Colors.black38,
                      fontSize: 8,
                    ),
                  ),
                  Text(
                    bank.ifscCode,
                    style: TextStyle(
                      color: bank.isPrimary
                          ? Colors.white
                          : AppTheme.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(
            Icons.account_balance_rounded,
            size: 64,
            color: AppTheme.indigo.withOpacity(0.1),
          ),
          const SizedBox(height: 24),
          Text(
            'No bank accounts linked',
            style: AppTheme.lightTheme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          const Text(
            'Link your bank account to start managing your vaults efficiently.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeleton() {
    return Column(
      children: [
        ShimmerLoader(width: double.infinity, height: 180, borderRadius: 24),
        const SizedBox(height: 16),
        ShimmerLoader(width: double.infinity, height: 180, borderRadius: 24),
      ],
    );
  }

  void _confirmDelete(BankAccount bank) {
    HapticFeedback.vibrate();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account?'),
        content: Text(
          'Are you sure you want to remove ${bank.bankName} account?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              ref.read(bankProvider.notifier).deleteAccount(bank.id);
              Navigator.pop(context);
              ErrorHandler.showSuccess(context, 'Account disconnected');
            },
            child: const Text('DELETE', style: TextStyle(color: AppTheme.rose)),
          ),
        ],
      ),
    );
  }

  void _showAddBankSheet(BuildContext context) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'LINK BANK ACCOUNT',
                style: AppTheme.lightTheme.textTheme.labelSmall,
              ),
              const SizedBox(height: 24),
              _buildField(
                'Bank Name',
                _bankNameController,
                Icons.account_balance,
              ),
              const SizedBox(height: 16),
              _buildField(
                'Account Number',
                _accountNumberController,
                Icons.numbers,
              ),
              const SizedBox(height: 16),
              _buildField('IFSC Code', _ifscCodeController, Icons.code),
              const SizedBox(height: 16),
              _buildField(
                'Holder Name',
                _holderNameController,
                Icons.person_outline,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    if (_bankNameController.text.isEmpty) return;
                    final newBank = BankAccount(
                      id: _uuid.v4(),
                      bankName: _bankNameController.text,
                      accountNumber: _accountNumberController.text,
                      ifscCode: _ifscCodeController.text,
                      holderName: _holderNameController.text,
                      isPrimary: ref.read(bankProvider).accounts.isEmpty,
                    );
                    ref.read(bankProvider.notifier).addAccount(newBank);
                    Navigator.pop(context);
                    ErrorHandler.showSuccess(
                      context,
                      'Bank Linked Successfully',
                    );
                    _bankNameController.clear();
                    _accountNumberController.clear();
                    _ifscCodeController.clear();
                    _holderNameController.clear();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.indigo,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'CONFIRM LINK',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController controller,
    IconData icon,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: AppTheme.indigo, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 12,
          ),
        ),
      ),
    );
  }
}
