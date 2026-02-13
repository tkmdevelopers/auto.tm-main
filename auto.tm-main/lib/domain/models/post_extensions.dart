import 'package:intl/intl.dart';
import 'package:auto_tm/domain/models/post.dart';

extension PostUiExtensions on Post {
  /// Returns the price formatted with thousands separator, e.g. "150,000"
  String get formattedPrice {
    final formatter = NumberFormat("#,###", "en_US");
    return formatter.format(price);
  }

  /// Returns the full formatted price with currency, e.g. "150,000 TMT"
  String get priceWithCurrency => '$formattedPrice $currency';

  /// Returns the milleage formatted with thousands separator, e.g. "45,000 km"
  String get formattedMilleage {
    final formatter = NumberFormat("#,###", "en_US");
    return '${formatter.format(milleage)} km';
  }

  /// Returns the creation date in a human-readable format, e.g. "10.02.2026"
  String get formattedDate {
    try {
      final dateTime = DateTime.parse(createdAt);
      return DateFormat('dd.MM.yyyy').format(dateTime);
    } catch (_) {
      return createdAt;
    }
  }

  /// Returns the year as an integer string, e.g. "2024"
  String get yearString => year.toInt().toString();
}
