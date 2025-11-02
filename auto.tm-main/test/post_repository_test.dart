import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:auto_tm/screens/post_screen/repository/post_repository.dart';
import 'package:auto_tm/screens/post_screen/repository/repository_exceptions.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class FakeClient extends http.BaseClient {
  final Map<Uri, http.Response> responses;
  FakeClient(this.responses);
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final response = responses[request.url];
    if (response == null) {
      return http.StreamedResponse(Stream.value([]), 404);
    }
    return http.StreamedResponse(
      Stream.value(response.bodyBytes),
      response.statusCode,
      headers: response.headers,
    );
  }
}

void main() {
  setUpAll(() async {
    // Initialize dotenv with test values
    dotenv.testLoad(mergeWith: {'API_BASE': 'https://your-api-base-url.com/'});
  });

  group('PostRepository.createPost', () {
    test('returns post UUID on successful creation (200)', () async {
      final client = FakeClient({
        Uri.parse('https://your-api-base-url.com/api/v1/posts'): http.Response(
          jsonEncode({'uuid': 'post-123', 'status': true}),
          200,
        ),
      });
      final repo = PostRepository(client: client);
      final postUuid = await repo.createPost({
        'price': 25000,
        'year': 2020,
        'brand': 'Toyota',
      });
      expect(postUuid, 'post-123');
    });

    test('returns post UUID on successful creation (201)', () async {
      final client = FakeClient({
        Uri.parse('https://your-api-base-url.com/api/v1/posts'): http.Response(
          jsonEncode({'uuid': 'post-456'}),
          201,
        ),
      });
      final repo = PostRepository(client: client);
      final postUuid = await repo.createPost({'price': 30000});
      expect(postUuid, 'post-456');
    });

    test('throws AuthExpiredException on 406', () async {
      final client = FakeClient({
        Uri.parse('https://your-api-base-url.com/api/v1/posts'): http.Response(
          'Unauthorized',
          406,
        ),
      });
      final repo = PostRepository(client: client);
      expect(
        repo.createPost({'price': 10000}),
        throwsA(isA<AuthExpiredException>()),
      );
    });

    test('throws HttpException on non-200/201/406 status', () async {
      final client = FakeClient({
        Uri.parse('https://your-api-base-url.com/api/v1/posts'): http.Response(
          'Bad Request',
          400,
        ),
      });
      final repo = PostRepository(client: client);
      expect(
        repo.createPost({'invalid': 'data'}),
        throwsA(isA<HttpException>()),
      );
    });
  });

  group('PostRepository.fetchMyPosts', () {
    test('returns parsed list of posts', () async {
      final postsJson = [
        {
          'uuid': 'p1',
          'price': 25000,
          'brand': {'name': 'Toyota'},
          'model': {'name': 'Camry'},
        },
        {
          'uuid': 'p2',
          'price': 30000,
          'brand': {'name': 'Honda'},
          'model': {'name': 'Accord'},
        },
      ];
      final client = FakeClient({
        Uri.parse('https://your-api-base-url.com/api/v1/posts/me'):
            http.Response(jsonEncode(postsJson), 200),
      });
      final repo = PostRepository(client: client);
      final posts = await repo.fetchMyPosts();
      expect(posts.length, 2);
      expect(posts[0]['uuid'], 'p1');
      expect(posts[1]['uuid'], 'p2');
    });

    test('handles response with data wrapper', () async {
      final responseJson = {
        'data': [
          {'uuid': 'p1', 'price': 15000},
        ],
      };
      final client = FakeClient({
        Uri.parse('https://your-api-base-url.com/api/v1/posts/me'):
            http.Response(jsonEncode(responseJson), 200),
      });
      final repo = PostRepository(client: client);
      final posts = await repo.fetchMyPosts();
      expect(posts.length, 1);
      expect(posts[0]['uuid'], 'p1');
    });

    test('returns empty list for non-list response', () async {
      final client = FakeClient({
        Uri.parse('https://your-api-base-url.com/api/v1/posts/me'):
            http.Response(jsonEncode({'message': 'no posts'}), 200),
      });
      final repo = PostRepository(client: client);
      final posts = await repo.fetchMyPosts();
      expect(posts, isEmpty);
    });

    test('throws AuthExpiredException on 406', () async {
      final client = FakeClient({
        Uri.parse('https://your-api-base-url.com/api/v1/posts/me'):
            http.Response('Unauthorized', 406),
      });
      final repo = PostRepository(client: client);
      expect(repo.fetchMyPosts(), throwsA(isA<AuthExpiredException>()));
    });

    test('throws HttpException on non-200/406 status', () async {
      final client = FakeClient({
        Uri.parse('https://your-api-base-url.com/api/v1/posts/me'):
            http.Response('Server Error', 500),
      });
      final repo = PostRepository(client: client);
      expect(repo.fetchMyPosts(), throwsA(isA<HttpException>()));
    });
  });
}
