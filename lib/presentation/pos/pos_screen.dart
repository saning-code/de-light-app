import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../core/providers/auth_provider.dart';
import '../../core/providers/product_provider.dart';
import '../../core/providers/sale_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/product_model.dart';
import '../../data/models/sale_model.dart';

class PosScreen extends StatefulWidget {
  const PosScreen({super.key});

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().loadProducts(refresh: true);
    });
    _scrollCtrl.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 200) {
      context.read<ProductProvider>().loadMore();
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  String _fmt(double v, String symbol) =>
      '$symbol ${NumberFormat('#,##0.00').format(v)}';

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final productProvider = context.watch<ProductProvider>();
    final saleProvider = context.watch<SaleProvider>();
    final symbol = auth.currencySymbol;
    final cart = saleProvider.cart;

    return Scaffold(
      appBar: AppBar(
        title: const Text('POS Register',
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          // Cart badge
          Stack(
            alignment: Alignment.topRight,
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart_outlined),
                onPressed: cart.isEmpty ? null : () => _showCart(context),
              ),
              if (cart.isNotEmpty)
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.danger,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${cart.length}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),
          if (cart.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined,
                  color: AppColors.danger),
              onPressed: () {
                saleProvider.clearCart();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Cart cleared')),
                );
              },
            ),
        ],
      ),
      body: Column(
        children: [
          // ── Search bar ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search product or scan barcode…',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_searchCtrl.text.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchCtrl.clear();
                          context.read<ProductProvider>().setSearch('');
                        },
                      ),
                    IconButton(
                      icon: const Icon(Icons.qr_code_scanner,
                          color: AppColors.primary),
                      onPressed: () => _scanBarcode(context),
                    ),
                  ],
                ),
              ),
              onChanged: (v) =>
                  context.read<ProductProvider>().setSearch(v),
            ),
          ),

          // ── Product grid ───────────────────────────────────────────
          Expanded(
            child: productProvider.isLoading && productProvider.products.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : productProvider.products.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inventory_2_outlined,
                                size: 56, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            const Text('No products found'),
                            TextButton(
                              onPressed: () => context
                                  .read<ProductProvider>()
                                  .loadProducts(refresh: true),
                              child: const Text('Refresh'),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () => context
                            .read<ProductProvider>()
                            .loadProducts(refresh: true),
                        child: GridView.builder(
                          controller: _scrollCtrl,
                          padding: const EdgeInsets.fromLTRB(12, 4, 12, 100),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                            childAspectRatio: 1.2,
                          ),
                          itemCount: productProvider.products.length +
                              (productProvider.isLoadingMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == productProvider.products.length) {
                              return const Center(
                                  child: CircularProgressIndicator());
                            }
                            final product =
                                productProvider.products[index];
                            return _ProductTile(
                              product: product,
                              symbol: symbol,
                              onTap: () => _addToCart(context, product),
                            );
                          },
                        ),
                      ),
          ),

          // ── Checkout bar ───────────────────────────────────────────
          if (cart.isNotEmpty)
            _CheckoutBar(
              symbol: symbol,
              onCheckout: () => _showCheckout(context),
            ),
        ],
      ),
    );
  }

  void _addToCart(BuildContext context, ProductModel product) {
    if (product.isOutOfStock && !product.allowNegativeStock) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${product.name} is out of stock'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }
    context.read<SaleProvider>().addToCart(product);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product.name} added to cart'),
        duration: const Duration(milliseconds: 800),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _scanBarcode(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Barcode scanner — use mobile device')),
    );
  }

  void _showCart(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<SaleProvider>(),
        child: _CartSheet(
          symbol: context.read<AuthProvider>().currencySymbol,
          onCheckout: () {
            Navigator.pop(context);
            _showCheckout(context);
          },
        ),
      ),
    );
  }

  void _showCheckout(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<SaleProvider>(),
        child: _CheckoutSheet(
          symbol: context.read<AuthProvider>().currencySymbol,
        ),
      ),
    );
  }
}

// ─── Product Tile ──────────────────────────────────────────────────────────

class _ProductTile extends StatelessWidget {
  final ProductModel product;
  final String symbol;
  final VoidCallback onTap;

  const _ProductTile({
    required this.product,
    required this.symbol,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isUnavailable =
        product.isOutOfStock && !product.allowNegativeStock;

    return Card(
      child: InkWell(
        onTap: isUnavailable ? null : onTap,
        borderRadius: BorderRadius.circular(16),
        child: Opacity(
          opacity: isUnavailable ? 0.45 : 1.0,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Category chip
                if (product.category != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      product.category!.name,
                      style: const TextStyle(
                          fontSize: 9, color: AppColors.accent),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                Text(
                  product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 13),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$symbol ${NumberFormat('#,##0.00').format(product.sellingPrice)}',
                          style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 13),
                        ),
                        Text(
                          isUnavailable
                              ? 'Out of stock'
                              : 'Qty: ${product.quantity.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 10,
                            color: isUnavailable
                                ? AppColors.danger
                                : product.isLowStock
                                    ? AppColors.warning
                                    : AppColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: isUnavailable
                            ? Colors.grey.shade300
                            : AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isUnavailable ? Icons.block : Icons.add,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Checkout Bar (bottom sticky) ─────────────────────────────────────────

class _CheckoutBar extends StatelessWidget {
  final String symbol;
  final VoidCallback onCheckout;

  const _CheckoutBar({required this.symbol, required this.onCheckout});

  @override
  Widget build(BuildContext context) {
    final sale = context.watch<SaleProvider>();
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, -2)),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _showCartSheet(context),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.shopping_cart,
                      color: AppColors.primary, size: 20),
                  const SizedBox(width: 6),
                  Text(
                    '${sale.cart.length} item(s)',
                    style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: onCheckout,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(
                'Charge $symbol ${NumberFormat('#,##0.00').format(sale.cartTotal)}',
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCartSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<SaleProvider>(),
        child: _CartSheet(symbol: symbol, onCheckout: onCheckout),
      ),
    );
  }
}

// ─── Cart Sheet ────────────────────────────────────────────────────────────

class _CartSheet extends StatelessWidget {
  final String symbol;
  final VoidCallback onCheckout;

  const _CartSheet({required this.symbol, required this.onCheckout});

  String _fmt(double v) => '$symbol ${NumberFormat('#,##0.00').format(v)}';

  @override
  Widget build(BuildContext context) {
    final sale = context.watch<SaleProvider>();
    final cart = sale.cart;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (_, scrollCtrl) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          children: [
            // Handle
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Cart (${cart.length} items)',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                TextButton.icon(
                  onPressed: () {
                    sale.clearCart();
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.delete_outline,
                      color: AppColors.danger, size: 18),
                  label: const Text('Clear',
                      style: TextStyle(color: AppColors.danger)),
                ),
              ],
            ),
            const Divider(),
            Expanded(
              child: ListView.builder(
                controller: scrollCtrl,
                itemCount: cart.length,
                itemBuilder: (_, i) {
                  final item = cart[i];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(item.product.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    subtitle: Text(
                        '${_fmt(item.unitPrice)} × ${item.quantity.toStringAsFixed(0)} ${item.product.unit}',
                        style: const TextStyle(fontSize: 11)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_fmt(item.subtotal),
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13)),
                        const SizedBox(width: 4),
                        // Qty stepper
                        _QtyStepper(
                          qty: item.quantity,
                          onDecrease: () => sale.updateCartQty(
                              item.product.id, item.quantity - 1),
                          onIncrease: () => sale.updateCartQty(
                              item.product.id, item.quantity + 1),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const Divider(),
            // Discount row
            _DiscountRow(symbol: symbol),
            const SizedBox(height: 8),
            // Totals
            _TotalRow(label: 'Subtotal', value: _fmt(sale.cartSubtotal)),
            if (sale.discountPercent > 0)
              _TotalRow(
                  label:
                      'Discount (${sale.discountPercent.toStringAsFixed(0)}%)',
                  value: '− ${_fmt(sale.cartDiscountAmount)}',
                  color: AppColors.danger),
            const SizedBox(height: 4),
            _TotalRow(
                label: 'TOTAL',
                value: _fmt(sale.cartTotal),
                bold: true,
                color: AppColors.success),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onCheckout,
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success),
                child: Text('Proceed to Checkout — ${_fmt(sale.cartTotal)}',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Qty Stepper ──────────────────────────────────────────────────────────

class _QtyStepper extends StatelessWidget {
  final double qty;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  const _QtyStepper(
      {required this.qty,
      required this.onDecrease,
      required this.onIncrease});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: onDecrease,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.danger.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.remove,
                size: 14, color: AppColors.danger),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(qty.toStringAsFixed(0),
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 13)),
        ),
        InkWell(
          onTap: onIncrease,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.add,
                size: 14, color: AppColors.success),
          ),
        ),
      ],
    );
  }
}

// ─── Discount Row ─────────────────────────────────────────────────────────

class _DiscountRow extends StatelessWidget {
  final String symbol;
  const _DiscountRow({required this.symbol});

  @override
  Widget build(BuildContext context) {
    final sale = context.watch<SaleProvider>();
    return Row(
      children: [
        const Icon(Icons.discount_outlined,
            size: 16, color: AppColors.warning),
        const SizedBox(width: 8),
        const Text('Discount:',
            style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(width: 8),
        Expanded(
          child: Slider(
            value: sale.discountPercent,
            min: 0,
            max: 30,
            divisions: 30,
            label: '${sale.discountPercent.toStringAsFixed(0)}%',
            activeColor: AppColors.warning,
            onChanged: (v) => sale.setDiscount(v),
          ),
        ),
        Text('${sale.discountPercent.toStringAsFixed(0)}%',
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: AppColors.warning)),
      ],
    );
  }
}

// ─── Total Row ────────────────────────────────────────────────────────────

class _TotalRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  final Color? color;

  const _TotalRow(
      {required this.label,
      required this.value,
      this.bold = false,
      this.color});

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontSize: bold ? 15 : 13,
      fontWeight: bold ? FontWeight.bold : FontWeight.normal,
      color: color,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
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

// ─── Checkout Sheet ───────────────────────────────────────────────────────

class _CheckoutSheet extends StatefulWidget {
  final String symbol;
  const _CheckoutSheet({required this.symbol});

  @override
  State<_CheckoutSheet> createState() => _CheckoutSheetState();
}

class _CheckoutSheetState extends State<_CheckoutSheet> {
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  String _selectedMethod = 'cash';

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  String _fmt(double v) =>
      '${widget.symbol} ${NumberFormat('#,##0.00').format(v)}';

  double get _amountPaid =>
      double.tryParse(_amountCtrl.text) ?? 0.0;

  double get _change {
    final sale = context.read<SaleProvider>();
    return (_amountPaid - sale.cartTotal).clamp(0, double.infinity);
  }

  Future<void> _processPayment() async {
    final sale = context.read<SaleProvider>();

    if (_selectedMethod != 'credit' &&
        _amountPaid < sale.cartTotal) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Amount paid is less than total'),
        backgroundColor: AppColors.danger,
      ));
      return;
    }

    final paid = _selectedMethod == 'credit' ? 0.0 : _amountPaid;
    final result = await sale.processSale(
      amountPaid: paid,
      note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
    );

    if (!mounted) return;

    if (result != null) {
      Navigator.pop(context);
      _showReceiptDialog(context, result);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(sale.saleError ?? 'Sale failed'),
        backgroundColor: AppColors.danger,
      ));
    }
  }

  void _showReceiptDialog(BuildContext context, SaleModel sale) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: AppColors.success),
            SizedBox(width: 8),
            Text('Sale Complete!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Invoice: ${sale.saleNumber}',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('Total: ${_fmt(sale.total)}'),
            Text('Paid: ${_fmt(sale.amountPaid)}'),
            if (sale.changeGiven > 0)
              Text('Change: ${_fmt(sale.changeGiven)}',
                  style:
                      const TextStyle(color: AppColors.success)),
            if (sale.isCreditSale)
              Text('Credit: ${_fmt(sale.creditAmount)}',
                  style: const TextStyle(color: AppColors.danger)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.print_outlined),
            label: const Text('Print Receipt'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sale = context.watch<SaleProvider>();
    final total = sale.cartTotal;

    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const Text('Checkout & Payment',
                style:
                    TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('Total: ${_fmt(total)}',
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.success)),
            const SizedBox(height: 16),
            // Payment method
            const Text('Payment Method',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: AppConstants.paymentMethods.map((m) {
                final isSelected = _selectedMethod == m;
                return ChoiceChip(
                  label: Text(AppConstants.paymentLabels[m] ?? m),
                  selected: isSelected,
                  selectedColor: AppColors.primary,
                  labelStyle: TextStyle(
                      color: isSelected ? Colors.white : null,
                      fontWeight: FontWeight.w600),
                  onSelected: (_) =>
                      setState(() => _selectedMethod = m),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            // Amount paid
            if (_selectedMethod != 'credit') ...[
              TextField(
                controller: _amountCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Amount Received',
                  prefixIcon: const Icon(Icons.payments_outlined),
                  hintText: _fmt(total),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 8),
              if (_amountPaid >= total)
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Change:',
                          style:
                              TextStyle(fontWeight: FontWeight.bold)),
                      Text(_fmt(_change),
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.success,
                              fontSize: 16)),
                    ],
                  ),
                ),
              const SizedBox(height: 12),
            ],
            // Note
            TextField(
              controller: _noteCtrl,
              decoration: const InputDecoration(
                labelText: 'Note (optional)',
                prefixIcon: Icon(Icons.notes_outlined),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: sale.isProcessingSale ? null : _processPayment,
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    padding:
                        const EdgeInsets.symmetric(vertical: 16)),
                child: sale.isProcessingSale
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Text(
                        _selectedMethod == 'credit'
                            ? 'Confirm Credit Sale'
                            : 'Complete Sale — ${_fmt(total)}',
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
