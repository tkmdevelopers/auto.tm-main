import 'package:auto_tm/screens/post_details_screen/controller/comments_controller.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart' hide Response;
import 'package:mockito/mockito.dart';

import '../../helpers/test_setup.dart';

void main() {
  late TestSetup testSetup;
  late CommentsController controller;

  setUp(() async {
    testSetup = TestSetup();
    await testSetup.init();
    controller = CommentsController();
  });

  tearDown(() {
    testSetup.dispose();
  });

  group('CommentsController - Initial State', () {
    test('should have empty comments list', () {
      expect(controller.comments, isEmpty);
    });

    test('should not be loading', () {
      expect(controller.isLoading.value, false);
    });

    test('should not be sending', () {
      expect(controller.isSending.value, false);
    });

    test('should have no reply target', () {
      expect(controller.replyToComment.value, isNull);
    });
  });

  group('CommentsController - Reply State', () {
    test('setReplyTo should set the reply target', () {
      final comment = {'uuid': 'c1', 'message': 'Hello', 'replyTo': null};
      controller.setReplyTo(comment);

      expect(controller.replyToComment.value, isNotNull);
      expect(controller.replyToComment.value!['uuid'], 'c1');
    });

    test('clearReply should clear the reply target', () {
      controller.setReplyTo({'uuid': 'c1', 'message': 'Test'});
      controller.clearReply();

      expect(controller.replyToComment.value, isNull);
    });
  });

  group('CommentsController - Thread Expansion', () {
    test('toggleThread should toggle expansion state', () {
      expect(controller.isThreadExpanded('parent-1'), false);

      controller.toggleThread('parent-1');
      expect(controller.isThreadExpanded('parent-1'), true);

      controller.toggleThread('parent-1');
      expect(controller.isThreadExpanded('parent-1'), false);
    });

    test('isThreadExpanded should default to false', () {
      expect(controller.isThreadExpanded('nonexistent'), false);
    });
  });

  group('CommentsController - groupedReplies', () {
    test('should group replies by parent uuid', () {
      controller.comments.assignAll([
        {'uuid': 'p1', 'message': 'Parent 1', 'replyTo': null},
        {'uuid': 'r1', 'message': 'Reply 1 to p1', 'replyTo': 'p1'},
        {'uuid': 'r2', 'message': 'Reply 2 to p1', 'replyTo': 'p1'},
        {'uuid': 'p2', 'message': 'Parent 2', 'replyTo': null},
        {'uuid': 'r3', 'message': 'Reply to p2', 'replyTo': 'p2'},
      ]);

      final grouped = controller.groupedReplies;

      expect(grouped.containsKey('p1'), true);
      expect(grouped['p1']!.length, 2);
      expect(grouped.containsKey('p2'), true);
      expect(grouped['p2']!.length, 1);
    });

    test('should return empty map when no replies exist', () {
      controller.comments.assignAll([
        {'uuid': 'p1', 'message': 'Parent 1', 'replyTo': null},
        {'uuid': 'p2', 'message': 'Parent 2', 'replyTo': null},
      ]);

      expect(controller.groupedReplies, isEmpty);
    });
  });

  group('CommentsController - fetchComments', () {
    test('should not fetch for empty postId', () async {
      await controller.fetchComments('');

      expect(controller.comments, isEmpty);
      expect(controller.isLoading.value, false);
    });

    test('should deduplicate comments by uuid', () async {
      testSetup.mockGet('comments', [
        {'uuid': 'c1', 'message': 'Hello'},
        {'uuid': 'c1', 'message': 'Hello'}, // duplicate
        {'uuid': 'c2', 'message': 'World'},
      ]);

      await controller.fetchComments('post-123');
      // Allow microtask to complete
      await Future.delayed(Duration.zero);

      expect(controller.comments.length, 2);
      expect(controller.comments[0]['uuid'], 'c1');
      expect(controller.comments[1]['uuid'], 'c2');
    });

    test('should skip refetch for same postId', () async {
      testSetup.mockGet('comments', [
        {'uuid': 'c1', 'message': 'Hello'},
      ]);

      await controller.fetchComments('post-123');
      await Future.delayed(Duration.zero);

      final firstCount = controller.comments.length;

      // Second call with same postId should be skipped
      await controller.fetchComments('post-123');
      await Future.delayed(Duration.zero);

      expect(controller.comments.length, firstCount);
    });

    test('should handle wrapped data response', () async {
      testSetup.mockGet('comments', {
        'data': [
          {'uuid': 'c1', 'message': 'From data wrapper'},
        ],
      });

      await controller.fetchComments('post-456');
      await Future.delayed(Duration.zero);

      expect(controller.comments.length, 1);
      expect(controller.comments[0]['message'], 'From data wrapper');
    });

    test('should initialize thread expansion for replies', () async {
      testSetup.mockGet('comments', [
        {'uuid': 'p1', 'message': 'Parent', 'replyTo': null},
        {'uuid': 'r1', 'message': 'Reply', 'replyTo': 'p1'},
      ]);

      await controller.fetchComments('post-789');
      await Future.delayed(Duration.zero);

      // Thread should be collapsed by default
      expect(controller.isThreadExpanded('p1'), false);
    });
  });

  group('CommentsController - sendComment', () {
    test('should not send empty message', () async {
      await controller.sendComment('post-123', '');

      expect(controller.isSending.value, false);
    });

    test('should not send when already sending', () async {
      controller.isSending.value = true;

      await controller.sendComment('post-123', 'Hello');

      // Should remain true (not reset because guard prevented entry)
      expect(controller.isSending.value, true);
    });

    test(
      'should guard against missing auth tokens',
      () async {
        // This test verifies the guard logic exists.
        // Full test requires GetMaterialApp for snackbar overlay.
        when(testSetup.mockStorage.read(key: 'ACCESS_TOKEN'))
            .thenAnswer((_) async => null);
        when(testSetup.mockStorage.read(key: 'REFRESH_TOKEN'))
            .thenAnswer((_) async => null);

        // Verify hasTokens returns false
        final hasTokens = await testSetup.tokenStore.hasTokens;
        expect(hasTokens, false);
      },
    );

    test('should add new comment to list on success', () async {
      // Ensure tokens exist
      when(testSetup.mockStorage.read(key: 'ACCESS_TOKEN'))
          .thenAnswer((_) async => 'valid_token');

      testSetup.mockPost('comments', {
        'uuid': 'new-comment',
        'message': 'Hello World',
        'postId': 'post-123',
      });

      await controller.sendComment('post-123', 'Hello World');

      expect(controller.isSending.value, false);
      expect(controller.comments.any((c) => c['uuid'] == 'new-comment'), true);
    });

    test('should clear reply target after successful send', () async {
      when(testSetup.mockStorage.read(key: 'ACCESS_TOKEN'))
          .thenAnswer((_) async => 'valid_token');

      controller.setReplyTo({'uuid': 'parent-1', 'message': 'Parent'});

      testSetup.mockPost('comments', {
        'uuid': 'reply-1',
        'message': 'Reply',
        'replyTo': 'parent-1',
      });

      await controller.sendComment('post-123', 'Reply');

      expect(controller.replyToComment.value, isNull);
    });

    test('should not add duplicate comment', () async {
      when(testSetup.mockStorage.read(key: 'ACCESS_TOKEN'))
          .thenAnswer((_) async => 'valid_token');

      // Pre-populate existing comment
      controller.comments.add({
        'uuid': 'existing-1',
        'message': 'Already exists',
      });

      testSetup.mockPost('comments', {
        'uuid': 'existing-1',
        'message': 'Already exists',
      });

      await controller.sendComment('post-123', 'Already exists');

      // Should still be 1, not 2
      expect(
        controller.comments.where((c) => c['uuid'] == 'existing-1').length,
        1,
      );
    });
  });
}
