import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../features/analytics/provider/analytics_provider.dart';
import '../theme/app_theme.dart';
import '../core/widgets/skeleton_loader.dart';
import '../core/widgets/premium_pressable.dart';
import 'profile_screen.dart';

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  String _timeFilter = 'Monthly';

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(analyticsProvider.notifier).loadAnalytics(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(analyticsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: RefreshIndicator(
        color: AppTheme.indigo,
        onRefresh: () => ref.read(analyticsProvider.notifier).loadAnalytics(),
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildSliverAppBar(context),
            if (state.status == AnalyticsStatus.loading)
              SliverToBoxAdapter(child: _buildSkeletonAnalytics())
            else if (state.status == AnalyticsStatus.error)
              SliverFillRemaining(
                child: Center(
                  child: Text(state.errorMessage ?? 'Error loading analytics'),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.all(24),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildTimeFilters(context),
                    const SizedBox(height: 32),
                    _buildSummaryCards(context, state.data),
                    const SizedBox(height: 48),
                    _buildChartSection(
                      context,
                      'Wealth Distribution',
                      state.data,
                    ),
                    const SizedBox(height: 100),
                  ]),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    final theme = Theme.of(context);
    return SliverAppBar(
      expandedHeight: 120,
      backgroundColor: Colors.transparent,
      elevation: 0,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: false,
        titlePadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        title: Text(
          'Analytics',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      actions: [
        IconButton(
          onPressed: () => Navigator.of(context).push(
            PageRouteBuilder(
              pageBuilder: (context, anim, sec) => const ProfileScreen(),
              transitionsBuilder: (context, anim, sec, child) =>
                  FadeTransition(opacity: anim, child: child),
            ),
          ),
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppTheme.indigo.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person_outline_rounded,
              size: 20,
              color: AppTheme.indigo,
            ),
          ),
        ),
        const SizedBox(width: 16),
      ],
    );
  }

  Widget _buildTimeFilters(BuildContext context) {
    final filters = ['Weekly', 'Monthly', 'Yearly'];
    return Row(
      children: filters.map((f) {
        final isSelected = _timeFilter == f;
        return Padding(
          padding: const EdgeInsets.only(right: 12),
          child: PremiumPressable(
            onTap: () => setState(() => _timeFilter = f),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.indigo : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? AppTheme.indigo
                      : AppTheme.indigo.withOpacity(0.1),
                ),
              ),
              child: Text(
                f,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppTheme.slate400,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSummaryCards(BuildContext context, AnalyticsModel data) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMiniCard(
                context,
                'Total Inflow',
                data.totalIncome.toStringAsFixed(0),
                Icons.arrow_downward_rounded,
                AppTheme.emerald,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildMiniCard(
                context,
                'Total Outflow',
                data.totalExpense.toStringAsFixed(0),
                Icons.arrow_upward_rounded,
                AppTheme.rose,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildMiniCard(
          context,
          'Savings Rate',
          '${(data.savingsRate).toStringAsFixed(1)}%',
          Icons.savings_rounded,
          AppTheme.indigo,
        ),
      ],
    );
  }

  Widget _buildMiniCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.primaryColor.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 16),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppTheme.slate400,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartSection(
    BuildContext context,
    String title,
    AnalyticsModel data,
  ) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 24),
        Container(
          height: 200,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.cardTheme.color,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: theme.primaryColor.withOpacity(0.05)),
          ),
          child: PieChart(
            PieChartData(
              sectionsSpace: 4,
              centerSpaceRadius: 50,
              sections: data.categoryBreakdown.entries
                  .map(
                    (e) => PieChartSectionData(
                      color: AppTheme.indigo.withOpacity(
                        0.2 +
                            (0.1 *
                                data.categoryBreakdown.keys.toList().indexOf(
                                  e.key,
                                )),
                      ),
                      value: e.value,
                      title: '',
                      radius: 20,
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSkeletonAnalytics() {
    return Column(
      children: List.generate(
        3,
        (i) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: SkeletonLoader.card(height: 120),
        ),
      ),
    );
  }
}
