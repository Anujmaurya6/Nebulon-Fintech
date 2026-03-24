import 'package:flutter/material.dart';
import 'profile_screen.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../features/analytics/provider/analytics_provider.dart';
import '../theme/app_theme.dart';
import '../core/utils/error_handler.dart';
import '../core/widgets/skeleton_loader.dart';


class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  String _timeFilter = 'Monthly';
  int? _touchedIndex;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(analyticsProvider.notifier).loadAnalytics());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(analyticsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: RefreshIndicator(
        color: AppTheme.indigo,
        onRefresh: () => ref.read(analyticsProvider.notifier).loadAnalytics(),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              _buildAppBar(context),
              if (state.status == AnalyticsStatus.loading)
                _buildSkeletonAnalytics()
              else if (state.status == AnalyticsStatus.error)

                ErrorHandler.buildErrorWidget(
                  state.errorMessage ?? 'Failed to load analytics',
                  () => ref.read(analyticsProvider.notifier).loadAnalytics(),
                )
              else if (state.data.totalTransactions == 0)
                _buildEmptyState()
              else
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      _buildTimeFilters(),
                      const SizedBox(height: 24),
                      _buildSummaryCards(state.data),
                      const SizedBox(height: 32),
                      _buildSectionHeader('Wealth Trend', 'Income vs Expenses'),
                      _buildLineChart(state.data),
                      const SizedBox(height: 40),
                      _buildSectionHeader('Spending Distribution', 'By Category'),
                      _buildPieChart(state.data),
                      const SizedBox(height: 48),
                      _buildCategoryDetails(state.data),
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

  Widget _buildAppBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 60, bottom: 20, left: 24, right: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () {
              HapticFeedback.mediumImpact();
              Navigator.of(context).push(_createProfileRoute(context));
            },
            child: const Hero(
              tag: 'profile_avatar',
              child: CircleAvatar(
                radius: 18,
                backgroundColor: AppTheme.indigo,
                child: Icon(Icons.person, color: Colors.white, size: 20),
              ),
            ),

          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Deep Analytics', style: Theme.of(context).textTheme.headlineLarge),
              Text('FINANCIAL INTELLIGENCE', style: AppTheme.lightTheme.textTheme.labelSmall),
            ],
          ),

          IconButton(
            icon: const Icon(Icons.download_outlined, color: AppTheme.indigo),
            onPressed: () {}, // Future PDF export
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.only(top: 100, left: 40, right: 40),
      child: Column(
        children: [
          Icon(Icons.bar_chart_rounded, size: 80, color: AppTheme.indigo.withValues(alpha: 0.2)),
          const SizedBox(height: 24),
          Text(
            'Your Financial Story Starts Here',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 12),
          Text(
            'Add your first income or expense to see beautiful, intelligent insights.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeFilters() {
    final filters = ['Weekly', 'Monthly', 'Yearly'];
    return Row(
      children: filters.map((f) {
        final isSelected = _timeFilter == f;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ChoiceChip(
            label: Text(f),
            selected: isSelected,
            onSelected: (val) {
              if (val) {
                HapticFeedback.selectionClick();
                setState(() => _timeFilter = f);
              }
            },
            selectedColor: AppTheme.indigo,
            labelStyle: TextStyle(
              color: isSelected ? Colors.white : AppTheme.indigo,
              fontWeight: FontWeight.bold,
            ),
            backgroundColor: Colors.white,
            side: BorderSide(color: isSelected ? Colors.transparent : AppTheme.indigo.withValues(alpha: 0.2)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSummaryCards(AnalyticsModel data) {
    return Column(
      children: [
        Row(
          children: [
            _buildMetricCard('Income', '₹${data.totalIncome.toStringAsFixed(0)}', AppTheme.emerald, Icons.arrow_upward),
            const SizedBox(width: 16),
            _buildMetricCard('Expenses', '₹${data.totalExpense.toStringAsFixed(0)}', AppTheme.rose, Icons.arrow_downward),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(color: AppTheme.indigo.withValues(alpha: 0.2), blurRadius: 20, offset: const Offset(0, 8))
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('SAVINGS RATE', style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(color: Colors.white70)),
                  const SizedBox(height: 4),
                  Text('${data.savingsRate.toStringAsFixed(1)}%', style: Theme.of(context).textTheme.displaySmall?.copyWith(color: Colors.white)),
                ],
              ),
              _buildCircularProgressIndicator(data.savingsRate / 100),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard(String label, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.borderLight.withValues(alpha: 0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(height: 12),
            Text(label, style: AppTheme.lightTheme.textTheme.labelSmall),
            const SizedBox(height: 4),
            Text(value, style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: AppTheme.indigo, fontWeight: FontWeight.w900, fontSize: 18)),
          ],
        ),
      ),
    );
  }

  Widget _buildCircularProgressIndicator(double value) {
    return SizedBox(
      height: 50, width: 50,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: value,
            backgroundColor: Colors.white12,
            valueColor: const AlwaysStoppedAnimation(AppTheme.mint),
            strokeWidth: 6,
          ),
          const Icon(Icons.savings, color: Colors.white70, size: 20),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.headlineMedium),
          Text(subtitle.toUpperCase(), style: AppTheme.lightTheme.textTheme.labelSmall),
        ],
      ),
    );
  }

  Widget _buildLineChart(AnalyticsModel data) {
    final months = data.expenseTrend.keys.toList()..sort();
    if (months.isEmpty) return const SizedBox();

    return Container(
      height: 250,
      padding: const EdgeInsets.only(right: 20, top: 10),
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (val, meta) {
                  if (val.toInt() >= months.length) return const SizedBox();
                  final month = months[val.toInt()].split('-').last;
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(month, style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
                  );
                },
              ),
            ),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            // Income Line
            LineChartBarData(
              spots: months.asMap().entries.map((e) {
                return FlSpot(e.key.toDouble(), data.incomeTrend[e.value] ?? 0);
              }).toList(),
              isCurved: true,
              color: AppTheme.emerald,
              barWidth: 4,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(show: true, color: AppTheme.emerald.withValues(alpha: 0.1)),
            ),
            // Expense Line
            LineChartBarData(
              spots: months.asMap().entries.map((e) {
                return FlSpot(e.key.toDouble(), data.expenseTrend[e.value] ?? 0);
              }).toList(),
              isCurved: true,
              color: AppTheme.rose,
              barWidth: 4,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(show: true, color: AppTheme.rose.withValues(alpha: 0.1)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPieChart(AnalyticsModel data) {
    return SizedBox(
      height: 200,
      child: PieChart(
        PieChartData(
          sectionsSpace: 0,
          centerSpaceRadius: 40,
          startDegreeOffset: -90,
          sections: _buildPieChartSections(data),
          pieTouchData: PieTouchData(
            touchCallback: (event, pieTouchResponse) {
              setState(() {
                if (!event.isInterestedForInteractions ||
                    pieTouchResponse == null ||
                    pieTouchResponse.touchedSection == null) {
                  _touchedIndex = -1;
                  return;
                }
                _touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
              });
            },
          ),
        ),
      ),
    );
  }

  List<PieChartSectionData> _buildPieChartSections(AnalyticsModel data) {
    final List<Color> colors = [
      AppTheme.indigo,
      AppTheme.emerald,
      AppTheme.rose,
      AppTheme.amber,
      Colors.indigoAccent,
      Colors.teal,
      Colors.pinkAccent,
    ];

    return data.categoryBreakdown.entries.toList().asMap().entries.map((e) {
      final isTouched = e.key == _touchedIndex;
      final radius = isTouched ? 70.0 : 60.0;
      final color = colors[e.key % colors.length];

      return PieChartSectionData(
        color: color,
        value: e.value.value,
        title: isTouched ? '₹${e.value.value.toInt()}' : '',
        radius: radius,
        titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
      );
    }).toList();
  }

  Widget _buildCategoryDetails(AnalyticsModel data) {
    return Column(
      children: data.categoryBreakdown.entries.map((e) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Container(width: 12, height: 12, decoration: const BoxDecoration(shape: BoxShape.circle, color: AppTheme.indigo)),
              const SizedBox(width: 12),
              Text(e.key, style: theme.textTheme.bodyMedium),
              const Spacer(),
              Text('₹${e.value.value.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSkeletonAnalytics() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Row(
            children: [
              SkeletonLoader(width: 80, height: 32, borderRadius: BorderRadius.circular(12)),
              const SizedBox(width: 8),
              SkeletonLoader(width: 80, height: 32, borderRadius: BorderRadius.circular(12)),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: SkeletonLoader.card(height: 100)),
              const SizedBox(width: 16),
              Expanded(child: SkeletonLoader.card(height: 100)),
            ],
          ),
          const SizedBox(height: 16),
          SkeletonLoader.card(height: 120),
          const SizedBox(height: 32),
          const SkeletonLoader(width: 150, height: 24),
          const SizedBox(height: 20),
          SkeletonLoader.card(height: 250),
        ],
      ),
    );
  }

  Route _createProfileRoute(BuildContext context) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => const ProfileScreen(),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
      transitionDuration: const Duration(milliseconds: 500),
    );
  }
}


