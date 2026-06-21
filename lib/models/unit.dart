class UnitResponse {
  final int id;
  final String unitName;

  UnitResponse({required this.id, required this.unitName});

  factory UnitResponse.fromJson(Map<String, dynamic> json) {
    return UnitResponse(
      id: (json['id'] as num?)?.toInt() ?? 0,
      unitName: json['unitName'] as String? ?? 'Unknown',
    );
  }
}
