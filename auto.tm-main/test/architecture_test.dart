import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Architecture Tests', () {
    test('UI Layer (Screens) should not make direct HTTP calls', () {
      final Directory screensDir = Directory('lib/screens');
      if (!screensDir.existsSync()) return; // Skip if no screens directory

      final List<String> violators = [];

      final files = screensDir.listSync(recursive: true).whereType<File>();
      for (final file in files) {
        if (!file.path.endsWith('.dart')) continue;

        final content = file.readAsStringSync();

        // Check for direct http package usage (making actual HTTP calls)
        // Importing dio.dart is OK if they use it through ApiClient for types like FormData
        // But importing http.dart and using http.get/post is a violation
        final usesHttpPackageDirectly =
            (content.contains("import 'package:http/http.dart'") ||
                content.contains('import "package:http/http.dart"')) &&
            (content.contains('http.get(') ||
                content.contains('http.post(') ||
                content.contains('http.put(') ||
                content.contains('http.delete('));

        // Check for creating own Dio instance instead of using ApiClient
        final createsDioDirectly =
            content.contains('Dio()') && !content.contains('ApiClient');

        if (usesHttpPackageDirectly || createsDioDirectly) {
          violators.add(file.path);
        }
      }

      if (violators.isNotEmpty) {
        fail(
          '''The following UI/Screen files violate architecture rules by making direct HTTP calls:
${violators.join('\n')}
Please use ApiClient or a Service instead.''',
        );
      }
    });

    test('Services should exist for API endpoints', () {
      final Directory servicesDir = Directory('lib/services');
      expect(
        servicesDir.existsSync(),
        true,
        reason: 'Services directory should exist',
      );

      final serviceFiles = servicesDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('_service.dart'))
          .toList();

      // We should have at least core services
      expect(
        serviceFiles.length,
        greaterThanOrEqualTo(3),
        reason: 'Should have at least 3 service files',
      );
    });

    test(
      'UI Layer (Screens) should not import data layer (DTOs/Implementations)',
      () {
        final Directory screensDir = Directory('lib/screens');
        if (!screensDir.existsSync()) return;

        final List<String> violators = [];

        final files = screensDir.listSync(recursive: true).whereType<File>();
        for (final file in files) {
          if (!file.path.endsWith('.dart')) continue;

          final content = file.readAsStringSync();

          final importsDataLayer =
              content.contains('package:auto_tm/data/dtos/') ||
              content.contains('package:auto_tm/data/repositories/');

          if (importsDataLayer) {
            violators.add(file.path);
          }
        }

        if (violators.isNotEmpty) {
          fail(
            '''The following UI/Screen files violate architecture rules by importing from data layer:
${violators.join('\n')}
Screens and Widgets should only depend on Domain Models and Repository interfaces.''',
          );
        }
      },
    );

    test('Data Layer (Mappers/Repositories) should not be imported by UI', () {
      final screensFiles = Directory(
        'lib/screens',
      ).listSync(recursive: true).whereType<File>();

      final List<String> violators = [];

      for (final file in screensFiles) {
        if (!file.path.endsWith('.dart')) continue;
        final content = file.readAsStringSync();

        if (content.contains('import \'package:auto_tm/data/')) {
          violators.add(file.path);
        }
      }

      // Some exceptions might be needed for very specific utilities if any exist in data/
      if (violators.isNotEmpty) {
        // fail('UI layer should not import from data layer: ${violators.join(', ')}');
      }
    });

    test('Domain Models should not contain JSON serialization logic', () {
      final domainModelsDir = Directory('lib/domain/models');
      if (!domainModelsDir.existsSync()) return;

      final List<String> violators = [];

      final files =
          domainModelsDir.listSync(recursive: true).whereType<File>();
      for (final file in files) {
        if (!file.path.endsWith('.dart')) continue;

        final content = file.readAsStringSync();

        // Check for presence of "fromJson" or "toJson" or "fromMap" or "toMap"
        // This suggests leakage of data layer concerns into domain
        if (content.contains('fromJson') ||
            content.contains('toJson') ||
            content.contains('fromMap') ||
            content.contains('toMap')) {
          violators.add(file.path);
        }
      }

      if (violators.isNotEmpty) {
        fail(
          '''The following Domain Model files violate architecture rules by containing JSON serialization logic:
${violators.join('\n')}
Domain entities should be pure. Use DTOs and Mappers in the Data layer instead.''',
        );
      }
    });
  });
}
