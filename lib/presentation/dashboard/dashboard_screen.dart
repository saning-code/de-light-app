import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../../core/providers/auth_provider.dart';
import '../../core/providers/sale_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/dashboard_model.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SaleProvider>().loadDashboard();
    });
  }

  String _fmt(double amount, String symbol) {
    final f = NumberFormat('#,##0.00', 'en_US');
    return '$symbol ${f.format(amount)}';
  }

  String _pct(double pct) {
    final sign = pct >= 0 ? '+' : '';
    return '$sign${pct.toStringAsFixed(1)}%';
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final saleProvider = context.watch<SaleProvider>();
    final symbol = auth.currencySymbol;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(auth.businessName,
                style: const TextStyle(
                    fontSize: 17, fontWeight: FontWeight.bold)),
            Text(auth.shopName,
                style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary)),
          ],
        ),
        actions: [
          IconButton(
              icon: const Icon(Icons.notifications_outlined),
              onPressed: () {}),
          IconButton(
              icon: const Icon(Icons.refresh_outlined),
              onPressed: () =>
                  context.read<SaleProvider>().loadDashboard()),
        ],
      ),
      body: saleProvider.isLoadingDashboard && saleProvider.dashboard == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => context.read<SaleProvider>().loadDashboard(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: saleProvider.dashboard == null
                    ? _buildEmpty()
                    : _buildContent(
                        context, saleProvider.dashboard!, symbol),
              ),
            ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 80),
        child: Column(
          children: [
            Icon(Icons.dashboard_outlined,
                size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text('No dashboard data yet',
                style: TextStyle(color: Colors.grey.shade500)),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => context.read<SaleProvider>().loadDashboard(),
              child: const Text('Refresh'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(
      BuildContext context, DashboardSummary d, String symbol) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Alerts ────────────────────────────────────────────────────
        if (d.lowStockCount > 0 || d.outOfStockCount > 0)
          _buildAlertBanner(d),
        if (d.lowStockCount > 0 || d.outOfStockCount > 0)
          const SizedBox(height: 12),

        // ── KPI Cards ─────────────────────────────────────────────────
        _buildKpiGrid(d, symbol),
        const SizedBox(height: 24),

        // ── Hourly sales chart ────────────────────────────────────────
        if (d.hourlyChart.isNotEmpty) ...[
          _sectionTitle('Today\'s Sales by Hour'),
          const SizedBox(height: 12),
          _buildHourlyChart(d.hourlyChart, symbol),
          const SizedBox(height: 24),
        ],

        // ── Top products ──────────────────────────────────────────────
        if (d.topProductsToday.isNotEmpty) ...[
          _sectionTitle('Top Products Today'),
          const SizedBox(height: 12),
          _buildTopProducts(d.topProductsToday, symbol),
          const SizedBox(height: 24),
        ],

        // ── Recent transactions ───────────────────────────────────────
        if (d.recentSales.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _sectionTitle('Recent Transactions'),
              TextButton(
                  onPressed: () {}, child: const Text('View All')),
            ],
          ),
          const SizedBox(height: 8),
          _buildRecentSales(d.recentSales, symbol),
        ],
      ],
    );
  }

  // ── Alert banner ──────────────────────────────────────────────────────────

  Widget _buildAlertBanner(DashboardSummary d) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: AppColors.warning, size: 26),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${d.lowStockCount} low stock'
                  '${d.outOfStockCount > 0 ? ' · ${d.outOfStockCount} out of stock' : ''}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.warning,
                      fontSize: 13),
                ),
                const Text('Tap to view affected products',
                    style: TextStyle(fontSize: 11)),
              ],
            ),
          ),
          TextButton(
            onPressed: () {},
            style:
                TextButton.styleFrom(foregroundColor: AppColors.warning),
            child: const Text('View'),
          ),
        ],
      ),
    );
  }

  // ── KPI grid ──────────────────────────────────────────────────────────────

  Widget _buildKpiGrid(DashboardSummary d, String symbol) {
    final pct = d.salesVsYesterdayPercent;
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.3,
      children: [
        _kpiCard(
          title: "Today's Sales",
          value: _fmt(d.todaySalesTotal, symbol),
          sub: '${d.todaySalesCount} transactions',
          sub2: pct != 0 ? _pct(pct) + ' vs yesterday' : null,
          sub2Color: pct >= 0 ? AppColors.success : AppColors.danger,
          gradient: AppColors.salesGradient,
          icon: Icons.point_of_sale,
        ),
        _kpiCard(
          title: "Today's Profit",
          value: _fmt(d.todayProfit, symbol),
          sub: 'Net after cost',
          gradient: AppColors.profitGradient,
          icon: Icons.trending_up,
        ),
        _kpiCard(
          title: 'Expenses Today',
          value: _fmt(d.todayExpenses, symbol),
          sub: 'Recorded expenses',
          gradient: AppColors.expenseGradient,
          icon: Icons.receipt_long_outlined,
        ),
        _kpiCard(
          title: 'Customers Owing',
          value: _fmt(d.customersOwingTotal, symbol),
          sub: '${d.customersOwingCount} client(s)',
          gradient: AppColors.creditGradient,
          icon: Icons.people_outline,
        ),
      ],
    );
  }

  Widget _kpiCard({
    required String title,
    required String value,
    required String sub,
    String? sub2,
    Color? sub2Color,
    required LinearGradient gradient,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: gradient.colors.first.withOpacity(0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(title,
                    style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
              ),
              Icon(icon, color: Colors.white, size: 18),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text(sub,
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 10)),
              if (sub2 != null) ...[
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(sub2,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold)),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // ── Hourly bar chart ──────────────────────────────────────────────────────

  Widget _buildHourlyChart(List<HourlyPoint> points, String symbol) {
    if (points.isEmpty) return const SizedBox.shrink();

    final maxY = points.map((p) => p.total).reduce((a, b) => a > b ? a : b);

    return Container(
      height: 180,
      padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: BarChart(
        BarChartData(
          maxY: maxY * 1.2,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => FlLine(
              color: Colors.grey.withOpacity(0.15),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, _) {
                  final h = value.toInt();
                  if (h % 3 != 0) return const SizedBox.shrink();
                  final label =
                      h == 0 ? '12a' : h < 12 ? '${h}a' : h == 12 ? '12p' : '${h - 12}p';
                  return Text(label,
                      style: const TextStyle(fontSize: 9));
                },
                reservedSize: 22,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 48,
                getTitlesWidget: (v, _) => Text(
                  v == 0 ? '' : NumberFormat.compact().format(v),
                  style: const TextStyle(fontSize: 9),
                ),
              ),
            ),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          barGroups: points
              .map(
                (p) => BarChartGroupData(
                  x: p.hour,
                  barRods: [
                    BarChartRodData(
                      toY: p.total,
                      width: 8,
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4)),
                      gradient: AppColors.salesGradient,
                    ),
                  ],
                ),
              )
              .toList(),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, _, rod, __) => BarTooltipItem(
                _fmt(rod.toY, symbol),
                const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Top products ──────────────────────────────────────────────────────────

  Widget _buildTopProducts(List<TopProduct> products, String symbol) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: products.asMap().entries.map((entry) {
          final i = entry.key;
          final p = entry.value;
          final medals = ['🥇', '🥈', '🥉'];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.primary.withOpacity(0.1),
              child: Text(
                i < 3 ? medals[i] : '${i + 1}',
                style: const TextStyle(fontSize: 16),
              ),
            ),
            title: Text(p.name,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 13)),
            subtitle: Text(
                '${p.totalQty.toStringAsFixed(0)} units sold',
                style: const TextStyle(fontSize: 11)),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(_fmt(p.totalRevenue, symbol),
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13)),
                Text('profit: ${_fmt(p.totalProfit, symbol)}',
                    style: const TextStyle(
                        fontSize: 10, color: AppColors.success)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Recent sales ──────────────────────────────────────────────────────────

  Widget _buildRecentSales(List<RecentSaleItem> sales, String symbol) {
    final methodColors = {
      'cash': AppColors.success,
      'momo': AppColors.info,
      'card': AppColors.secondary,
      'bank': AppColors.accent,
      'credit': AppColors.danger,
      'split': AppColors.warning,
    };

    return Column(
      children: sales.map((s) {
        final color =
            methodColors[s.paymentMethod] ?? AppColors.lightTextSecondary;
        final timeStr = _formatTime(s.createdAt);
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.primary.withOpacity(0.1),
              child: const Icon(Icons.receipt_long,
                  color: AppColors.primary, size: 18),
            ),
            title: Text(s.saleNumber,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 13)),
            subtitle: Text(
                '$timeStr • ${s.itemsCount} item(s)'
                '${s.customerName != null ? ' • ${s.customerName}' : ''}',
                style: const TextStyle(fontSize: 11)),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(_fmt(s.total, symbol),
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14)),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    s.paymentMethod.toUpperCase(),
                    style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: color),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  String _formatTime(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return DateFormat('hh:mm a').format(dt);
    } catch (_) {
      return '';
    }
  }

  Widget _sectionTitle(String text) => Text(
        text,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      );
}
