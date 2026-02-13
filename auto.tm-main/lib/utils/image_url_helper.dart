/// Builds full image URL from base and path; avoids double or missing slashes.
String fullImageUrl(String base, String path) {
  if (path.isEmpty) return '';
  if (path.startsWith('http://') || path.startsWith('https://')) return path;
  final b = base.endsWith('/') ? base : '$base/';
  final p = path.startsWith('/') ? path.substring(1) : path;
  return b + p;
}
