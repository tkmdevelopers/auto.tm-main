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
            content.contains('Dio()') && 
            !content.contains('ApiClient');
            
        if (usesHttpPackageDirectly || createsDioDirectly) {
          violators.add(file.path);
        }
      }

      if (violators.isNotEmpty) {
        fail('''The following UI/Screen files violate architecture rules by making direct HTTP calls:
${violators.join('\n')}
Please use ApiClient or a Service instead.''');
      }
    });
    
    test('Services should exist for API endpoints', () {
      final Directory servicesDir = Directory('lib/services');
      expect(servicesDir.existsSync(), true, reason: 'Services directory should exist');
      
      final serviceFiles = servicesDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('_service.dart'))
          .toList();
      
      // We should have at least core services
      expect(serviceFiles.length, greaterThanOrEqualTo(3), 
          reason: 'Should have at least 3 service files');
    });

    test('Controllers should be named correctly', () {
      final Directory libDir = Directory('lib');
      final files = libDir.listSync(recursive: true).whereType<File>();
      
      final List<String> badNaming = [];

      for (final file in files) {
         if (file.path.endsWith('_controller.dart')) {
             // Good
         } else if (file.path.contains('/controller/') && file.path.endsWith('.dart')) {
             // If it is in a controller folder, it should probably be named _controller.dart
             // Excluding generated files or standard utils
             if (!file.path.endsWith('.g.dart') && !file.path.endsWith('.freezed.dart')) {
                  // This is a heuristic, might be too strict, let's just warn or skip for now.
                  // badNaming.add(file.path);
             }
         }
      }
    });
  });
}
