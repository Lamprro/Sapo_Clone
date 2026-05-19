/// Generic wrapper for success/failure results used by repositories.
class Result<T> {
  final bool isSuccess;
  final T? data;
  final String? message;
  final Failure? failure;

  Result.success(this.data, {this.message}) : isSuccess = true, failure = null;
  Result.failure(this.failure, {this.message}) : isSuccess = false, data = null;
}

/// Simple failure representation.
class Failure {
  final String code;
  final String description;

  Failure({required this.code, required this.description});
}
