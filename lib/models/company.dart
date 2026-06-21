/// Company model matching backend `CompanyResponse` DTO.
class CompanyResponse {
  final int id;
  final String companyName;
  final String? companyAddress;
  final String? createdAt;

  CompanyResponse({
    required this.id,
    required this.companyName,
    this.companyAddress,
    this.createdAt,
  });

  /// Parse from JSON map returned by backend.
  factory CompanyResponse.fromJson(Map<String, dynamic> json) {
    String name = 'Unknown Company';
    for (var key in ['companyName', 'company_name', 'name', 'displayName']) {
      if (json[key] != null && json[key].toString().isNotEmpty) {
        name = json[key].toString();
        break;
      }
    }

    String? address;
    for (var key in ['companyAddress', 'company_address', 'address', 'location']) {
      if (json[key] != null && json[key].toString().isNotEmpty) {
        address = json[key].toString();
        break;
      }
    }

    return CompanyResponse(
      id: (json['id'] as num?)?.toInt() ?? 0,
      companyName: name,
      companyAddress: address,
      createdAt: json['createdAt'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'companyName': companyName,
      'companyAddress': companyAddress,
      'createdAt': createdAt,
    };
  }

  @override
  String toString() => companyName;
}
