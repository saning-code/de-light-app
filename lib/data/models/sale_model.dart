import 'product_model.dart';

class SaleItemModel {
  final int id;
  final int productId;
  final String productName;
  final String productUnit;
  final double quantity;
  final double unitPrice;
  final double costPrice;
  final double discountAmount;
  final double taxAmount;
  final double subtotal;
  final double profit;
  final ProductModel? product;

  const SaleItemModel({
    required this.id,
    required this.productId,
    required this.productName,
    required this.productUnit,
    required this.quantity,
    required this.unitPrice,
    required this.costPrice,
    required this.discountAmount,
    required this.taxAmount,
    required this.subtotal,
    required this.profit,
    this.product,
  });

  factory SaleItemModel.fromJson(Map<String, dynamic> json) => SaleItemModel(
        id: json['id'] as int,
        productId: json['product_id'] as int,
        productName: json['product_name'] as String,
        productUnit: json['product_unit'] as String? ?? 'pcs',
        quantity: (json['quantity'] as num).toDouble(),
        unitPrice: (json['unit_price'] as num).toDouble(),
        costPrice: (json['cost_price'] as num?)?.toDouble() ?? 0.0,
        discountAmount: (json['discount_amount'] as num?)?.toDouble() ?? 0.0,
        taxAmount: (json['tax_amount'] as num?)?.toDouble() ?? 0.0,
        subtotal: (json['subtotal'] as num).toDouble(),
        profit: (json['profit'] as num?)?.toDouble() ?? 0.0,
        product: json['product'] != null
            ? ProductModel.fromJson(json['product'] as Map<String, dynamic>)
            : null,
      );
}

class SaleCustomerModel {
  final int id;
  final String name;
  final String? phone;

  const SaleCustomerModel({
    required this.id,
    required this.name,
    this.phone,
  });

  factory SaleCustomerModel.fromJson(Map<String, dynamic> json) =>
      SaleCustomerModel(
        id: json['id'] as int,
        name: json['name'] as String,
        phone: json['phone'] as String?,
      );
}

class SaleModel {
  final int id;
  final String? uuid;
  final String saleNumber;
  final double subtotal;
  final double discountAmount;
  final double discountPercent;
  final double taxAmount;
  final double total;
  final double amountPaid;
  final double changeGiven;
  final double creditAmount;
  final String paymentMethod;
  final String status;
  final bool isCreditSale;
  final String? note;
  final String createdAt;
  final List<SaleItemModel> items;
  final SaleCustomerModel? customer;

  const SaleModel({
    required this.id,
    this.uuid,
    required this.saleNumber,
    required this.subtotal,
    required this.discountAmount,
    required this.discountPercent,
    required this.taxAmount,
    required this.total,
    required this.amountPaid,
    required this.changeGiven,
    required this.creditAmount,
    required this.paymentMethod,
    required this.status,
    required this.isCreditSale,
    this.note,
    required this.createdAt,
    required this.items,
    this.customer,
  });

  factory SaleModel.fromJson(Map<String, dynamic> json) => SaleModel(
        id: json['id'] as int,
        uuid: json['uuid'] as String?,
        saleNumber: json['sale_number'] as String,
        subtotal: (json['subtotal'] as num).toDouble(),
        discountAmount: (json['discount_amount'] as num?)?.toDouble() ?? 0.0,
        discountPercent: (json['discount_percent'] as num?)?.toDouble() ?? 0.0,
        taxAmount: (json['tax_amount'] as num?)?.toDouble() ?? 0.0,
        total: (json['total'] as num).toDouble(),
        amountPaid: (json['amount_paid'] as num).toDouble(),
        changeGiven: (json['change_given'] as num?)?.toDouble() ?? 0.0,
        creditAmount: (json['credit_amount'] as num?)?.toDouble() ?? 0.0,
        paymentMethod: json['payment_method'] as String,
        status: json['status'] as String,
        isCreditSale: json['is_credit_sale'] as bool? ?? false,
        note: json['note'] as String?,
        createdAt: json['created_at'] as String,
        items: (json['items'] as List<dynamic>?)
                ?.map((e) => SaleItemModel.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        customer: json['customer'] != null
            ? SaleCustomerModel.fromJson(
                json['customer'] as Map<String, dynamic>)
            : null,
      );

  bool get isVoided => status == 'voided';
  bool get isCompleted => status == 'completed';
}

/// Paginated wrapper for GET /sales
class SalePage {
  final List<SaleModel> items;
  final int total;
  final int currentPage;
  final int lastPage;

  const SalePage({
    required this.items,
    required this.total,
    required this.currentPage,
    required this.lastPage,
  });

  bool get hasMore => currentPage < lastPage;

  factory SalePage.fromResponse(Map<String, dynamic> response) {
    final rawItems = response['data'] as List<dynamic>? ?? [];
    final meta = response['meta'] as Map<String, dynamic>? ?? {};
    return SalePage(
      items: rawItems
          .map((e) => SaleModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: meta['total'] as int? ?? 0,
      currentPage: meta['current_page'] as int? ?? 1,
      lastPage: meta['last_page'] as int? ?? 1,
    );
  }
}

/// Cart item used locally in the POS screen before a sale is submitted
class CartItem {
  final ProductModel product;
  double quantity;
  double unitPrice;
  double discountAmount;

  CartItem({
    required this.product,
    this.quantity = 1,
    required this.unitPrice,
    this.discountAmount = 0,
  });

  double get subtotal => (unitPrice * quantity) - discountAmount;

  Map<String, dynamic> toSaleItemPayload() => {
        'product_id': product.id,
        'quantity': quantity,
        'unit_price': unitPrice,
        'discount_amount': discountAmount,
      };
}
