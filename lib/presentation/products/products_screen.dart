import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../core/providers/auth_provider.dart';
import '../../core/providers/product_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/product_model.dart';
import 'add_edit_product_screen.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
    _tabController.dispose();
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final canManage = auth.permissions?.canManageProducts ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Products & Stock',
            style: TextStyle(fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Low Stock'),
            Tab(text: 'Out of Stock'),
          ],
          onTap: (index) {
            final provider = context.read<ProductProvider>();
            switch (index) {
              case 0:
                provider.setCategory(null);
                provider.loadProducts(refresh: true);
                break;
              case 1:
                context.read<ProductProvider>().loadProducts(refresh: true);
                // handled by filter in build
                break;
              case 2:
                context.read<ProductProvider>().loadProducts(refresh: true);
                break;
            }
          },
        ),
      ),
      body: Column(
        children: [
          // ── Search bar ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search by name, SKU or barcode…',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchCtrl.clear();
                          context.read<ProductProvider>().setSearch('');
                        },
                      )
                    : null,
              ),
              onChanged: (v) =>
                  context.read<ProductProvider>().setSearch(v),
            ),
          ),

          // ── Product list ──────────────────────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tabController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _ProductList(
                    scrollCtrl: _scrollCtrl, filter: _ProductFilter.all),
                _ProductList(
                    scrollCtrl: _scrollCtrl,
                    filter: _ProductFilter.lowStock),
                _ProductList(
                    scrollCtrl: _scrollCtrl,
                    filter: _ProductFilter.outOfStock),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: canManage
          ? FloatingActionButton.extended(
              onPressed: () => _openAddProduct(context),
              icon: const Icon(Icons.add),
              label: const Text('Add Product'),
              backgroundColor: AppColors.primary,
            )
          : null,
    );
  }

  void _openAddProduct(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddEditProductScreen()),
    ).then((_) =>
        context.read<ProductProvider>().loadProducts(refresh: true));
  }
}

enum _ProductFilter { all, lowStock, outOfStock }

class _ProductList extends StatelessWidget {
  final ScrollController scrollCtrl;
  final _ProductFilter filter;

  const _ProductList({
    required this.scrollCtrl,
    required this.filter,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProductProvider>();
    final auth = context.watch<AuthProvider>();
    final symbol = auth.currencySymbol;
    final canManage = auth.permissions?.canManageProducts ?? false;
    final canViewCost = auth.permissions?.canViewCostPrice ?? false;

    List<ProductModel> items;
    switch (filter) {
      case _ProductFilter.lowStock:
        items = provider.products.where((p) => p.isLowStock).toList();
        break;
      case _ProductFilter.outOfStock:
        items = provider.products.where((p) => p.isOutOfStock).toList();
        break;
      case _ProductFilter.all:
        items = provider.products;
        break;
    }

    if (provider.isLoading && items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (items.isEmpty && !provider.isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined,
                size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              filter == _ProductFilter.all
                  ? 'No products found'
                  : filter == _ProductFilter.lowStock
                      ? 'No low stock products'
                      : 'All products are in stock',
              style: TextStyle(color: Colors.grey.shade500),
            ),
            if (filter == _ProductFilter.all) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: () =>
                    context.read<ProductProvider>().loadProducts(refresh: true),
                child: const Text('Refresh'),
              ),
            ],
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () =>
          context.read<ProductProvider>().loadProducts(refresh: true),
      child: ListView.builder(
        controller: filter == _ProductFilter.all ? scrollCtrl : null,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
        itemCount: items.length + (provider.isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == items.length) {
            return const Center(
                child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ));
          }
          final product = items[index];
          return _ProductCard(
            product: product,
            symbol: symbol,
            canManage: canManage,
            canViewCost: canViewCost,
          );
        },
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final ProductModel product;
  final String symbol;
  final bool canManage;
  final bool canViewCost;

  const _ProductCard({
    required this.product,
    required this.symbol,
    required this.canManage,
    required this.canViewCost,
  });

  String _fmt(double v) => '$symbol ${NumberFormat('#,##0.00').format(v)}';

  @override
  Widget build(BuildContext context) {
    Color stockColor;
    String stockLabel;
    if (product.isOutOfStock) {
      stockColor = AppColors.danger;
      stockLabel = 'Out of Stock';
    } else if (product.isLowStock) {
      stockColor = AppColors.warning;
      stockLabel = 'Low Stock';
    } else {
      stockColor = AppColors.success;
      stockLabel = 'In Stock';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: canManage
            ? () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        AddEditProductScreen(product: product),
                  ),
                ).then((_) => context
                    .read<ProductProvider>()
                    .loadProducts(refresh: true))
            : null,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Product image / placeholder ───────────────────────
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: product.imageUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(product.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                                Icons.inventory_2_outlined,
                                color: AppColors.primary)),
                      )
                    : const Icon(Icons.inventory_2_outlined,
                        color: AppColors.primary),
              ),
              const SizedBox(width: 12),

              // ── Details ────────────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            product.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: stockColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            stockLabel,
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: stockColor),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (product.category != null)
                      Text(
                        product.category!.name,
                        style: TextStyle(
                            fontSize: 11,
                            color: AppColors.lightTextSecondary),
                      ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _infoChip(
                            Icons.sell_outlined,
                            _fmt(product.sellingPrice),
                            AppColors.primary),
                        const SizedBox(width: 8),
                        if (canViewCost)
                          _infoChip(
                              Icons.shopping_bag_outlined,
                              _fmt(product.costPrice),
                              AppColors.lightTextSecondary),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Qty: ${product.quantity.toStringAsFixed(product.quantity % 1 == 0 ? 0 : 2)} ${product.unit}',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: stockColor),
                        ),
                        if (product.sku != null)
                          Text(
                            product.sku!,
                            style: TextStyle(
                                fontSize: 10,
                                color: AppColors.lightTextSecondary),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // ── Actions ────────────────────────────────────────────
              if (canManage)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 20),
                  onSelected: (action) =>
                      _handleAction(context, action, product),
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                        value: 'edit',
                        child: ListTile(
                          leading: Icon(Icons.edit_outlined),
                          title: Text('Edit'),
                          dense: true,
                        )),
                    const PopupMenuItem(
                        value: 'adjust',
                        child: ListTile(
                          leading: Icon(Icons.tune_outlined),
                          title: Text('Adjust Stock'),
                          dense: true,
                        )),
                    const PopupMenuItem(
                        value: 'delete',
                        child: ListTile(
                          leading: Icon(Icons.delete_outline,
                              color: AppColors.danger),
                          title: Text('Delete',
                              style:
                                  TextStyle(color: AppColors.danger)),
                          dense: true,
                        )),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String label, Color color) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 3),
          Text(label,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color)),
        ],
      );

  void _handleAction(
      BuildContext context, String action, ProductModel product) {
    switch (action) {
      case 'edit':
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => AddEditProductScreen(product: product)),
        ).then((_) => context
            .read<ProductProvider>()
            .loadProducts(refresh: true));
        break;
      case 'adjust':
        _showAdjustStockDialog(context, product);
        break;
      case 'delete':
        _confirmDelete(context, product);
        break;
    }
  }

  void _showAdjustStockDialog(BuildContext context, ProductModel product) {
    final ctrl = TextEditingController();
    String type = 'in';
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
          title: const Text('Adjust Stock'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Current: ${product.quantity} ${product.unit}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                      value: 'in',
                      label: Text('Stock In'),
                      icon: Icon(Icons.add_circle_outline)),
                  ButtonSegment(
                      value: 'out',
                      label: Text('Stock Out'),
                      icon: Icon(Icons.remove_circle_outline)),
                  ButtonSegment(
                      value: 'set',
                      label: Text('Set Qty'),
                      icon: Icon(Icons.edit_outlined)),
                ],
                selected: {type},
                onSelectionChanged: (s) =>
                    setModalState(() => type = s.first),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: ctrl,
                keyboardType: const TextInputType.numberWithOptions(
                    decimal: true),
                decoration: InputDecoration(
                  labelText: type == 'set'
                      ? 'New Quantity'
                      : 'Quantity to ${type == 'in' ? 'add' : 'remove'}',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final qty = double.tryParse(ctrl.text);
                if (qty == null || qty < 0) return;
                Navigator.pop(ctx);
                await context
                    .read<ProductProvider>()
                    .adjustStock(product.id, type, qty);
                if (context.mounted) {
                  context
                      .read<ProductProvider>()
                      .loadProducts(refresh: true);
                }
              },
              child: const Text('Confirm'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, ProductModel product) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Product?'),
        content: Text(
            'Delete "${product.name}"? This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () async {
              Navigator.pop(ctx);
              final error = await context
                  .read<ProductProvider>()
                  .deleteProduct(product.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(
                      error ?? '${product.name} deleted successfully'),
                  backgroundColor:
                      error != null ? AppColors.danger : AppColors.success,
                ));
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

