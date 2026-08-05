import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';

import '../../core/providers/auth_provider.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/dashboard_model.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String _period = 'monthly';
  PeriodReport? _report;
  bool _isLoading = false;
  String? _error;

  final _periods = const {
    'daily': 'Today',
    'weekly': 'This Week',
    'monthly': 'This Month',
    'yearly': 'This Year',
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadReport());
  }

  Future<void> _loadReport() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final response = await ApiClient().getPeriodReport(period: _period);
      final body = ApiResponse.fromResponse(response);
      if (body.success) {
        setState(() => _report = PeriodReport.fromJson(body.data as Map<String, dynamic>));
      } else {
        setState(() => _error = body.message);
      }
    } on DioException catch (e) {
      setState(() => _error = dioErrorMessage(e));
    } catch (_) {
      setState(() => _error = 'Failed to load report.');
    }
    setState(() => _isLoading = false);
  }

  String _fmt(double v, String symbol) =>
      '$symbol ${NumberFormat('#,##0.00').format(v)}';

  @override
  Widget build(BuildContext context) {
    final symbol = context.watch<AuthProvider>().currencySymbol;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports & Analytics',
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: const Icon(Icons.refresh_outlined), onPressed: _loadReport),
        ],
      ),
      body: Column(
        children: [
          // Period pills
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: _periods.entries.map((e) {
                final sel = _period == e.key;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(e.value),
                    selected: sel,
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                        color: sel ? Colors.white : null,
                        fontWeight: FontWeight.bold),
                    onSelected: (_) { setState(() => _period = e.key); _loadReport(); },
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          const Icon(Icons.error_outline, size: 48, color: AppColors.danger),
                          const SizedBox(height: 12),
                          Text(_error!, style: const TextStyle(color: AppColors.danger)),
                          const SizedBox(height: 8),
                          TextButton(onPressed: _loadReport, child: const Text('Retry')),
                        ]))
                    : _report == null
                        ? const Center(child: Text('No data'))
                        : RefreshIndicator(
                            onRefresh: _loadReport,
                            child: SingleChildScrollView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.all(16),
                              child: _buildContent(_report!, symbol),
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(PeriodReport r, String symbol) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.35,
          children: [
            _kpiCard('Revenue', _fmt(r.totalRevenue, symbol),
                '${r.totalTransactions} sales', AppColors.salesGradient, Icons.point_of_sale),
            _kpiCard('Gross Profit', _fmt(r.totalProfit, symbol),
                'After cost of goods', AppColors.profitGradient, Icons.trending_up),
            _kpiCard('Expenses', _fmt(r.totalExpenses, symbol),
                'Recorded', AppColors.expenseGradient, Icons.receipt_long_outlined),
            _kpiCard('Net Profit', _fmt(r.netProfit, symbol),
                'Revenue − Expenses',
                r.netProfit >= 0 ? AppColors.profitGradient : AppColors.creditGradient,
                Icons.account_balance_wallet_outlined),
          ],
        ),
        if (r.revenueChart.isNotEmpty) ...[
          const SizedBox(height: 24),
          const Text('Revenue Trend',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _buildLineChart(r.revenueChart, symbol),
        ],
        if (r.topProducts.isNotEmpty) ...[
          const SizedBox(height: 24),
          const Text('Top Products',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _buildTopProducts(r.topProducts, symbol),
        ],
      ],
    );
  }

  Widget _kpiCard(String title, String value, String sub,
      LinearGradient gradient, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: gradient.colors.first.withOpacity(0.25), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Flexible(child: Text(title, style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600))),
            Icon(icon, color: Colors.white, size: 18),
          ]),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(sub, style: const TextStyle(color: Colors.white70, fontSize: 10)),
          ]),
        ],
      ),
    );
  }

  Widget _buildLineChart(List<ChartPoint> points, String symbol) {
    final maxY = points.map((p) => p.value).reduce((a, b) => a > b ? a : b);
    final spots = points.asMap().entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.value))
        .toList();
    return Container(
      height: 200,
      padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: LineChart(LineChartData(
        maxY: maxY * 1.2,
        minY: 0,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => FlLine(color: Colors.grey.withOpacity(0.15), strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 22,
            interval: (points.length / 5).ceilToDouble(),
            getTitlesWidget: (v, _) {
              final i = v.toInt();
              if (i < 0 || i >= points.length) return const SizedBox.shrink();
              return Text(points[i].label, style: const TextStyle(fontSize: 9));
            },
          )),
          leftTitles: AxisTitles(sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 52,
            getTitlesWidget: (v, _) => Text(
              v == 0 ? '' : NumberFormat.compact().format(v),
              style: const TextStyle(fontSize: 9),
            ),
          )),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        lineBarsData: [LineChartBarData(
          spots: spots,
          isCurved: true,
          gradient: AppColors.salesGradient,
          barWidth: 3,
          dotData: FlDotData(
            show: points.length <= 10,
            getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                radius: 4, color: AppColors.primary, strokeWidth: 2, strokeColor: Colors.white),
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [AppColors.primary.withOpacity(0.25), AppColors.primary.withOpacity(0.0)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        )],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (spots) => spots.map((s) => LineTooltipItem(
              _fmt(s.y, symbol),
              const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
            )).toList(),
          ),
        ),
      )),
    );
  }

  Widget _buildTopProducts(List<TopProduct> products, String symbol) {
    final medals = ['🥇', '🥈', '🥉'];
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: products.asMap().entries.map((entry) {
          final i = entry.key;
          final p = entry.value;
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.primary.withOpacity(0.1),
              child: Text(i < 3 ? medals[i] : '${i + 1}', style: const TextStyle(fontSize: 16)),
            ),
            title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            subtitle: Text('${p.totalQty.toStringAsFixed(0)} units', style: const TextStyle(fontSize: 11)),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(_fmt(p.totalRevenue, symbol), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                Text('profit: ${_fmt(p.totalProfit, symbol)}',
                    style: const TextStyle(fontSize: 10, color: AppColors.success)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
