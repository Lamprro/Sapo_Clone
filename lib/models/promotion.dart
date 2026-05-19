class PromotionResponse {
  final int id;
  final int scope; // 0: Order, 1: Product
  final String promotionName;
  final double discountValue;
  final String discountType; // "0" for Flat, "1" for Percentage
  final double? maxAccount;
  final double? minAccount;
  final String? description;
  final String? startDate;
  final String? endDate;
  final int status;
  final List<int>? productIds;

  PromotionResponse({
    required this.id,
    required this.scope,
    required this.promotionName,
    required this.discountValue,
    required this.discountType,
    this.maxAccount,
    this.minAccount,
    this.description,
    this.startDate,
    this.endDate,
    required this.status,
    this.productIds,
  });

  DateTime? get startedAt => startDate != null ? DateTime.tryParse(startDate!) : null;
  DateTime? get endedAt => endDate != null ? DateTime.tryParse(endDate!) : null;

  factory PromotionResponse.fromJson(Map<String, dynamic> json) {
    return PromotionResponse(
      id: json['id'] as int,
      scope: json['scope'] as int,
      promotionName: json['promotionName'] as String,
      discountValue: (json['discountValue'] as num).toDouble(),
      discountType: json['discountType'] as String,
      maxAccount: (json['maxAccount'] as num?)?.toDouble(),
      minAccount: (json['minAccount'] as num?)?.toDouble(),
      description: json['description'] as String?,
      startDate: json['startDate'] as String?,
      endDate: json['endDate'] as String?,
      status: json['status'] as int,
      productIds: (json['productIds'] as List<dynamic>?)?.map((e) => e as int).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'scope': scope,
    'promotionName': promotionName,
    'discountValue': discountValue,
    'discountType': discountType,
    'maxAccount': maxAccount,
    'minAccount': minAccount,
    'description': description,
    'startDate': startDate,
    'endDate': endDate,
    'status': status,
    'productIds': productIds,
  };
}

class PromotionListResponse {
  final int id;
  final int scope;
  final String promotionName;
  final double discountValue;
  final String discountType; // "0" or "1"
  final double? maxAccount;
  final double? minAccount;
  final String? description;
  final String? startDate;
  final String? endDate;
  final int status;

  PromotionListResponse({
    required this.id,
    required this.scope,
    required this.promotionName,
    required this.discountValue,
    required this.discountType,
    this.maxAccount,
    this.minAccount,
    this.description,
    this.startDate,
    this.endDate,
    required this.status,
  });

  DateTime? get startedAt => startDate != null ? DateTime.tryParse(startDate!) : null;
  DateTime? get endedAt => endDate != null ? DateTime.tryParse(endDate!) : null;

  factory PromotionListResponse.fromJson(Map<String, dynamic> json) {
    return PromotionListResponse(
      id: json['id'] as int,
      scope: json['scope'] as int,
      promotionName: json['promotionName'] as String,
      discountValue: (json['discountValue'] as num).toDouble(),
      discountType: json['discountType'] as String,
      maxAccount: (json['maxAccount'] as num?)?.toDouble(),
      minAccount: (json['minAccount'] as num?)?.toDouble(),
      description: json['description'] as String?,
      startDate: json['startDate'] as String?,
      endDate: json['endDate'] as String?,
      status: json['status'] as int,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'scope': scope,
    'promotionName': promotionName,
    'discountValue': discountValue,
    'discountType': discountType,
    'maxAccount': maxAccount,
    'minAccount': minAccount,
    'description': description,
    'startDate': startDate,
    'endDate': endDate,
    'status': status,
  };
}
