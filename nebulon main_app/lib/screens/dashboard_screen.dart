import 'package:flutter/material.dart';
import '../core/utils/error_handler.dart';
import 'profile_screen.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/dashboard/provider/dashboard_provider.dart';
import '../theme/app_theme.dart';
import '../core/widgets/premium_pressable.dart';
import '../core/widgets/animated_counter.dart';
import '../features/profile/provider/profile_provider.dart';
import '../core/widgets/skeleton_loader.dart';
import '../core/network/sync_service.dart';
import '../widgets/kpi_card.dart';
import '../widgets/summary_card.dart';
import '../widgets/activity_item.dart';
import '../theme/theme_provider.dart';
import '../theme/theme_provider.dart';
import 'add_transaction_screen.dart';
import '../core/services/payment_service.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../features/transactions/model/transaction_model.dart';
import '../features/transactions/provider/transaction_provider.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  late PaymentService _paymentService;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await ref.read(transactionProvider.notifier).seedDummyData();
      ref.read(dashboardProvider.notifier).loadDashboard();
    });
    _paymentService = PaymentService(
      onSuccess: _handlePaymentSuccess,
      onFailure: _handlePaymentError,
      onWallet: _handleExternalWallet,
    );
  }

  @override
  void dispose() {
    _paymentService.dispose();
    super.dispose();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    final tx = TransactionModel(
      title: 'Added Funds',
      amount: 5000.0,
      type: 'income',
      category: 'Deposit',
      description: 'Razorpay Payment ID: ${response.paymentId}',
      account: 'Primary',
      createdAt: DateTime.now(),
    );
    await ref.read(transactionProvider.notifier).addTransaction(tx);
    ref.read(dashboardProvider.notifier).loadDashboard();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment Successful! Funds added to Vault.'),
        ),
      );
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    if (mounted) {
      ErrorHandler.showError(context, 'Payment failed: ${response.message}');
    }
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('External Wallet Selected: ${response.walletName}'),
        ),
      );
    }
  }

  void _startPayment() {
    _paymentService.openCheckout(
      amount: 5000.0,
      name: ref.read(profileProvider).profile?.fullName ?? 'Vault User',
      email: ref.read(profileProvider).profile?.email ?? 'demo@smartvault.com',
      defaultContact: '9876543210',
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(dashboardProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: RefreshIndicator(
        color: theme.colorScheme.primary,
        onRefresh: () => ref.read(dashboardProvider.notifier).loadDashboard(),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            _buildSliverAppBar(context),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              sliver: SliverToBoxAdapter(
                child: state.status == DashboardStatus.loading
                    ? SkeletonLoader.card(height: 160)
                    : (state.status == DashboardStatus.error
                          ? const SizedBox.shrink()
                          : _buildBalanceCard(context, state)),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              sliver: SliverToBoxAdapter(child: _buildQuickActions(context)),
            ),
            if (state.status == DashboardStatus.loaded)
              SliverPadding(
                padding: const EdgeInsets.all(24),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 1.1,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  delegate: SliverChildListDelegate([
                    SummaryCard(
                      title: 'Income',
                      value: state.data.totalIncome,
                      prefix: '₹',
                      percent: '+12%',
                      isPositive: true,
                    ),
                    SummaryCard(
                      title: 'Expenses',
                      value: state.data.totalExpenses,
                      prefix: '₹',
                      percent: '-5%',
                      isPositive: false,
                    ),
                    KpiCard(
                      title: 'Profitability',
                      value:
                          '${(state.data.profitMargin * 100).toStringAsFixed(1)}%',
                      progress: state.data.profitMargin.clamp(0.0, 1.0),
                      icon: Icons.auto_graph_rounded,
                      isAnimated: true,
                    ),
                    KpiCard(
                      title: 'Efficiency',
                      value:
                          '${(100 - (state.data.expenseRatio * 100)).toStringAsFixed(1)}%',
                      progress: (1.0 - state.data.expenseRatio).clamp(0.0, 1.0),
                      icon: Icons.bolt_rounded,
                      isAnimated: true,
                    ),
                  ]),
                ),
              ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  if (state.status == DashboardStatus.error)
                    ErrorHandler.buildErrorWidget(
                      state.errorMessage ?? 'Failed to load dashboard',
                      () =>
                          ref.read(dashboardProvider.notifier).loadDashboard(),
                    )
                  else if (state.status == DashboardStatus.loaded) ...[
                    _buildRecentActivity(context, state),
                    const SizedBox(height: 120),
                  ],
                ]),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const AddTransactionScreen()),
        ),
        backgroundColor: AppTheme.indigo,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'New Expense',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    final theme = Theme.of(context);
    final profileState = ref.watch(profileProvider);
    final name = profileState.profile?.fullName?.split(' ').first ?? 'Anuj';
    final isDark = theme.brightness == Brightness.dark;

    return SliverAppBar(
      expandedHeight: 120,
      floating: true,
      pinned: true,
      elevation: 0,
      backgroundColor: theme.scaffoldBackgroundColor,
      surfaceTintColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.symmetric(
          horizontal: AppTheme.s24,
          vertical: 16,
        ),
        centerTitle: false,
        title: Text(
          'Hey, $name',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppTheme.indigo,
          ),
        ),
      ),
      actions: [
        IconButton(
          onPressed: () {
            HapticFeedback.lightImpact();
            final currentMode = ref.read(themeProvider);
            ref
                .read(themeProvider.notifier)
                .setThemeMode(
                  currentMode == ThemeMode.dark
                      ? ThemeMode.light
                      : ThemeMode.dark,
                );
          },
          icon: Icon(
            isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
            color: isDark ? Colors.white70 : AppTheme.indigo,
          ),
        ),
        IconButton(
          onPressed: () async {
            HapticFeedback.mediumImpact();
            ErrorHandler.showSuccess(context, 'Syncing Vault...');
            await ref.read(syncServiceProvider).syncPendingActions();
            await ref.read(dashboardProvider.notifier).loadDashboard();
          },
          icon: Icon(
            Icons.sync_rounded,
            color: isDark ? Colors.white70 : AppTheme.indigo,
          ),
        ),
        const SizedBox(width: AppTheme.s8),
      ],
      leading: Padding(
        padding: const EdgeInsets.all(AppTheme.s8),
        child: PremiumPressable(
          onTap: () => Navigator.of(context).push(_createProfileRoute()),
          child: Hero(
            tag: 'profile_avatar',
            child: CircleAvatar(
              backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
              child: const Icon(Icons.person, color: AppTheme.indigo, size: 20),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceCard(BuildContext context, DashboardState state) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.s24),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.indigo.withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Global Vault Balance',
            style: theme.textTheme.labelMedium?.copyWith(
              color: Colors.white70,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppTheme.s8),
          AnimatedCounter(
            value: state.data.balance,
            prefix: '₹',
            style: theme.textTheme.displayLarge?.copyWith(
              color: Colors.white,
              fontSize: 36,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: AppTheme.s16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.s8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.security_rounded,
                      color: Colors.white,
                      size: 12,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'AES-256 SECURED',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                '${state.data.transactionCount} entries',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: Colors.white60,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Bank connection simulated.')),
              );
            },
            icon: const Icon(Icons.account_balance_rounded, size: 18),
            label: const Text('Connect Bank', style: TextStyle(fontSize: 13)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).cardColor,
              foregroundColor: AppTheme.indigo,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: AppTheme.indigo.withOpacity(0.1)),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _startPayment,
            icon: const Icon(Icons.add_card_rounded, size: 18),
            label: const Text('Add Funds', style: TextStyle(fontSize: 13)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.indigo,
              foregroundColor: Colors.white,
              elevation: 4,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentActivity(BuildContext context, DashboardState state) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Activity',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {},
              child: Text(
                'View All',
                style: TextStyle(color: theme.colorScheme.primary),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.s8),
        if (state.data.recentTransactions.isEmpty)
          ErrorHandler.buildEmptyWidget('No data in the vault yet.')
        else
          ...state.data.recentTransactions.asMap().entries.map((entry) {
            final tx = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: AppTheme.s12),
              child: PremiumPressable(
                child: ActivityItem(
                  title: tx.title,
                  subtitle: '${tx.category} • ${tx.timeAgo}',
                  amount: tx.formattedAmount,
                  isNegative: tx.isExpense,
                  status: tx.status,
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildSkeletonDashboard() {
    return Column(
      children: [
        const SizedBox(height: AppTheme.s24),
        SkeletonLoader.card(height: 160),
        const SizedBox(height: AppTheme.s32),
        Row(
          children: [
            Expanded(child: SkeletonLoader.card(height: 100)),
            const SizedBox(width: 16),
            Expanded(child: SkeletonLoader.card(height: 100)),
          ],
        ),
        const SizedBox(height: AppTheme.s16),
        Row(
          children: [
            Expanded(child: SkeletonLoader.card(height: 100)),
            const SizedBox(width: 16),
            Expanded(child: SkeletonLoader.card(height: 100)),
          ],
        ),
      ],
    );
  }

  Route _createProfileRoute() {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) =>
          const ProfileScreen(),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }
}
