class UserModel {
  final int id;
  final String uuid;
  final String name;
  final String email;
  final String? phone;
  final String role;
  final String? avatarUrl;
  final int shopId;
  final int tenantId;

  const UserModel({
    required this.id,
    required this.uuid,
    required this.name,
    required this.email,
    this.phone,
    required this.role,
    this.avatarUrl,
    required this.shopId,
    required this.tenantId,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] as int,
        uuid: json['uuid'] as String,
        name: json['name'] as String,
        email: json['email'] as String,
        phone: json['phone'] as String?,
        role: json['role'] as String,
        avatarUrl: json['avatar_url'] as String?,
        shopId: json['shop_id'] as int,
        tenantId: json['tenant_id'] as int,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'uuid': uuid,
        'name': name,
        'email': email,
        'phone': phone,
        'role': role,
        'avatar_url': avatarUrl,
        'shop_id': shopId,
        'tenant_id': tenantId,
      };

  bool get isOwner => role == 'owner';
  bool get isManager => role == 'manager';
  bool get isCashier => role == 'cashier';

  @override
  String toString() => 'UserModel(id: $id, name: $name, role: $role)';
}

class PermissionsModel {
  final bool canGiveDiscount;
  final double maxDiscountPercent;
  final bool canDeleteSale;
  final bool canViewReports;
  final bool canManageProducts;
  final bool canManageUsers;
  final bool canViewCostPrice;

  const PermissionsModel({
    required this.canGiveDiscount,
    required this.maxDiscountPercent,
    required this.canDeleteSale,
    required this.canViewReports,
    required this.canManageProducts,
    required this.canManageUsers,
    required this.canViewCostPrice,
  });

  factory PermissionsModel.fromJson(Map<String, dynamic> json) =>
      PermissionsModel(
        canGiveDiscount: json['can_give_discount'] as bool? ?? false,
        maxDiscountPercent:
            (json['max_discount_percent'] as num?)?.toDouble() ?? 0.0,
        canDeleteSale: json['can_delete_sale'] as bool? ?? false,
        canViewReports: json['can_view_reports'] as bool? ?? false,
        canManageProducts: json['can_manage_products'] as bool? ?? false,
        canManageUsers: json['can_manage_users'] as bool? ?? false,
        canViewCostPrice: json['can_view_cost_price'] as bool? ?? false,
      );

  // Full-access permissions for owners
  factory PermissionsModel.ownerDefault() => const PermissionsModel(
        canGiveDiscount: true,
        maxDiscountPercent: 100,
        canDeleteSale: true,
        canViewReports: true,
        canManageProducts: true,
        canManageUsers: true,
        canViewCostPrice: true,
      );
}

class TenantModel {
  final int id;
  final String uuid;
  final String businessName;
  final String? businessCode;
  final String? businessType;
  final String? logoUrl;
  final String status;
  final String currency;
  final String currencySymbol;
  final String? trialEndsAt;
  final String? subscriptionEndsAt;

  const TenantModel({
    required this.id,
    required this.uuid,
    required this.businessName,
    this.businessCode,
    this.businessType,
    this.logoUrl,
    required this.status,
    required this.currency,
    required this.currencySymbol,
    this.trialEndsAt,
    this.subscriptionEndsAt,
  });

  factory TenantModel.fromJson(Map<String, dynamic> json) => TenantModel(
        id: json['id'] as int,
        uuid: json['uuid'] as String,
        businessName: json['business_name'] as String,
        businessCode: json['business_code'] as String?,
        businessType: json['business_type'] as String?,
        logoUrl: json['logo_url'] as String?,
        status: json['status'] as String? ?? 'trial',
        currency: json['currency'] as String? ?? 'GHS',
        currencySymbol: json['currency_symbol'] as String? ?? 'GH₵',
        trialEndsAt: json['trial_ends_at'] as String?,
        subscriptionEndsAt: json['subscription_ends_at'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'uuid': uuid,
        'business_name': businessName,
        'business_code': businessCode,
        'currency': currency,
        'currency_symbol': currencySymbol,
        'status': status,
      };
}

class ShopModel {
  final int id;
  final String name;
  final String? type;
  final String? city;
  final String? phone;
  final String? address;
  final bool isPrimary;
  final bool isActive;

  const ShopModel({
    required this.id,
    required this.name,
    this.type,
    this.city,
    this.phone,
    this.address,
    required this.isPrimary,
    required this.isActive,
  });

  factory ShopModel.fromJson(Map<String, dynamic> json) => ShopModel(
        id: json['id'] as int,
        name: json['name'] as String,
        type: json['type'] as String?,
        city: json['city'] as String?,
        phone: json['phone'] as String?,
        address: json['address'] as String?,
        isPrimary: json['is_primary'] as bool? ?? false,
        isActive: json['is_active'] as bool? ?? true,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type,
        'city': city,
      };
}
