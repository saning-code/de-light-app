import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_constants.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal() {
    _init();
  }

  late final Dio dio;
  final _storage = const FlutterSecureStorage();

  void _init() {
    dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.baseUrl,
        connectTimeout: AppConstants.connectTimeout,
        receiveTimeout: AppConstants.receiveTimeout,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.read(key: AppConstants.kJwtToken);
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException error, handler) async {
          if (error.response?.statusCode == 401) {
            // Clear stale token — app router will redirect to login
            await _storage.delete(key: AppConstants.kJwtToken);
          }
          return handler.next(error);
        },
      ),
    );
  }

  // ─── Auth ─────────────────────────────────────────────────────────────────

  Future<Response> login(String email, String password, {
    String? deviceId,
    String? deviceName,
    String? fcmToken,
  }) =>
      dio.post('/auth/login', data: {
        'email': email,
        'password': password,
        if (deviceId != null) 'device_id': deviceId,
        if (deviceName != null) 'device_name': deviceName,
        if (fcmToken != null) 'fcm_token': fcmToken,
      });

  Future<Response> register(Map<String, dynamic> data) =>
      dio.post('/auth/register', data: data);

  Future<Response> pinLogin(String userUuid, String pin) =>
      dio.post('/auth/pin-login', data: {'user_uuid': userUuid, 'pin': pin});

  Future<Response> logout() => dio.post('/auth/logout');

  Future<Response> refreshToken() => dio.post('/auth/refresh');

  Future<Response> getMe() => dio.get('/auth/me');

  Future<Response> setPin(String pin) =>
      dio.post('/auth/set-pin', data: {'pin': pin, 'pin_confirmation': pin});

  // ─── Dashboard / Reports ──────────────────────────────────────────────────

  Future<Response> getDashboard({int? shopId}) =>
      dio.get('/reports/dashboard', queryParameters: {
        if (shopId != null) 'shop_id': shopId,
      });

  Future<Response> getPeriodReport({
    required String period,
    String? from,
    String? to,
    int? shopId,
  }) =>
      dio.get('/reports/period', queryParameters: {
        'period': period,
        if (from != null) 'from': from,
        if (to != null) 'to': to,
        if (shopId != null) 'shop_id': shopId,
      });

  // ─── Products ────────────────────────────────────────────────────────────

  Future<Response> getProducts({
    String? search,
    int? categoryId,
    bool? lowStock,
    bool? outOfStock,
    bool? isActive,
    int page = 1,
    int perPage = AppConstants.defaultPerPage,
  }) =>
      dio.get('/products', queryParameters: {
        'page': page,
        'per_page': perPage,
        if (search != null && search.isNotEmpty) 'search': search,
        if (categoryId != null) 'category_id': categoryId,
        if (lowStock == true) 'low_stock': 1,
        if (outOfStock == true) 'out_of_stock': 1,
        if (isActive != null) 'is_active': isActive ? 1 : 0,
      });

  Future<Response> getProduct(int id) => dio.get('/products/$id');

  Future<Response> createProduct(Map<String, dynamic> data) =>
      dio.post('/products', data: data);

  Future<Response> updateProduct(int id, Map<String, dynamic> data) =>
      dio.put('/products/$id', data: data);

  Future<Response> deleteProduct(int id) => dio.delete('/products/$id');

  Future<Response> lookupBarcode(String barcode) =>
      dio.get('/products/barcode/$barcode');

  Future<Response> adjustStock(int productId, Map<String, dynamic> data) =>
      dio.post('/products/$productId/adjust-stock', data: data);

  Future<Response> getStockValue() => dio.get('/products/stock-value');

  Future<Response> bulkImportProducts(List<Map<String, dynamic>> products) =>
      dio.post('/products/bulk-import', data: {'products': products});

  // ─── Sales ───────────────────────────────────────────────────────────────

  Future<Response> getSales({
    String? status,
    String? paymentMethod,
    int? customerId,
    String? dateFrom,
    String? dateTo,
    String? search,
    int page = 1,
    int perPage = AppConstants.defaultPerPage,
  }) =>
      dio.get('/sales', queryParameters: {
        'page': page,
        'per_page': perPage,
        if (status != null) 'status': status,
        if (paymentMethod != null) 'payment_method': paymentMethod,
        if (customerId != null) 'customer_id': customerId,
        if (dateFrom != null) 'date_from': dateFrom,
        if (dateTo != null) 'date_to': dateTo,
        if (search != null && search.isNotEmpty) 'search': search,
      });

  Future<Response> getSale(int id) => dio.get('/sales/$id');

  Future<Response> createSale(Map<String, dynamic> data) =>
      dio.post('/sales', data: data);

  Future<Response> voidSale(int id, {String? reason}) =>
      dio.post('/sales/$id/void', data: {'reason': reason ?? ''});

  Future<Response> getReceipt(int id) => dio.get('/sales/$id/receipt');

  Future<Response> getTodaySummary({int? shopId}) =>
      dio.get('/sales/today-summary', queryParameters: {
        if (shopId != null) 'shop_id': shopId,
      });

  // ─── Sync ────────────────────────────────────────────────────────────────

  Future<Response> syncPush(Map<String, dynamic> data) =>
      dio.post('/sync/push', data: data);

  Future<Response> syncPull({String? lastSyncedAt}) =>
      dio.get('/sync/pull', queryParameters: {
        if (lastSyncedAt != null) 'last_synced_at': lastSyncedAt,
      });

  Future<Response> getSyncStatus({String? deviceId}) =>
      dio.get('/sync/status', queryParameters: {
        if (deviceId != null) 'device_id': deviceId,
      });

  // ─── Token helpers ────────────────────────────────────────────────────────

  Future<void> saveToken(String token) =>
      _storage.write(key: AppConstants.kJwtToken, value: token);

  Future<void> clearToken() =>
      _storage.delete(key: AppConstants.kJwtToken);

  Future<String?> getToken() =>
      _storage.read(key: AppConstants.kJwtToken);

  Future<bool> get hasToken async {
    final token = await _storage.read(key: AppConstants.kJwtToken);
    return token != null && token.isNotEmpty;
  }
}

/// Parses a Dio response body that follows the API's standard shape:
/// { "success": bool, "message": string, "data": ... }
class ApiResponse {
  final bool success;
  final String message;
  final dynamic data;

  const ApiResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory ApiResponse.fromResponse(Response response) {
    final body = response.data as Map<String, dynamic>;
    return ApiResponse(
      success: body['success'] as bool? ?? false,
      message: body['message'] as String? ?? '',
      data: body['data'],
    );
  }
}

/// Helper to extract a user-friendly error message from DioException.
String dioErrorMessage(DioException e) {
  if (e.response != null) {
    final data = e.response!.data;
    if (data is Map && data['message'] != null) {
      return data['message'].toString();
    }
    return 'Server error (${e.response!.statusCode})';
  }
  if (e.type == DioExceptionType.connectionTimeout ||
      e.type == DioExceptionType.receiveTimeout) {
    return 'Connection timed out. Check your internet.';
  }
  if (e.type == DioExceptionType.connectionError) {
    return 'Cannot connect to server. Are you online?';
  }
  return e.message ?? 'Unknown error';
}
