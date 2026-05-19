/// Generic wrapper matching backend `ApiResponse<T>`.
///
/// Every backend response follows this structure:
/// ```json
/// { "status": "success"|"error", "message": "...", "data": <T> }
/// ```
class ApiResponse<T> {
  final String status;
  final String message;
  final T? data;

  ApiResponse({
    required this.status,
    required this.message,
    this.data,
  });

  /// Whether the request was successful.
  bool get isSuccess => status == 'success';

  /// Parse from JSON map. [fromJsonT] converts the raw `data` field
  /// into the target type [T].
  ///
  /// Example usage:
  /// ```dart
  /// final apiResp = ApiResponse.fromJson(
  ///   response.data,
  ///   (json) => UserResponse.fromJson(json as Map<String, dynamic>),
  /// );
  /// ```
  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic json)? fromJsonT,
  ) {
    return ApiResponse<T>(
      status: json['status'] as String,
      message: json['message'] as String,
      data: json['data'] != null && fromJsonT != null
          ? fromJsonT(json['data'])
          : json['data'] as T?,
    );
  }
}
