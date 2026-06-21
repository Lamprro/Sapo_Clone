// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rating.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RatingResponse _$RatingResponseFromJson(Map<String, dynamic> json) =>
    RatingResponse(
      id: (json['id'] as num).toInt(),
      rating: (json['rating'] as num).toInt(),
      comment: json['comment'] as String,
      userId: (json['userId'] as num).toInt(),
      userFullName: json['userFullName'] as String,
      updatedAt: json['updatedAt'] as String?,
      productId: (json['productId'] as num).toInt(),
    );

Map<String, dynamic> _$RatingResponseToJson(RatingResponse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'rating': instance.rating,
      'comment': instance.comment,
      'userId': instance.userId,
      'userFullName': instance.userFullName,
      'updatedAt': instance.updatedAt,
      'productId': instance.productId,
    };

RatingCreateDTO _$RatingCreateDTOFromJson(Map<String, dynamic> json) =>
    RatingCreateDTO(
      productId: (json['productId'] as num).toInt(),
      rating: (json['rating'] as num).toInt(),
      comment: json['comment'] as String,
    );

Map<String, dynamic> _$RatingCreateDTOToJson(RatingCreateDTO instance) =>
    <String, dynamic>{
      'productId': instance.productId,
      'rating': instance.rating,
      'comment': instance.comment,
    };

RatingUpdateDTO _$RatingUpdateDTOFromJson(Map<String, dynamic> json) =>
    RatingUpdateDTO(
      rating: (json['rating'] as num?)?.toInt(),
      comment: json['comment'] as String?,
      status: (json['status'] as num?)?.toInt(),
    );

Map<String, dynamic> _$RatingUpdateDTOToJson(RatingUpdateDTO instance) =>
    <String, dynamic>{
      'rating': instance.rating,
      'comment': instance.comment,
      'status': instance.status,
    };
