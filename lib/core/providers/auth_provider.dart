import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';

import '../../data/models/user_model.dart';
import '../constants/app_constants.dart';
import '../network/api_client.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  final ApiClient _api = ApiClient();
  final _storage = const FlutterSecureStorage();

  AuthStatus _status = AuthStatus.unknown;
  UserModel? _user;
  TenantModel? _tenant;
  ShopModel? _shop;
  PermissionsModel? _permissions;
  String? _errorMessage;
  bool _isLoading = false;

  // ─── Getters ──────────────────────────────────────────────────────────────

  AuthStatus get status => _status;
  UserModel? get user => _user;
  TenantModel? get tenant => _tenant;
  ShopModel? get shop => _shop;
  PermissionsModel? get permissions => _permissions;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  String get currencySymbol => _tenant?.currencySymbol ?? 'GH₵';
  String get businessName => _tenant?.businessName ?? 'De-Light';
  String get shopName => _shop?.name ?? 'My Shop';

  // ─── Boot: restore session from secure storage ────────────────────────────

  Future<void> tryRestoreSession() async {
    _status = AuthStatus.unknown;
    notifyListeners();

    final token = await _storage.read(key: AppConstants.kJwtToken);
    if (token == null || token.isEmpty) {
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }

    // Try to load cached user data first so UI shows instantly
    await _loadCachedSession();

    // Then silently verify token is still valid with the server
    try {
      final response = await _api.getMe();
      final body = ApiResponse.fromResponse(response);
      if (body.success) {
        _applySessionData(body.data as Map<String, dynamic>);
        _status = AuthStatus.authenticated;
      } else {
        await _clearSession();
        _status = AuthStatus.unauthenticated;
      }
    } on DioException catch (_) {
      // No connectivity — keep using cached session if we have one
      if (_user != null) {
        _status = AuthStatus.authenticated;
      } else {
        _status = AuthStatus.unauthenticated;
      }
    } catch (_) {
      await _clearSession();
      _status = AuthStatus.unauthenticated;
    }

    notifyListeners();
  }

  // ─── Login ────────────────────────────────────────────────────────────────

  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final response = await _api.login(email, password);
      final body = ApiResponse.fromResponse(response);

      if (body.success) {
        final data = body.data as Map<String, dynamic>;
        final token = data['token'] as String;
        await _api.saveToken(token);
        await _saveAndApplySession(data);
        _status = AuthStatus.authenticated;
        _setLoading(false);
        return true;
      } else {
        _errorMessage = body.message;
        _setLoading(false);
        return false;
      }
    } on DioException catch (e) {
      _errorMessage = dioErrorMessage(e);
      _setLoading(false);
      return false;
    } catch (e) {
      _errorMessage = 'Unexpected error. Please try again.';
      _setLoading(false);
      return false;
    }
  }

  // ─── Register ─────────────────────────────────────────────────────────────

  Future<bool> register(Map<String, dynamic> registrationData) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final response = await _api.register(registrationData);
      final body = ApiResponse.fromResponse(response);

      if (body.success) {
        final data = body.data as Map<String, dynamic>;
        final token = data['token'] as String;
        await _api.saveToken(token);
        await _saveAndApplySession(data);
        _status = AuthStatus.authenticated;
        _setLoading(false);
        return true;
      } else {
        _errorMessage = body.message;
        _setLoading(false);
        return false;
      }
    } on DioException catch (e) {
      _errorMessage = dioErrorMessage(e);
      _setLoading(false);
      return false;
    } catch (e) {
      _errorMessage = 'Registration failed. Please try again.';
      _setLoading(false);
      return false;
    }
  }

  // ─── Logout ───────────────────────────────────────────────────────────────

  Future<void> logout() async {
    _setLoading(true);
    try {
      await _api.logout();
    } catch (_) {
      // Ignore — clear locally regardless
    }
    await _clearSession();
    _status = AuthStatus.unauthenticated;
    _setLoading(false);
  }

  // ─── Refresh profile ──────────────────────────────────────────────────────

  Future<void> refreshProfile() async {
    try {
      final response = await _api.getMe();
      final body = ApiResponse.fromResponse(response);
      if (body.success) {
        _applySessionData(body.data as Map<String, dynamic>);
        notifyListeners();
      }
    } catch (_) {}
  }

  // ─── Clear error ─────────────────────────────────────────────────────────

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // ─── Private helpers ──────────────────────────────────────────────────────

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _applySessionData(Map<String, dynamic> data) {
    if (data['user'] != null) {
      _user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
    }
    if (data['tenant'] != null) {
      _tenant = TenantModel.fromJson(data['tenant'] as Map<String, dynamic>);
    }
    if (data['shop'] != null) {
      _shop = ShopModel.fromJson(data['shop'] as Map<String, dynamic>);
    }
    if (data['permissions'] != null) {
      _permissions = PermissionsModel.fromJson(
          data['permissions'] as Map<String, dynamic>);
    } else if (_user?.isOwner == true) {
      _permissions = PermissionsModel.ownerDefault();
    }
  }

  Future<void> _saveAndApplySession(Map<String, dynamic> data) async {
    _applySessionData(data);
    // Cache user/tenant/shop for offline restoration
    if (_user != null) {
      await _storage.write(
          key: AppConstants.kUserJson, value: jsonEncode(_user!.toJson()));
    }
    if (_tenant != null) {
      await _storage.write(
          key: AppConstants.kTenantJson, value: jsonEncode(_tenant!.toJson()));
    }
    if (_shop != null) {
      await _storage.write(
          key: AppConstants.kShopJson, value: jsonEncode(_shop!.toJson()));
    }
  }

  Future<void> _loadCachedSession() async {
    final userJson = await _storage.read(key: AppConstants.kUserJson);
    final tenantJson = await _storage.read(key: AppConstants.kTenantJson);
    final shopJson = await _storage.read(key: AppConstants.kShopJson);

    if (userJson != null) {
      _user = UserModel.fromJson(jsonDecode(userJson) as Map<String, dynamic>);
    }
    if (tenantJson != null) {
      _tenant = TenantModel.fromJson(
          jsonDecode(tenantJson) as Map<String, dynamic>);
    }
    if (shopJson != null) {
      _shop = ShopModel.fromJson(
          jsonDecode(shopJson) as Map<String, dynamic>);
    }
    if (_user?.isOwner == true) {
      _permissions = PermissionsModel.ownerDefault();
    }
  }

  Future<void> _clearSession() async {
    _user = null;
    _tenant = null;
    _shop = null;
    _permissions = null;
    await _storage.deleteAll();
  }
}
