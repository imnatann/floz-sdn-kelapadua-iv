sealed class ApiException implements Exception {
  final String message;
  final int? statusCode;
  const ApiException(this.message, {this.statusCode});
}

class NetworkException extends ApiException {
  const NetworkException(super.message);
}

class UnauthorizedException extends ApiException {
  const UnauthorizedException(super.message) : super(statusCode: 401);
}

class ForbiddenException extends ApiException {
  const ForbiddenException(super.message) : super(statusCode: 403);
}

class NotFoundException extends ApiException {
  const NotFoundException(super.message) : super(statusCode: 404);
}

class ValidationException extends ApiException {
  final Map<String, List<String>> errors;
  const ValidationException(super.message, this.errors)
      : super(statusCode: 422);
}

class RateLimitException extends ApiException {
  const RateLimitException(super.message) : super(statusCode: 429);
}

class ServerException extends ApiException {
  const ServerException(super.message, {super.statusCode});
}
