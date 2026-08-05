import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../core/providers/auth_provider.dart';
import '../../core/providers/sale_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/sale_model.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  String? _filterMethod;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SaleProvider>().loadSales(refresh: true);
    });
    _scrollCtrl.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 200) {
      context.read<SaleProvider>().loadMoreSales();
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final saleProvider = context.watch<SaleProvider>();
    final auth = context.watch<AuthProvider>();
    final symbol = auth.currencySymbol;

    final sales = _filterMethod == null
        ? saleProvider.sales
        : saleProvider.sales
            .where((s) => s.paymentMethod == _filterMethod)
            .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales History',
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterSheet(context),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            onPressed: () =>
                context.read<SaleProvider>().loadSales(refresh: true),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Today summary strip ───────────────────────────────────
          _TodaySummaryStrip(symbol: symbol),

          // ── Search bar ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search invoice number…',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() {});
                        },
                      )
                    : null,
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),

          // ── Filter chip ───────────────────────────────────────────
          if (_filterMethod != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: Row(
                children: [
                  Chip(
                    label: Text(
                        'Method: ${_filterMethod!.toUpperCase()}'),
                    deleteIcon: const Icon(Icons.close, size: 16),
                    onDeleted: () =>
                        setState(() => _filterMethod = null),
                    backgroundColor:
                        AppColors.primary.withOpacity(0.1),
                  ),
                ],
              ),
            ),

          // ── Sales list ────────────────────────────────────────────
          Expanded(
            child: saleProvider.isLoadingSales && sales.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : sales.isEmpty
                    ? _buildEmpty(context)
                    : RefreshIndicator(
                        onRefresh: () => context
                            .read<SaleProvider>()
                            .loadSales(refresh: true),
                        child: ListView.builder(
                          controller: _scrollCtrl,
                          padding: const EdgeInsets.fromLTRB(
                              16, 8, 16, 80),
                          itemCount: sales.length +
                              (saleProvider.isLoadingSales ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == sales.length) {
                              return const Center(
                                  child: Padding(
                                padding: EdgeInsets.all(16),
                                child: CircularProgressIndicator(),
                              ));
                            }
                            final sale = sales[index];
                            // Apply search filter
                            if (_searchCtrl.text.isNotEmpty &&
                                !sale.saleNumber.toLowerCase().contains(
                                    _searchCtrl.text.toLowerCase())) {
                              return const SizedBox.shrink();
                            }
                            return _SaleCard(sale: sale, symbol: symbol);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined,
              size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text('No sales found',
              style: TextStyle(color: Colors.grey.shade500)),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () =>
                context.read<SaleProvider>().loadSales(refresh: true),
            child: const Text('Refresh'),
          ),
        ],
      ),
    );
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) {
        final methods = [
          null, 'cash', 'momo', 'card', 'bank', 'credit', 'split'
        ];
        final labels = {
          null: 'All Methods',
          'cash': 'Cash',
          'momo': 'MTN MoMo / Telecel',
          'card': 'Card',
          'bank': 'Bank Transfer',
          'credit': 'Credit',
          'split': 'Split',
        };
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Filter by Payment Method',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ...methods.map((m) => ListTile(
                    leading: Icon(
                      m == null
                          ? Icons.all_inclusive
                          : Icons.payment_outlined,
                      color: _filterMethod == m
                          ? AppColors.primary
                          : null,
                    ),
                    title: Text(labels[m] ?? m!),
                    trailing: _filterMethod == m
                        ? const Icon(Icons.check,
                            color: AppColors.primary)
                        : null,
                    onTap: () {
                      setState(() => _filterMethod = m);
                      Navigator.pop(context);
                    },
                  )),
            ],
          ),
        );
      },
    );
  }
}

// ─── Today Summary Strip ──────────────────────────────────────────────────

class _TodaySummaryStrip extends StatelessWidget {
  final String symbol;
  const _TodaySummaryStrip({required this.symbol});

  String _fmt(double v) => '$symbol ${NumberFormat('#,##0.00').format(v)}';

  @override
  Widget build(BuildContext context) {
    final sales = context.watch<SaleProvider>().sales;
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final todaySales = sales.where((s) {
      try {
        return s.createdAt.startsWith(today) && s.isCompleted;
      } catch (_) {
        return false;
      }
    }).toList();

    final total = todaySales.fold(0.0, (s, e) => s + e.total);
    final count = todaySales.length;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: AppColors.salesGradient,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Today's Revenue",
                  style: TextStyle(color: Colors.white70, fontSize: 12)),
              Text(_fmt(total),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text('Transactions',
                  style: TextStyle(color: Colors.white70, fontSize: 12)),
              Text('$count',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Sale Card ────────────────────────────────────────────────────────────

class _SaleCard extends StatelessWidget {
  final SaleModel sale;
  final String symbol;

  const _SaleCard({required this.sale, required this.symbol});

  String _fmt(double v) => '$symbol ${NumberFormat('#,##0.00').format(v)}';

  String _timeAgo(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return DateFormat('MMM d, hh:mm a').format(dt);
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final methodColors = {
      'cash': AppColors.success,
      'momo': AppColors.info,
      'card': AppColors.secondary,
      'bank': AppColors.accent,
      'credit': AppColors.danger,
      'split': AppColors.warning,
    };
    final color =
        methodColors[sale.paymentMethod] ?? AppColors.lightTextSecondary;
    final auth = context.read<AuthProvider>();
    final canDelete = auth.permissions?.canDeleteSale ?? false;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showSaleDetail(context),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(sale.saleNumber,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                  if (sale.isVoided)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.danger.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('VOIDED',
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppColors.danger)),
                    ),
                  Container(
                    margin: const EdgeInsets.only(left: 6),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      sale.paymentMethod.toUpperCase(),
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: color),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '${sale.items.length} item(s)'
                '${sale.customer != null ? ' · ${sale.customer!.name}' : ''}',
                style: TextStyle(
                    fontSize: 12,
                    color: AppColors.lightTextSecondary),
              ),
              const SizedBox(height: 2),
              Text(_timeAgo(sale.createdAt),
                  style: TextStyle(
                      fontSize: 11,
                      color: AppColors.lightTextSecondary)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_fmt(sale.total),
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16)),
                      if (sale.isCreditSale)
                        Text('Credit: ${_fmt(sale.creditAmount)}',
                            style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.danger)),
                    ],
                  ),
                  if (canDelete && !sale.isVoided)
                    TextButton.icon(
                      onPressed: () => _confirmVoid(context),
                      icon: const Icon(Icons.cancel_outlined,
                          size: 16, color: AppColors.danger),
                      label: const Text('Void',
                          style: TextStyle(color: AppColors.danger)),
                      style: TextButton.styleFrom(
                          padding: EdgeInsets.zero),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSaleDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _SaleDetailSheet(sale: sale, symbol: symbol),
    );
  }

  void _confirmVoid(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Void Sale?'),
        content: Text(
            'Void ${sale.saleNumber}? Stock will be restored.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger),
            onPressed: () async {
              Navigator.pop(ctx);
              final error = await context
                  .read<SaleProvider>()
                  .voidSale(sale.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(error ?? 'Sale voided successfully'),
                  backgroundColor: error != null
                      ? AppColors.danger
                      : AppColors.success,
                ));
              }
            },
            child: const Text('Void Sale'),
          ),
        ],
      ),
    );
  }
}

// ─── Sale Detail Sheet ────────────────────────────────────────────────────

class _SaleDetailSheet extends StatelessWidget {
  final SaleModel sale;
  final String symbol;

  const _SaleDetailSheet({required this.sale, required this.symbol});

  String _fmt(double v) => '$symbol ${NumberFormat('#,##0.00').format(v)}';

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.65,
      maxChildSize: 0.92,
      builder: (_, ctrl) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                width: 40, height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            Text(sale.saleNumber,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            Text(
              DateFormat('MMMM d, yyyy · hh:mm a')
                  .format(DateTime.parse(sale.createdAt).toLocal()),
              style: TextStyle(
                  color: AppColors.lightTextSecondary, fontSize: 12),
            ),
            const Divider(height: 20),
            Expanded(
              child: ListView(
                controller: ctrl,
                children: [
                  ...sale.items.map((item) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(item.productName,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13)),
                        subtitle: Text(
                            '${_fmt(item.unitPrice)} × ${item.quantity.toStringAsFixed(0)} ${item.productUnit}'),
                        trailing: Text(_fmt(item.subtotal),
                            style: const TextStyle(
                                fontWeight: FontWeight.bold)),
                      )),
                  const Divider(),
                  _detailRow('Subtotal', _fmt(sale.subtotal)),
                  if (sale.discountAmount > 0)
                    _detailRow(
                        'Discount (${sale.discountPercent.toStringAsFixed(0)}%)',
                        '− ${_fmt(sale.discountAmount)}',
                        color: AppColors.danger),
                  if (sale.taxAmount > 0)
                    _detailRow('Tax', _fmt(sale.taxAmount)),
                  const Divider(),
                  _detailRow('TOTAL', _fmt(sale.total), bold: true),
                  _detailRow('Amount Paid', _fmt(sale.amountPaid)),
                  if (sale.changeGiven > 0)
                    _detailRow('Change', _fmt(sale.changeGiven),
                        color: AppColors.success),
                  if (sale.isCreditSale)
                    _detailRow('Credit Balance', _fmt(sale.creditAmount),
                        color: AppColors.danger),
                  const SizedBox(height: 12),
                  _detailRow(
                      'Payment', sale.paymentMethod.toUpperCase()),
                  if (sale.customer != null)
                    _detailRow('Customer', sale.customer!.name),
                  if (sale.note != null && sale.note!.isNotEmpty)
                    _detailRow('Note', sale.note!),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value,
      {bool bold = false, Color? color}) {
    final style = TextStyle(
        fontWeight: bold ? FontWeight.bold : FontWeight.normal,
        fontSize: bold ? 15 : 13,
        color: color);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(value, style: style),
        ],
      ),
    );
  }
}
