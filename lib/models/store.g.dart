// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'store.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StoreResponse _$StoreResponseFromJson(Map<String, dynamic> json) =>
    StoreResponse(
      id: (json['id'] as num).toInt(),
        storeName: (json['storeName'] as String?) ?? '',
      companyId: (json['companyId'] as num).toInt(),
        storeAddress: (json['storeAddress'] as String?) ?? '',
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$StoreResponseToJson(StoreResponse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'storeName': instance.storeName,
      'companyId': instance.companyId,
      'storeAddress': instance.storeAddress,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'createdAt': instance.createdAt?.toIso8601String(),
    };

StoreWithInventoryResponse _$StoreWithInventoryResponseFromJson(
  Map<String, dynamic> json,
) => StoreWithInventoryResponse(
  id: (json['id'] as num).toInt(),
  storeName: (json['storeName'] as String?) ?? '',
  storeAddress: (json['storeAddress'] as String?) ?? '',
  latitude: (json['latitude'] as num?)?.toDouble(),
  longitude: (json['longitude'] as num?)?.toDouble(),
  quantity: (json['quantity'] as num).toInt(),
);

Map<String, dynamic> _$StoreWithInventoryResponseToJson(
  StoreWithInventoryResponse instance,
) => <String, dynamic>{
  'id': instance.id,
  'storeName': instance.storeName,
  'storeAddress': instance.storeAddress,
  'latitude': instance.latitude,
  'longitude': instance.longitude,
  'quantity': instance.quantity,
};
