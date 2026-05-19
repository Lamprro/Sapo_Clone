import 'package:json_annotation/json_annotation.dart';

part 'rating.g.dart';

@JsonSerializable()
class RatingResponse {
  final int id;
  final int rating;
  final String comment;
  final int userId;
  final String userFullName;
  final String? updatedAt;
  final int productId;

  RatingResponse({
    required this.id,
    required this.rating,
    required this.comment,
    required this.userId,
    required this.userFullName,
    this.updatedAt,
    required this.productId,
  });

  factory RatingResponse.fromJson(Map<String, dynamic> json) =>
      _$RatingResponseFromJson(json);

  Map<String, dynamic> toJson() => _$RatingResponseToJson(this);
}

@JsonSerializable()
class RatingCreateDTO {
  final int productId;
  final int rating;
  final String comment;

  RatingCreateDTO({
    required this.productId,
    required this.rating,
    required this.comment,
  });

  Map<String, dynamic> toJson() => _$RatingCreateDTOToJson(this);
}

@JsonSerializable()
class RatingUpdateDTO {
  final int? rating;
  final String? comment;
  final int? status;

  RatingUpdateDTO({
    this.rating,
    this.comment,
    this.status,
  });

  Map<String, dynamic> toJson() => _$RatingUpdateDTOToJson(this);
}
