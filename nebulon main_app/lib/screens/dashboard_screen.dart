import 'package:flutter/material.dart';
import 'profile_screen.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/dashboard/provider/dashboard_provider.dart';
import '../theme/app_theme.dart';
import '../core/utils/error_handler.dart';
import '../widgets/kpi_card.dart';
import '../widgets/summary_card.dart';
import '../widgets/activity_item.dart';


class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Load data on first build
    Future.microtask(() => ref.read(dashboardProvider.notifier).loadDashboard());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(dashboardProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: RefreshIndicator(
        color: AppTheme.indigo,
        onRefresh: () => ref.read(dashboardProvider.notifier).loadDashboard(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              _buildAppBar(context),
              if (state.status == DashboardStatus.loading)
                _buildSkeletonDashboard()
              else if (state.status == DashboardStatus.error)

                ErrorHandler.buildErrorWidget(
                  state.errorMessage ?? 'Failed to load dashboard',
                  () => ref.read(dashboardProvider.notifier).loadDashboard(),
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 32),
                      // KPI Row
                      Row(
                        children: [
                          Expanded(
                            child: PremiumPressable(
                              child: KpiCard(
                                title: 'Profit Margin',
                                value: '${(state.data.profitMargin * 100).toStringAsFixed(1)}%',
                                progress: state.data.profitMargin.clamp(0.0, 1.0),
                                icon: Icons.trending_up,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: PremiumPressable(
                              child: KpiCard(
                                title: 'Expense Ratio',
                                value: '${(state.data.expenseRatio * 100).toStringAsFixed(1)}%',
                                progress: state.data.expenseRatio.clamp(0.0, 1.0),
                                icon: Icons.pie_chart,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // Summary Cards
                      Row(
                        children: [
                          Expanded(
                            child: PremiumPressable(
                              child: SummaryCard(
                                title: 'Total Income',
                                value: '₹${state.data.totalIncome.toStringAsFixed(0)}',
                                percent: '+12%',
                                isPositive: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: PremiumPressable(
                              child: SummaryCard(
                                title: 'Total Expenses',
                                value: '₹${state.data.totalExpenses.toStringAsFixed(0)}',
                                percent: '-5%',
                                isPositive: false,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(color: AppTheme.indigo.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 10))
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Net Balance', style: theme.textTheme.labelMedium?.copyWith(color: Colors.white70)),
                            const SizedBox(height: 8),
                            AnimatedCounter(
                              value: state.data.balance,
                              prefix: '₹',
                              style: theme.textTheme.displayLarge?.copyWith(color: Colors.white),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${state.data.transactionCount} transactions encrypted',
                              style: theme.textTheme.labelSmall?.copyWith(color: AppTheme.mint, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),
                      // Recent Activity
                      Text('Recent Activity', style: theme.textTheme.headlineLarge),
                      const SizedBox(height: 16),
                      if (state.data.recentTransactions.isEmpty)
                        ErrorHandler.buildEmptyWidget('No transactions yet.\nAdd your first one!')
                      else
                        ...state.data.recentTransactions.map((tx) => ActivityItem(
                              title: tx.title,
                              subtitle: '${tx.category} • ${tx.timeAgo}',
                              amount: tx.formattedAmount,
                              isNegative: tx.isExpense,
                              status: tx.status,
                            )),
                      const SizedBox(height: 120),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSkeletonDashboard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(child: SkeletonLoader.card(height: 100)),
              const SizedBox(width: 16),
              Expanded(child: SkeletonLoader.card(height: 100)),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: SkeletonLoader.card(height: 120)),
              const SizedBox(width: 16),
              Expanded(child: SkeletonLoader.card(height: 120)),
            ],
          ),
          const SizedBox(height: 32),
          SkeletonLoader.card(height: 140),
          const SizedBox(height: 32),
          const SkeletonLoader(width: 150, height: 24),
          const SizedBox(height: 16),
          SkeletonLoader.listTile(),
          SkeletonLoader.listTile(),
          SkeletonLoader.listTile(),
        ],
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  Widget _buildAppBar(BuildContext context) {
    final profileState = ref.watch(profileProvider);
    final name = profileState.profile?.fullName?.split(' ').first ?? 'Anuj';
    
    return Container(
      padding: const EdgeInsets.only(top: 60, bottom: 20, left: 24, right: 24),
      color: AppTheme.background,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              PremiumPressable(
                onTap: () => Navigator.of(context).push(_createProfileRoute()),
                child: Hero(
                  tag: 'profile_avatar',
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.indigo.withValues(alpha: 0.1), width: 2),
                    ),
                    child: const CircleAvatar(
                      radius: 18,
                      backgroundColor: AppTheme.indigo,
                      child: Icon(Icons.person, color: Colors.white, size: 20),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_getGreeting(), style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppTheme.textSecondary, letterSpacing: 1.2)),
                  Text(name, style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: AppTheme.indigo, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.sync_rounded, color: AppTheme.indigo),
            onPressed: () async {
              HapticFeedback.mediumImpact();
              ErrorHandler.showSuccess(context, 'Synchronizing Vault...');
              await ref.read(syncServiceProvider).syncPendingActions();
              await ref.read(dashboardProvider.notifier).loadDashboard();
            },
          ),
        ],
      ),
    );
  }

  Route _createProfileRoute() {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => const ProfileScreen(),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.0, 0.1),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutQuint)),
            child: child,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 600),
    );
  }
}



