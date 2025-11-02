/// Common repository exceptions
class AuthExpiredException implements Exception {
  @override
  String toString() => 'AuthExpiredException: Session expired (406)';
}

class HttpException implements Exception {
  final String message;
  HttpException(this.message);
  @override
  String toString() => 'HttpException($message)';
}
