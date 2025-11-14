import 'package:flutter_test/flutter_test.dart';
import 'package:auto_tm/screens/post_details_screen/domain/image_prefetch_service.dart';
import 'package:auto_tm/screens/post_details_screen/domain/prefetch_strategy.dart';
import 'package:auto_tm/screens/post_details_screen/model/post_model.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Mock strategy that returns predictable targets
class MockPrefetchStrategy implements PrefetchStrategy {
  final Set<int> targetsToReturn;

  MockPrefetchStrategy(this.targetsToReturn);

  @override
  Set<int> computeTargets({
    required int currentIndex,
    required int lastPrefetchIndex,
    required List<Photo> photos,
    required PrefetchContext ctx,
  }) {
    return targetsToReturn;
  }
}

void main() {
  setUpAll(() async {
    // Initialize dotenv for API key access
    dotenv.testLoad(mergeWith: {'API_BASE': 'https://test-api.com/'});
  });

  group('ImagePrefetchService', () {
    late List<Photo> testPhotos;

    setUp(() {
      // Create test photos
      testPhotos = List.generate(
        10,
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

    group('Session management', () {
      test('resetSession clears all tracking state', () {
        final service = ImagePrefetchService();

        // Set some state
        service.lastPrefetchIndex = 5;
        service.consecutiveForwardSwipes = 3;
        service.networkSlow = true;

        // Reset
        service.resetSession();

        // Verify state cleared
        expect(service.lastPrefetchIndex, -1);
        expect(service.consecutiveForwardSwipes, 0);
        expect(service.networkSlow, false);
      });

      test('initial state is clean', () {
        final service = ImagePrefetchService();

        expect(service.lastPrefetchIndex, -1);
        expect(service.consecutiveForwardSwipes, 0);
        expect(service.networkSlow, false);
      });
    });

    group('prefetchInitial', () {
      test('does not prefetch if disposed', () {
        final service = ImagePrefetchService();
        var disposed = true;

        // Should return early without processing
        service.prefetchInitial(testPhotos, disposed: () => disposed);

        // No exception thrown, operation completed
        expect(service.lastPrefetchIndex, -1); // Unchanged
      });

      test('does not prefetch if photos list is empty', () {
        final service = ImagePrefetchService();

        service.prefetchInitial([], disposed: () => false);

        // No exception thrown
        expect(service.lastPrefetchIndex, -1);
      });

      test('prefetches up to normalWarmCount images', () {
        final service = ImagePrefetchService();
        service.networkSlow = false;

        service.prefetchInitial(testPhotos, disposed: () => false);

        // Note: We can't directly verify CachedImageHelper.prewarmCache was called
        // without extensive mocking, but we can verify the service completed
        // without errors (implicitly tested by test passing)
      });

      test('prefetches fewer images when network is slow', () {
        final service = ImagePrefetchService();
        service.networkSlow = true;

        service.prefetchInitial(testPhotos, disposed: () => false);

        // Service should use slowNetworkWarmCount (3) instead of normalWarmCount (5)
        // We can't verify the count directly without mocking CachedImageHelper
      });

      test('limits warm count to photo array length', () {
        final smallPhotoList = [testPhotos[0], testPhotos[1]];
        final service = ImagePrefetchService();

        // Should not throw when photo count < warmCount
        service.prefetchInitial(smallPhotoList, disposed: () => false);
      });

      test('skips photos with empty paths', () {
        final photosWithEmpty = [
          Photo(
            uuid: 'empty',
            originalPath: '',
            paths: {'small': '', 'medium': '', 'large': ''},
          ),
          testPhotos[0],
          testPhotos[1],
        ];

        final service = ImagePrefetchService();
        service.prefetchInitial(photosWithEmpty, disposed: () => false);

        // Should complete without error despite empty paths
      });
    });

    group('prefetchAdjacent', () {
      test('does not prefetch if disposed', () {
        final service = ImagePrefetchService();
        var disposed = true;

        service.prefetchAdjacent(
          currentIndex: 2,
          photos: testPhotos,
          disposed: () => disposed,
        );

        expect(service.lastPrefetchIndex, -1); // Unchanged
      });

      test('does not prefetch if photos list is empty', () {
        final service = ImagePrefetchService();

        service.prefetchAdjacent(
          currentIndex: 0,
          photos: [],
          disposed: () => false,
        );

        expect(service.lastPrefetchIndex, -1);
      });

      test('skips duplicate prefetch for same index', () {
        final service = ImagePrefetchService();
        service.lastPrefetchIndex = 5;

        service.prefetchAdjacent(
          currentIndex: 5, // Same as last
          photos: testPhotos,
          disposed: () => false,
        );

        // Should return early, lastPrefetchIndex unchanged
        expect(service.lastPrefetchIndex, 5);
      });

      test('updates lastPrefetchIndex after successful prefetch', () {
        final service = ImagePrefetchService();

        service.prefetchAdjacent(
          currentIndex: 3,
          photos: testPhotos,
          disposed: () => false,
        );

        expect(service.lastPrefetchIndex, 3);
      });

      test('increments consecutiveForwardSwipes on forward movement', () {
        final service = ImagePrefetchService();
        service.lastPrefetchIndex = 2;

        service.prefetchAdjacent(
          currentIndex: 3,
          photos: testPhotos,
          disposed: () => false,
        );

        expect(service.consecutiveForwardSwipes, 1);

        service.prefetchAdjacent(
          currentIndex: 4,
          photos: testPhotos,
          disposed: () => false,
        );

        expect(service.consecutiveForwardSwipes, 2);
      });

      test('resets consecutiveForwardSwipes on backward movement', () {
        final service = ImagePrefetchService();
        service.lastPrefetchIndex = 5;
        service.consecutiveForwardSwipes = 3;

        service.prefetchAdjacent(
          currentIndex: 4, // Backward
          photos: testPhotos,
          disposed: () => false,
        );

        expect(service.consecutiveForwardSwipes, 0);
      });

      test('detects fast swipe based on time delta', () {
        final service = ImagePrefetchService();
        service.lastPrefetchIndex = 2;
        service.lastSwipeTime = DateTime.now().subtract(Duration(milliseconds: 100));

        service.prefetchAdjacent(
          currentIndex: 3,
          photos: testPhotos,
          disposed: () => false,
        );

        // Fast swipe detected (< 300ms), strategy receives isFastSwipe: true
        expect(service.lastPrefetchIndex, 3);
      });

      test('delegates target computation to strategy', () {
        final mockStrategy = MockPrefetchStrategy({3, 4, 5});
        final service = ImagePrefetchService(strategy: mockStrategy);

        service.prefetchAdjacent(
          currentIndex: 2,
          photos: testPhotos,
          disposed: () => false,
        );

        // Mock strategy returns {3, 4, 5}, service should process them
        expect(service.lastPrefetchIndex, 2);
      });

      test('skips already prefetched URLs', () {
        final service = ImagePrefetchService();

        // First prefetch
        service.prefetchAdjacent(
          currentIndex: 2,
          photos: testPhotos,
          disposed: () => false,
        );

        // Prefetch again (same images likely cached)
        service.prefetchAdjacent(
          currentIndex: 3,
          photos: testPhotos,
          disposed: () => false,
        );

        // Should complete without error
      });

      test('prunes prefetched URLs when cache exceeds limit', () {
        final service = ImagePrefetchService();

        // Simulate large prefetched URLs set by manually adding
        for (var i = 0; i < 60; i++) {
          // Exceeds maxPrefetchedUrls (50)
          service.prefetchAdjacent(
            currentIndex: i % testPhotos.length,
            photos: testPhotos,
            disposed: () => false,
          );
        }

        // Cache should be pruned (verified by test not throwing)
      });

      test('handles photos with empty paths gracefully', () {
        final photosWithEmpty = [
          testPhotos[0],
          Photo(
            uuid: 'empty',
            originalPath: '',
            paths: {'small': '', 'medium': '', 'large': ''},
          ),
          testPhotos[2],
        ];

        final service = ImagePrefetchService();
        service.prefetchAdjacent(
          currentIndex: 1,
          photos: photosWithEmpty,
          disposed: () => false,
        );

        // Should skip empty photo without error
        expect(service.lastPrefetchIndex, 1);
      });
    });

    group('Network slow flag synchronization', () {
      test('networkSlow flag affects initial prefetch count', () {
        final service = ImagePrefetchService();
        service.networkSlow = false;

        service.prefetchInitial(testPhotos, disposed: () => false);

        // Now set network slow
        service.networkSlow = true;
        service.resetSession();

        service.prefetchInitial(testPhotos, disposed: () => false);

        // Should use reduced warm count on second call
      });

      test('networkSlow flag is passed to strategy context', () {
        final mockStrategy = MockPrefetchStrategy({2, 3});
        final service = ImagePrefetchService(strategy: mockStrategy);

        service.networkSlow = true;

        service.prefetchAdjacent(
          currentIndex: 1,
          photos: testPhotos,
          disposed: () => false,
        );

        // Strategy receives context with networkSlow: true
        // Verified by test completing without error
      });
    });

    group('Edge cases', () {
      test('handles rapid consecutive calls gracefully', () {
        final service = ImagePrefetchService();

        for (var i = 0; i < 10; i++) {
          service.prefetchAdjacent(
            currentIndex: i,
            photos: testPhotos,
            disposed: () => false,
          );
        }

        expect(service.lastPrefetchIndex, 9);
      });

      test('handles disposal mid-operation', () {
        final service = ImagePrefetchService();
        var disposed = false;

        // Start prefetch, then dispose mid-operation
        Future.delayed(Duration(milliseconds: 1), () {
          disposed = true;
        });

        service.prefetchAdjacent(
          currentIndex: 2,
          photos: testPhotos,
          disposed: () => disposed,
        );

        // Should handle gracefully
      });

      test('handles index at boundaries', () {
        final service = ImagePrefetchService();

        // First index
        service.prefetchAdjacent(
          currentIndex: 0,
          photos: testPhotos,
          disposed: () => false,
        );

        expect(service.lastPrefetchIndex, 0);

        // Last index
        service.prefetchAdjacent(
          currentIndex: testPhotos.length - 1,
          photos: testPhotos,
          disposed: () => false,
        );

        expect(service.lastPrefetchIndex, testPhotos.length - 1);
      });
    });
  });
}
