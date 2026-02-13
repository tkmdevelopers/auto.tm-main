/// Simple failure wrapper for error handling
class Failure {
  final String? message;
  Failure(this.message);
  @override
  String toString() => message ?? 'Unknown error';
}
