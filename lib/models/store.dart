import 'package:json_annotation/json_annotation.dart';

part 'store.g.dart';

@JsonSerializable()
class StoreResponse {
  int id;
  String storeName;
  int companyId;
  String storeAddress;
  double? latitude;
  double? longitude;
  DateTime? createdAt;

  StoreResponse({
    required this.id,
    required this.storeName,
    required this.companyId,
    required this.storeAddress,
    this.latitude,
    this.longitude,
    this.createdAt,
  });

  factory StoreResponse.fromJson(Map<String, dynamic> json) =>
      _$StoreResponseFromJson(json);

  Map<String, dynamic> toJson() => _$StoreResponseToJson(this);
}

@JsonSerializable()
class StoreWithInventoryResponse {
  int id;
  String storeName;
  String storeAddress;
  double? latitude;
  double? longitude;
  int quantity;

  StoreWithInventoryResponse({
    required this.id,
    required this.storeName,
    required this.storeAddress,
    this.latitude,
    this.longitude,
    required this.quantity,
  });

  factory StoreWithInventoryResponse.fromJson(Map<String, dynamic> json) =>
      _$StoreWithInventoryResponseFromJson(json);

  Map<String, dynamic> toJson() => _$StoreWithInventoryResponseToJson(this);
}
