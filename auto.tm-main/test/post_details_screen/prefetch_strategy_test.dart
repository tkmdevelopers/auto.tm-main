import 'package:flutter_test/flutter_test.dart';
import 'package:auto_tm/screens/post_details_screen/domain/prefetch_strategy.dart';
import 'package:auto_tm/screens/post_details_screen/model/post_model.dart';

void main() {
  group('DefaultAdaptiveStrategy', () {
    late DefaultAdaptiveStrategy strategy;
    late List<Photo> photos;

    setUp(() {
      strategy = DefaultAdaptiveStrategy();
      // Create 20 mock photos
      photos = List.generate(
        20,
        (i) => Photo(
          uuid: 'photo-$i',
          originalPath: '/path/to/photo$i.jpg',
          paths: {
            'small': '/path/to/photo${i}_small.jpg',
            'medium': '/path/to/photo${i}_medium.jpg',
            'large': '/path/to/photo${i}_large.jpg',
          },
        ),
      );
    });

    group('Basic prefetch behavior', () {
      test('prefetches forward and backward with default radius', () {
        final ctx = PrefetchContext(
          networkSlow: false,
          consecutiveForwardSwipes: 0,
          isFastSwipe: false,
        );

        final targets = strategy.computeTargets(
          currentIndex: 5,
          lastPrefetchIndex: 4,
          photos: photos,
          ctx: ctx,
        );

        // Default: forward radius = 1, backward radius = 1
        expect(targets, containsAll([4, 6])); // backward 1, forward 1
        expect(targets.length, 2);
      });

      test('does not include negative indices', () {
        final ctx = PrefetchContext(
          networkSlow: false,
          consecutiveForwardSwipes: 0,
          isFastSwipe: false,
        );

        final targets = strategy.computeTargets(
          currentIndex: 0,
          lastPrefetchIndex: -1,
          photos: photos,
          ctx: ctx,
        );

        // Only forward, no negative indices
        expect(targets, contains(1));
        expect(targets.every((idx) => idx >= 0), isTrue);
      });

      test('does not exceed photo array bounds', () {
        final ctx = PrefetchContext(
          networkSlow: false,
          consecutiveForwardSwipes: 0,
          isFastSwipe: false,
        );

        final targets = strategy.computeTargets(
          currentIndex: 19,
          lastPrefetchIndex: 18,
          photos: photos,
          ctx: ctx,
        );

        // Only backward, no index >= 20
        expect(targets, contains(18));
        expect(targets.every((idx) => idx < photos.length), isTrue);
      });
    });

    group('Forward momentum detection', () {
      test('increases forward radius with strong momentum and fast swipe', () {
        final ctx = PrefetchContext(
          networkSlow: false,
          consecutiveForwardSwipes: 3,
          isFastSwipe: true,
        );

        final targets = strategy.computeTargets(
          currentIndex: 5,
          lastPrefetchIndex: 4,
          photos: photos,
          ctx: ctx,
        );

        // Strong momentum + fast = forward radius 3, backward radius 1
        expect(targets, containsAll([6, 7, 8])); // forward 3
        expect(targets, contains(4)); // backward 1
        expect(targets.length, 4);
      });

      test('increases forward radius with momentum only', () {
        final ctx = PrefetchContext(
          networkSlow: false,
          consecutiveForwardSwipes: 2,
          isFastSwipe: false,
        );

        final targets = strategy.computeTargets(
          currentIndex: 5,
          lastPrefetchIndex: 4,
          photos: photos,
          ctx: ctx,
        );

        // Momentum only = forward radius 2, backward radius 1
        expect(targets, containsAll([6, 7])); // forward 2
        expect(targets, contains(4)); // backward 1
        expect(targets.length, 3);
      });

      test('does not apply momentum for backward swipe', () {
        final ctx = PrefetchContext(
          networkSlow: false,
          consecutiveForwardSwipes: 0, // Reset by backward swipe
          isFastSwipe: false,
        );

        final targets = strategy.computeTargets(
          currentIndex: 5,
          lastPrefetchIndex: 6, // Moving backward
          photos: photos,
          ctx: ctx,
        );

        // Backward swipe resets momentum
        expect(targets.length, 2); // Default radius
      });
    });

    group('Fast swipe detection', () {
      test('increases radius symmetrically for fast swipe without momentum', () {
        final ctx = PrefetchContext(
          networkSlow: false,
          consecutiveForwardSwipes: 0,
          isFastSwipe: true,
        );

        final targets = strategy.computeTargets(
          currentIndex: 5,
          lastPrefetchIndex: 4,
          photos: photos,
          ctx: ctx,
        );

        // Fast swipe only = forward radius 2, backward radius 2
        expect(targets, containsAll([6, 7])); // forward 2
        expect(targets, containsAll([4, 3])); // backward 2
        expect(targets.length, 4);
      });
    });

    group('Network slow adaptation', () {
      test('reduces radius by half when network is slow', () {
        final ctx = PrefetchContext(
          networkSlow: true,
          consecutiveForwardSwipes: 0,
          isFastSwipe: true, // Would normally be radius 2
        );

        final targets = strategy.computeTargets(
          currentIndex: 5,
          lastPrefetchIndex: 4,
          photos: photos,
          ctx: ctx,
        );

        // Network slow halves radius: 2 -> 1
        expect(targets.length, 2); // Forward 1, backward 1
      });

      test('preserves momentum benefit when network is slow', () {
        final ctx = PrefetchContext(
          networkSlow: true,
          consecutiveForwardSwipes: 3,
          isFastSwipe: true, // Would normally be forward 3
        );

        final targets = strategy.computeTargets(
          currentIndex: 5,
          lastPrefetchIndex: 4,
          photos: photos,
          ctx: ctx,
        );

        // Network slow caps forward radius at 2 even with momentum
        expect(targets, containsAll([6, 7])); // forward 2 (capped from 3)
        expect(targets, contains(4)); // backward 1
        expect(targets.length, 3);
      });

      test('maintains minimum radius of 1 when network is slow', () {
        final ctx = PrefetchContext(
          networkSlow: true,
          consecutiveForwardSwipes: 0,
          isFastSwipe: false, // Minimal radius
        );

        final targets = strategy.computeTargets(
          currentIndex: 5,
          lastPrefetchIndex: 4,
          photos: photos,
          ctx: ctx,
        );

        // Even with network slow, minimum radius is 1
        expect(targets.length, greaterThanOrEqualTo(1));
      });
    });

    group('Edge cases', () {
      test('handles first photo correctly', () {
        final ctx = PrefetchContext(
          networkSlow: false,
          consecutiveForwardSwipes: 0,
          isFastSwipe: false,
        );

        final targets = strategy.computeTargets(
          currentIndex: 0,
          lastPrefetchIndex: -1,
          photos: photos,
          ctx: ctx,
        );

        expect(targets, contains(1));
        expect(targets.every((idx) => idx >= 0), isTrue);
      });

      test('handles last photo correctly', () {
        final ctx = PrefetchContext(
          networkSlow: false,
          consecutiveForwardSwipes: 0,
          isFastSwipe: false,
        );

        final targets = strategy.computeTargets(
          currentIndex: 19,
          lastPrefetchIndex: 18,
          photos: photos,
          ctx: ctx,
        );

        expect(targets, contains(18));
        expect(targets.every((idx) => idx < photos.length), isTrue);
      });

      test('handles single photo scenario', () {
        final singlePhoto = [photos[0]];
        final ctx = PrefetchContext(
          networkSlow: false,
          consecutiveForwardSwipes: 0,
          isFastSwipe: false,
        );

        final targets = strategy.computeTargets(
          currentIndex: 0,
          lastPrefetchIndex: -1,
          photos: singlePhoto,
          ctx: ctx,
        );

        // No targets available beyond current
        expect(targets.isEmpty, isTrue);
      });

      test('returns unique indices only', () {
        final ctx = PrefetchContext(
          networkSlow: false,
          consecutiveForwardSwipes: 3,
          isFastSwipe: true,
        );

        final targets = strategy.computeTargets(
          currentIndex: 5,
          lastPrefetchIndex: 4,
          photos: photos,
          ctx: ctx,
        );

        // Verify all indices are unique
        expect(targets.length, targets.toSet().length);
      });
    });

    group('Momentum accumulation scenarios', () {
      test('consecutive forward swipes increase radius progressively', () {
        // Simulate progressive swipes
        var lastIndex = 0;
        var consecutiveSwipes = 0;

        for (var currentIndex = 1; currentIndex <= 4; currentIndex++) {
          consecutiveSwipes++;
          final ctx = PrefetchContext(
            networkSlow: false,
            consecutiveForwardSwipes: consecutiveSwipes,
            isFastSwipe: false,
          );

          final targets = strategy.computeTargets(
            currentIndex: currentIndex,
            lastPrefetchIndex: lastIndex,
            photos: photos,
            ctx: ctx,
          );

          if (consecutiveSwipes >= 2) {
            // Should have forward momentum
            expect(targets.length, greaterThan(2));
          }

          lastIndex = currentIndex;
        }
      });
    });
  });

  group('PrefetchContext', () {
    test('creates context with all required fields', () {
      final ctx = PrefetchContext(
        networkSlow: true,
        consecutiveForwardSwipes: 5,
        isFastSwipe: true,
      );

      expect(ctx.networkSlow, isTrue);
      expect(ctx.consecutiveForwardSwipes, 5);
      expect(ctx.isFastSwipe, isTrue);
    });
  });
}
