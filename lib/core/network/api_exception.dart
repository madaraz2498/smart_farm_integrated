/// Typed exception for every non-2xx HTTP response.
class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int?   statusCode;

  bool get isNetworkError  => statusCode == 0;
  bool get isUnauthorized  => statusCode == 401;
  bool get isForbidden     => statusCode == 403;
  bool get isNotFound      => statusCode == 404;
  bool get isConflict      => statusCode == 409;
  bool get isValidation    => statusCode == 422;
  bool get isServerError   => (statusCode ?? 0) >= 500;

  @override
  String toString() => 'ApiException($statusCode): $message';
}
