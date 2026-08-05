import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';

import '../../data/models/product_model.dart';
import '../network/api_client.dart';

class ProductProvider extends ChangeNotifier {
  final ApiClient _api = ApiClient();

  List<ProductModel> _products = [];
  List<CategoryModel> _categories = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _errorMessage;
  int _currentPage = 1;
  int _lastPage = 1;
  String _search = '';
  int? _selectedCategoryId;

  // ─── Getters ──────────────────────────────────────────────────────────────

  List<ProductModel> get products => _products;
  List<CategoryModel> get categories => _categories;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get errorMessage => _errorMessage;
  bool get hasMore => _currentPage < _lastPage;
  String get search => _search;
  int? get selectedCategoryId => _selectedCategoryId;

  // ─── Load first page ──────────────────────────────────────────────────────

  Future<void> loadProducts({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _lastPage = 1;
      _products = [];
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _api.getProducts(
        search: _search,
        categoryId: _selectedCategoryId,
        page: 1,
      );
      final page = ProductPage.fromResponse(
          response.data as Map<String, dynamic>);
      _products = page.items;
      _currentPage = page.currentPage;
      _lastPage = page.lastPage;
    } on DioException catch (e) {
      _errorMessage = dioErrorMessage(e);
    } catch (e) {
      _errorMessage = 'Failed to load products.';
    }

    _isLoading = false;
    notifyListeners();
  }

  // ─── Load next page ───────────────────────────────────────────────────────

  Future<void> loadMore() async {
    if (_isLoadingMore || !hasMore) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      final response = await _api.getProducts(
        search: _search,
        categoryId: _selectedCategoryId,
        page: _currentPage + 1,
      );
      final page = ProductPage.fromResponse(
          response.data as Map<String, dynamic>);
      _products = [..._products, ...page.items];
      _currentPage = page.currentPage;
      _lastPage = page.lastPage;
    } on DioException catch (e) {
      _errorMessage = dioErrorMessage(e);
    } catch (_) {}

    _isLoadingMore = false;
    notifyListeners();
  }

  // ─── Search & filter ─────────────────────────────────────────────────────

  void setSearch(String query) {
    _search = query;
    loadProducts(refresh: true);
  }

  void setCategory(int? categoryId) {
    _selectedCategoryId = categoryId;
    loadProducts(refresh: true);
  }

  // ─── Create ───────────────────────────────────────────────────────────────

  Future<String?> createProduct(Map<String, dynamic> data) async {
    try {
      final response = await _api.createProduct(data);
      final body = ApiResponse.fromResponse(response);
      if (body.success) {
        final newProduct = ProductModel.fromJson(
            (body.data as Map<String, dynamic>)['product']
                as Map<String, dynamic>);
        _products = [newProduct, ..._products];
        notifyListeners();
        return null; // no error
      }
      return body.message;
    } on DioException catch (e) {
      return dioErrorMessage(e);
    } catch (_) {
      return 'Failed to create product.';
    }
  }

  // ─── Update ───────────────────────────────────────────────────────────────

  Future<String?> updateProduct(int id, Map<String, dynamic> data) async {
    try {
      final response = await _api.updateProduct(id, data);
      final body = ApiResponse.fromResponse(response);
      if (body.success) {
        final updated = ProductModel.fromJson(
            (body.data as Map<String, dynamic>)['product']
                as Map<String, dynamic>);
        _products = _products
            .map((p) => p.id == id ? updated : p)
            .toList();
        notifyListeners();
        return null;
      }
      return body.message;
    } on DioException catch (e) {
      return dioErrorMessage(e);
    } catch (_) {
      return 'Failed to update product.';
    }
  }

  // ─── Delete ───────────────────────────────────────────────────────────────

  Future<String?> deleteProduct(int id) async {
    try {
      final response = await _api.deleteProduct(id);
      final body = ApiResponse.fromResponse(response);
      if (body.success) {
        _products = _products.where((p) => p.id != id).toList();
        notifyListeners();
        return null;
      }
      return body.message;
    } on DioException catch (e) {
      return dioErrorMessage(e);
    } catch (_) {
      return 'Failed to delete product.';
    }
  }

  // ─── Barcode lookup ───────────────────────────────────────────────────────

  Future<ProductModel?> lookupBarcode(String barcode) async {
    try {
      final response = await _api.lookupBarcode(barcode);
      final body = ApiResponse.fromResponse(response);
      if (body.success) {
        return ProductModel.fromJson(
            (body.data as Map<String, dynamic>)['product']
                as Map<String, dynamic>);
      }
    } catch (_) {}
    return null;
  }

  // ─── Adjust stock ─────────────────────────────────────────────────────────

  Future<String?> adjustStock(int productId, String type, double qty) async {
    try {
      // Convert type + qty to new_quantity that the API expects
      ProductModel? current = _products.firstWhere((p) => p.id == productId, orElse: () => throw Exception('not found'));
      double newQty;
      if (type == 'in')  newQty = current.quantity + qty;
      else if (type == 'out') newQty = (current.quantity - qty).clamp(0, double.infinity);
      else newQty = qty; // 'set'

      final response = await _api.adjustStock(productId, {
        'new_quantity': newQty,
        'type': type == 'in' ? 'adjustment' : type == 'out' ? 'adjustment' : 'adjustment',
        'reason': 'Manual stock adjustment',
      });
      final body = ApiResponse.fromResponse(response);
      if (body.success) {
        // Refresh the product in list
        final updated = ProductModel.fromJson(
            (body.data as Map<String, dynamic>)['product']
                as Map<String, dynamic>);
        _products = _products.map((p) => p.id == productId ? updated : p).toList();
        notifyListeners();
        return null;
      }
      return body.message;
    } on DioException catch (e) {
      return dioErrorMessage(e);
    } catch (_) {
      return 'Failed to adjust stock.';
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
