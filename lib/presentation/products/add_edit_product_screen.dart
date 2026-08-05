import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/providers/product_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/product_model.dart';

class AddEditProductScreen extends StatefulWidget {
  final ProductModel? product; // null = add mode

  const AddEditProductScreen({super.key, this.product});

  @override
  State<AddEditProductScreen> createState() => _AddEditProductScreenState();
}

class _AddEditProductScreenState extends State<AddEditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Controllers
  late final TextEditingController _nameCtrl;
  late final TextEditingController _barcodeCtrl;
  late final TextEditingController _skuCtrl;
  late final TextEditingController _unitCtrl;
  late final TextEditingController _sellingPriceCtrl;
  late final TextEditingController _costPriceCtrl;
  late final TextEditingController _wholesalePriceCtrl;
  late final TextEditingController _quantityCtrl;
  late final TextEditingController _reorderCtrl;
  late final TextEditingController _descCtrl;

  bool _trackInventory = true;
  bool _allowNegativeStock = false;

  bool get _isEditing => widget.product != null;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _nameCtrl = TextEditingController(text: p?.name ?? '');
    _barcodeCtrl = TextEditingController(text: p?.barcode ?? '');
    _skuCtrl = TextEditingController(text: p?.sku ?? '');
    _unitCtrl = TextEditingController(text: p?.unit ?? 'piece');
    _sellingPriceCtrl = TextEditingController(
        text: p != null ? p.sellingPrice.toStringAsFixed(2) : '');
    _costPriceCtrl = TextEditingController(
        text: p != null ? p.costPrice.toStringAsFixed(2) : '');
    _wholesalePriceCtrl = TextEditingController(
        text: p?.wholesalePrice != null
            ? p!.wholesalePrice!.toStringAsFixed(2)
            : '');
    _quantityCtrl = TextEditingController(
        text: p != null ? p.quantity.toStringAsFixed(0) : '0');
    _reorderCtrl = TextEditingController(
        text: p != null ? p.reorderLevel.toStringAsFixed(0) : '5');
    _descCtrl = TextEditingController(text: p?.description ?? '');
    _trackInventory = p?.trackInventory ?? true;
    _allowNegativeStock = p?.allowNegativeStock ?? false;
  }

  @override
  void dispose() {
    for (final c in [
      _nameCtrl, _barcodeCtrl, _skuCtrl, _unitCtrl,
      _sellingPriceCtrl, _costPriceCtrl, _wholesalePriceCtrl,
      _quantityCtrl, _reorderCtrl, _descCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final data = {
      'name': _nameCtrl.text.trim(),
      'barcode': _barcodeCtrl.text.trim().isEmpty
          ? null
          : _barcodeCtrl.text.trim(),
      'sku': _skuCtrl.text.trim().isEmpty ? null : _skuCtrl.text.trim(),
      'unit': _unitCtrl.text.trim(),
      'selling_price': double.tryParse(_sellingPriceCtrl.text) ?? 0,
      'cost_price': double.tryParse(_costPriceCtrl.text) ?? 0,
      'wholesale_price': _wholesalePriceCtrl.text.trim().isEmpty
          ? null
          : double.tryParse(_wholesalePriceCtrl.text),
      'quantity': double.tryParse(_quantityCtrl.text) ?? 0,
      'reorder_level': double.tryParse(_reorderCtrl.text) ?? 5,
      'track_inventory': _trackInventory,
      'allow_negative_stock': _allowNegativeStock,
      'description': _descCtrl.text.trim().isEmpty
          ? null
          : _descCtrl.text.trim(),
    };

    final provider = context.read<ProductProvider>();
    String? error;

    if (_isEditing) {
      error = await provider.updateProduct(widget.product!.id, data);
    } else {
      error = await provider.createProduct(data);
    }

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(error),
        backgroundColor: AppColors.danger,
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_isEditing
            ? 'Product updated successfully'
            : 'Product created successfully'),
        backgroundColor: AppColors.success,
      ));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Product' : 'Add New Product',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.only(right: 16),
                child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2)),
              ),
            )
          else
            TextButton(
              onPressed: _submit,
              child: Text(
                _isEditing ? 'Save' : 'Create',
                style: const TextStyle(
                    color: AppColors.primary, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _section('Basic Information'),
              const SizedBox(height: 12),

              // Name
              TextFormField(
                controller: _nameCtrl,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Product Name *',
                  prefixIcon: Icon(Icons.inventory_2_outlined),
                ),
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Product name is required'
                    : null,
              ),
              const SizedBox(height: 12),

              // Barcode & SKU row
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _barcodeCtrl,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Barcode',
                        prefixIcon: Icon(Icons.qr_code),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _skuCtrl,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'SKU',
                        prefixIcon: Icon(Icons.tag),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Unit
              TextFormField(
                controller: _unitCtrl,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Unit of Measure *',
                  prefixIcon: Icon(Icons.scale_outlined),
                  hintText: 'piece, kg, litre, box…',
                ),
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Unit is required'
                    : null,
              ),
              const SizedBox(height: 20),

              _section('Pricing'),
              const SizedBox(height: 12),

              // Selling & Cost price row
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _sellingPriceCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Selling Price *',
                        prefixIcon: Icon(Icons.sell_outlined),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Required';
                        }
                        if (double.tryParse(v) == null) return 'Invalid';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _costPriceCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Cost Price',
                        prefixIcon: Icon(Icons.shopping_bag_outlined),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _wholesalePriceCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Wholesale Price (optional)',
                  prefixIcon: Icon(Icons.discount_outlined),
                ),
              ),
              const SizedBox(height: 20),

              _section('Stock Management'),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _quantityCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Opening Quantity',
                        prefixIcon: Icon(Icons.numbers),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _reorderCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Reorder Level',
                        prefixIcon: Icon(Icons.warning_amber_outlined),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              SwitchListTile(
                value: _trackInventory,
                onChanged: (v) => setState(() => _trackInventory = v),
                title: const Text('Track Inventory'),
                subtitle: const Text(
                    'Deduct stock automatically on each sale'),
                activeColor: AppColors.primary,
                contentPadding: EdgeInsets.zero,
              ),
              SwitchListTile(
                value: _allowNegativeStock,
                onChanged: (v) => setState(() => _allowNegativeStock = v),
                title: const Text('Allow Negative Stock'),
                subtitle: const Text('Sell even when stock is 0'),
                activeColor: AppColors.warning,
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 20),

              _section('Additional Info'),
              const SizedBox(height: 12),

              TextFormField(
                controller: _descCtrl,
                maxLines: 3,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  prefixIcon: Icon(Icons.notes),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 32),

              // Save button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor:
                        _isEditing ? AppColors.secondary : AppColors.primary,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          _isEditing ? 'Save Changes' : 'Create Product',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _section(String title) => Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
          letterSpacing: 0.5,
        ),
      );
}
