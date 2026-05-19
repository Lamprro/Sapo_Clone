/// Represents the logged-in user information returned by the backend.
/// Maps to backend `UserResponse` DTO exactly.
///
/// Backend fields: id, fullName, email, username, phone, address,
/// status, createdAt, updatedAt, roleName, companyId, storeId, pointValue.
class UserResponse {
  final int id;
  final String fullName;
  final String? email;
  final String? username;
  final String? phone;
  final String? address;
  final int status;
  final String? createdAt;
  final String? updatedAt;
  final String? roleName;
  final int? companyId;
  final int? storeId;
  final int? pointValue;

  UserResponse({
    required this.id,
    required this.fullName,
    this.email,
    this.username,
    this.phone,
    this.address,
    required this.status,
    this.createdAt,
    this.updatedAt,
    this.roleName,
    this.companyId,
    this.storeId,
    this.pointValue,
  });

  /// Parse from JSON map returned by backend.
  factory UserResponse.fromJson(Map<String, dynamic> json) {
    return UserResponse(
      id: json['id'] as int,
      fullName: json['fullName'] as String,
      email: json['email'] as String?,
      username: json['username'] as String?,
      phone: json['phone'] as String?,
      address: json['address'] as String?,
      status: json['status'] as int,
      createdAt: json['createdAt'] as String?,
      updatedAt: json['updatedAt'] as String?,
      roleName: json['roleName'] as String?,
      companyId: json['companyId'] as int?,
      storeId: json['storeId'] as int?,
      pointValue: json['pointValue'] as int?,
    );
  }

  /// Convert to JSON map (useful for profile update requests).
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
      'username': username,
      'phone': phone,
      'address': address,
      'status': status,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'roleName': roleName,
      'companyId': companyId,
      'storeId': storeId,
      'pointValue': pointValue,
    };
  }
}

/// Login response contains JWT token and the user object.
/// Maps to backend `LoginResponse` DTO: { token, user }.
class LoginResponse {
  final String token;
  final UserResponse user;

  LoginResponse({
    required this.token,
    required this.user,
  });

  /// Parse from JSON map returned by backend inside ApiResponse.data.
  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      token: json['token'] as String,
      user: UserResponse.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}
