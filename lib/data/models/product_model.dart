class CategoryModel {
  final int id;
  final String name;
  final String? color;
  final String? icon;

  const CategoryModel({
    required this.id,
    required this.name,
    this.color,
    this.icon,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) => CategoryModel(
        id: json['id'] as int,
        name: json['name'] as String,
        color: json['color'] as String?,
        icon: json['icon'] as String?,
      );
}

class ProductModel {
  final int id;
  final String? uuid;
  final int? categoryId;
  final CategoryModel? category;
  final String name;
  final String? barcode;
  final String? sku;
  final String unit;
  final double sellingPrice;
  final double costPrice;
  final double? wholesalePrice;
  final double quantity;
  final double reorderLevel;
  final bool trackInventory;
  final bool allowNegativeStock;
  final bool isActive;
  final String? imageUrl;
  final double? taxRate;
  final String? description;
  final String? expiryDate;

  const ProductModel({
    required this.id,
    this.uuid,
    this.categoryId,
    this.category,
    required this.name,
    this.barcode,
    this.sku,
    required this.unit,
    required this.sellingPrice,
    required this.costPrice,
    this.wholesalePrice,
    required this.quantity,
    required this.reorderLevel,
    required this.trackInventory,
    required this.allowNegativeStock,
    required this.isActive,
    this.imageUrl,
    this.taxRate,
    this.description,
    this.expiryDate,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) => ProductModel(
        id: json['id'] as int,
        uuid: json['uuid'] as String?,
        categoryId: json['category_id'] as int?,
        category: json['category'] != null
            ? CategoryModel.fromJson(json['category'] as Map<String, dynamic>)
            : null,
        name: json['name'] as String,
        barcode: json['barcode'] as String?,
        sku: json['sku'] as String?,
        unit: json['unit'] as String? ?? 'piece',
        sellingPrice: (json['selling_price'] as num?)?.toDouble() ?? 0.0,
        costPrice: (json['cost_price'] as num?)?.toDouble() ?? 0.0,
        wholesalePrice: (json['wholesale_price'] as num?)?.toDouble(),
        quantity: (json['quantity'] as num?)?.toDouble() ?? 0.0,
        reorderLevel: (json['reorder_level'] as num?)?.toDouble() ?? 5.0,
        trackInventory: json['track_inventory'] as bool? ?? true,
        allowNegativeStock: json['allow_negative_stock'] as bool? ?? false,
        isActive: json['is_active'] as bool? ?? true,
        imageUrl: json['image_url'] as String?,
        taxRate: (json['tax_rate'] as num?)?.toDouble(),
        description: json['description'] as String?,
        expiryDate: json['expiry_date'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'barcode': barcode,
        'sku': sku,
        'unit': unit,
        'selling_price': sellingPrice,
        'cost_price': costPrice,
        'wholesale_price': wholesalePrice,
        'quantity': quantity,
        'reorder_level': reorderLevel,
        'track_inventory': trackInventory,
        'allow_negative_stock': allowNegativeStock,
        'category_id': categoryId,
        'description': description,
        'tax_rate': taxRate,
        'expiry_date': expiryDate,
      };

  bool get isLowStock =>
      trackInventory && quantity > 0 && quantity <= reorderLevel;
  bool get isOutOfStock => trackInventory && quantity <= 0;

  double get profit => sellingPrice - costPrice;
  double get profitMargin =>
      sellingPrice > 0 ? (profit / sellingPrice) * 100 : 0;

  ProductModel copyWith({
    int? id,
    String? name,
    double? sellingPrice,
    double? costPrice,
    double? quantity,
    bool? isActive,
  }) =>
      ProductModel(
        id: id ?? this.id,
        uuid: uuid,
        categoryId: categoryId,
        category: category,
        name: name ?? this.name,
        barcode: barcode,
        sku: sku,
        unit: unit,
        sellingPrice: sellingPrice ?? this.sellingPrice,
        costPrice: costPrice ?? this.costPrice,
        wholesalePrice: wholesalePrice,
        quantity: quantity ?? this.quantity,
        reorderLevel: reorderLevel,
        trackInventory: trackInventory,
        allowNegativeStock: allowNegativeStock,
        isActive: isActive ?? this.isActive,
        imageUrl: imageUrl,
        taxRate: taxRate,
        description: description,
        expiryDate: expiryDate,
      );
}

/// Paginated wrapper returned from GET /products
class ProductPage {
  final List<ProductModel> items;
  final int total;
  final int perPage;
  final int currentPage;
  final int lastPage;

  const ProductPage({
    required this.items,
    required this.total,
    required this.perPage,
    required this.currentPage,
    required this.lastPage,
  });

  bool get hasMore => currentPage < lastPage;

  factory ProductPage.fromResponse(Map<String, dynamic> response) {
    final rawItems = response['data'] as List<dynamic>? ?? [];
    final meta = response['meta'] as Map<String, dynamic>? ?? {};
    return ProductPage(
      items: rawItems
          .map((e) => ProductModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: meta['total'] as int? ?? 0,
      perPage: meta['per_page'] as int? ?? 20,
      currentPage: meta['current_page'] as int? ?? 1,
      lastPage: meta['last_page'] as int? ?? 1,
    );
  }
}
