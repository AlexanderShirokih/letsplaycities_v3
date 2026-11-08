/// Error that the server answered a REST request with, parsed from the body
/// `{"error": {"code": "...", "message": "..."}}`.
class ApiException implements Exception {
  /// HTTP status of the answer.
  final int status;

  /// Machine-readable error code, e.g. `unauthorized` or `bad_name`.
  /// `internal` when the answer has no readable error body.
  final String code;

  /// Human-readable text the server provided, if any.
  final String? message;

  const ApiException(this.status, this.code, [this.message]);

  @override
  String toString() => 'ApiException($status, $code, $message)';
}

/// The account is banned (`banned` error code).
class BannedException extends ApiException {
  const BannedException(super.status, super.code, [super.message]);
}

/// The token is missing, expired or revoked (HTTP 401).
class UnauthorizedException extends ApiException {
  const UnauthorizedException(super.status, super.code, [super.message]);
}
