import 'dart:convert';
import 'dart:io';

import '../models/giphy_gif_model.dart';

class GiphyService {
  static const String _apiKey = String.fromEnvironment(
    'QMATCH_GIPHY_API_KEY',
  );

  static const int pageSize = 24;

  bool get isConfigured => _apiKey.trim().isNotEmpty;

  Future<List<GiphyGifModel>> search({
    required String query,
    required String languageCode,
  }) async {
    final q = query.trim();

    if (q.isEmpty) {
      return trending();
    }

    if (q.length > 50) {
      throw StateError('GIF search query is too long.');
    }

    final language = languageCode.toLowerCase() == 'tr' ? 'tr' : 'en';

    return _request(
      path: '/v1/gifs/search',
      parameters: {
        'q': q,
        'limit': '$pageSize',
        'offset': '0',
        'rating': 'pg-13',
        'lang': language,
        'bundle': 'messaging_non_clips',
      },
    );
  }

  Future<List<GiphyGifModel>> trending() {
    return _request(
      path: '/v1/gifs/trending',
      parameters: {
        'limit': '$pageSize',
        'offset': '0',
        'rating': 'pg-13',
        'bundle': 'messaging_non_clips',
      },
    );
  }

  Future<List<GiphyGifModel>> _request({
    required String path,
    required Map<String, String> parameters,
  }) async {
    if (!isConfigured) {
      throw StateError(
        'QMATCH_GIPHY_API_KEY is not configured.',
      );
    }

    final uri = Uri.https(
      'api.giphy.com',
      path,
      {
        'api_key': _apiKey,
        ...parameters,
      },
    );

    final client = HttpClient();

    try {
      final request = await client.getUrl(uri).timeout(
            const Duration(seconds: 10),
          );

      request.headers.set(
        HttpHeaders.acceptHeader,
        'application/json',
      );

      final response = await request.close().timeout(
            const Duration(seconds: 10),
          );

      final body = await utf8.decoder.bind(response).join();

      if (response.statusCode != HttpStatus.ok) {
        throw HttpException(
          'GIPHY request failed (${response.statusCode}).',
          uri: uri,
        );
      }

      final decoded = jsonDecode(body);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException(
          'Invalid GIPHY response.',
        );
      }

      final rawData = decoded['data'];
      if (rawData is! List) {
        return const <GiphyGifModel>[];
      }

      final results = <GiphyGifModel>[];

      for (final row in rawData) {
        if (row is! Map) continue;

        try {
          final gif = GiphyGifModel.fromApi(
            row.cast<String, dynamic>(),
          );

          if (gif.id.isNotEmpty) {
            results.add(gif);
          }
        } on FormatException {
          continue;
        }
      }

      return results;
    } finally {
      client.close(force: true);
    }
  }

  Future<void> registerAnalytics(String? url) async {
    final value = url?.trim();
    if (value == null || value.isEmpty) return;

    final uri = Uri.tryParse(value);
    if (uri == null || uri.scheme != 'https') return;

    final client = HttpClient();

    try {
      final request = await client.getUrl(uri).timeout(
            const Duration(seconds: 5),
          );
      await request.close().timeout(
            const Duration(seconds: 5),
          );
    } catch (_) {
      // Analytics must never block chat UX.
    } finally {
      client.close(force: true);
    }
  }
}
