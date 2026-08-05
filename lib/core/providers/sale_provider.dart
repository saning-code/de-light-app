import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';

import '../../data/models/sale_model.dart';
import '../../data/models/product_model.dart';
import '../../data/models/dashboard_model.dart';
import '../network/api_client.dart';

class SaleProvider extends ChangeNotifier {
  final ApiClient _api = ApiClient();

  // ─── Sales list state ─────────────────────────────────────────────────────
  List<SaleModel> _sales = [];
  bool _isLoadingSales = false;
  String? _salesError;
  int _currentPage = 1;
  int _lastPage = 1;

  // ─── Cart state ───────────────────────────────────────────────────────────
  List<CartItem> _cart = [];
  String _paymentMethod = 'cash';
  double _discountPercent = 0.0;
  int? _selectedCustomerId;
  bool _isProcessingSale = false;
  String? _saleError;

  // ─── Dashboard state ──────────────────────────────────────────────────────
  DashboardSummary? _dashboard;
  bool _isLoadingDashboard = false;

  // ─── Getters ──────────────────────────────────────────────────────────────

  List<SaleModel> get sales => _sales;
  bool get isLoadingSales => _isLoadingSales;
  String? get salesError => _salesError;
  bool get hasMoreSales => _currentPage < _lastPage;

  List<CartItem> get cart => _cart;
  String get paymentMethod => _paymentMethod;
  double get discountPercent => _discountPercent;
  int? get selectedCustomerId => _selectedCustomerId;
  bool get isProcessingSale => _isProcessingSale;
  String? get saleError => _saleError;

  DashboardSummary? get dashboard => _dashboard;
  bool get isLoadingDashboard => _isLoadingDashboard;

  int get cartItemCount =>
      _cart.fold(0, (sum, item) => sum + item.quantity.ceil());

  double get cartSubtotal =>
      _cart.fold(0.0, (sum, item) => sum + item.subtotal);

  double get cartDiscountAmount => cartSubtotal * (_discountPercent / 100);

  double get cartTotal => cartSubtotal - cartDiscountAmount;

  // ─── Dashboard ────────────────────────────────────────────────────────────

  Future<void> loadDashboard() async {
    _isLoadingDashboard = true;
    notifyListeners();

    try {
      final response = await _api.getDashboard();
      final body = ApiResponse.fromResponse(response);
      if (body.success) {
        _dashboard = DashboardSummary.fromJson(
            body.data as Map<String, dynamic>);
      }
    } on DioException catch (e) {
      debugPrint('Dashboard error: ${dioErrorMessage(e)}');
    } catch (e) {
      debugPrint('Dashboard error: $e');
    }

    _isLoadingDashboard = false;
    notifyListeners();
  }

  // ─── Sales list ───────────────────────────────────────────────────────────

  Future<void> loadSales({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _lastPage = 1;
      _sales = [];
    }

    _isLoadingSales = true;
    _salesError = null;
    notifyListeners();

    try {
      final response = await _api.getSales(page: 1);
      final page = SalePage.fromResponse(response.data as Map<String, dynamic>);
      _sales = page.items;
      _currentPage = page.currentPage;
      _lastPage = page.lastPage;
    } on DioException catch (e) {
      _salesError = dioErrorMessage(e);
    } catch (_) {
      _salesError = 'Failed to load sales.';
    }

    _isLoadingSales = false;
    notifyListeners();
  }

  Future<void> loadMoreSales() async {
    if (_isLoadingSales || !hasMoreSales) return;
    _isLoadingSales = true;
    notifyListeners();

    try {
      final response =
          await _api.getSales(page: _currentPage + 1);
      final page = SalePage.fromResponse(response.data as Map<String, dynamic>);
      _sales = [..._sales, ...page.items];
      _currentPage = page.currentPage;
      _lastPage = page.lastPage;
    } catch (_) {}

    _isLoadingSales = false;
    notifyListeners();
  }

  // ─── Cart management ─────────────────────────────────────────────────────

  void addToCart(ProductModel product) {
    final idx = _cart.indexWhere((i) => i.product.id == product.id);
    if (idx >= 0) {
      _cart[idx].quantity++;
    } else {
      _cart.add(CartItem(
        product: product,
        unitPrice: product.sellingPrice,
      ));
    }
    notifyListeners();
  }

  void removeFromCart(int productId) {
    _cart.removeWhere((i) => i.product.id == productId);
    notifyListeners();
  }

  void updateCartQty(int productId, double qty) {
    final idx = _cart.indexWhere((i) => i.product.id == productId);
    if (idx < 0) return;
    if (qty <= 0) {
      _cart.removeAt(idx);
    } else {
      _cart[idx].quantity = qty;
    }
    notifyListeners();
  }

  void updateCartItemPrice(int productId, double price) {
    final idx = _cart.indexWhere((i) => i.product.id == productId);
    if (idx < 0) return;
    _cart[idx].unitPrice = price;
    notifyListeners();
  }

  void setPaymentMethod(String method) {
    _paymentMethod = method;
    notifyListeners();
  }

  void setDiscount(double percent) {
    _discountPercent = percent.clamp(0, 100);
    notifyListeners();
  }

  void setCustomer(int? customerId) {
    _selectedCustomerId = customerId;
    notifyListeners();
  }

  void clearCart() {
    _cart = [];
    _discountPercent = 0;
    _paymentMethod = 'cash';
    _selectedCustomerId = null;
    _saleError = null;
    notifyListeners();
  }

  // ─── Process sale ─────────────────────────────────────────────────────────

  /// Returns the created SaleModel on success, or null on failure.
  /// Check [saleError] for the error message.
  Future<SaleModel?> processSale({
    required double amountPaid,
    String? note,
  }) async {
    if (_cart.isEmpty) return null;

    _isProcessingSale = true;
    _saleError = null;
    notifyListeners();

    try {
      final payload = {
        'items': _cart.map((i) => i.toSaleItemPayload()).toList(),
        'amount_paid': amountPaid,
        'payment_method': _paymentMethod,
        'discount_percent': _discountPercent,
        if (_selectedCustomerId != null) 'customer_id': _selectedCustomerId,
        if (note != null && note.isNotEmpty) 'note': note,
      };

      final response = await _api.createSale(payload);
      final body = ApiResponse.fromResponse(response);

      if (body.success) {
        final sale = SaleModel.fromJson(
            (body.data as Map<String, dynamic>)['sale']
                as Map<String, dynamic>);
        // Prepend to sales list so it appears at top
        _sales = [sale, ..._sales];
        clearCart();
        _isProcessingSale = false;
        notifyListeners();
        return sale;
      } else {
        _saleError = body.message;
      }
    } on DioException catch (e) {
      _saleError = dioErrorMessage(e);
    } catch (e) {
      _saleError = 'Sale failed. Please try again.';
    }

    _isProcessingSale = false;
    notifyListeners();
    return null;
  }

  // ─── Void sale ────────────────────────────────────────────────────────────

  Future<String?> voidSale(int saleId, {String? reason}) async {
    try {
      final response = await _api.voidSale(saleId, reason: reason);
      final body = ApiResponse.fromResponse(response);
      if (body.success) {
        _sales = _sales.map((s) {
          if (s.id == saleId) {
            return SaleModel.fromJson(
                (body.data as Map<String, dynamic>)['sale']
                    as Map<String, dynamic>);
          }
          return s;
        }).toList();
        notifyListeners();
        return null;
      }
      return body.message;
    } on DioException catch (e) {
      return dioErrorMessage(e);
    } catch (_) {
      return 'Failed to void sale.';
    }
  }

  void clearSaleError() {
    _saleError = null;
    notifyListeners();
  }
}
