class GiphyGifModel {
  const GiphyGifModel({
    required this.id,
    required this.previewUrl,
    required this.sendUrl,
    this.title,
    this.analyticsViewUrl,
    this.analyticsClickUrl,
    this.analyticsSendUrl,
  });

  final String id;
  final String previewUrl;
  final String sendUrl;
  final String? title;

  final String? analyticsViewUrl;
  final String? analyticsClickUrl;
  final String? analyticsSendUrl;

  static String? _string(dynamic value) {
    if (value is! String) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static bool _isGiphyMediaUrl(String value) {
    final uri = Uri.tryParse(value);
    if (uri == null || uri.scheme != 'https') return false;

    return RegExp(
      r'^media\d*\.giphy\.com$',
    ).hasMatch(uri.host.toLowerCase());
  }

  static String? _imageUrl(
    Map<String, dynamic> images,
    String rendition,
  ) {
    final raw = images[rendition];
    if (raw is! Map) return null;

    final url = _string(raw['url']);
    if (url == null || !_isGiphyMediaUrl(url)) return null;

    return url;
  }

  factory GiphyGifModel.fromApi(Map<String, dynamic> data) {
    final images = (data['images'] as Map?)?.cast<String, dynamic>() ??
        const <String, dynamic>{};

    final previewUrl = _imageUrl(images, 'fixed_width') ??
        _imageUrl(images, 'downsized') ??
        _imageUrl(images, 'original');

    final sendUrl = _imageUrl(images, 'downsized_medium') ??
        _imageUrl(images, 'original') ??
        previewUrl;

    if (previewUrl == null || sendUrl == null) {
      throw const FormatException(
        'GIPHY response has no usable media URL.',
      );
    }

    final analytics = (data['analytics'] as Map?)?.cast<String, dynamic>() ??
        const <String, dynamic>{};

    String? analyticsUrl(String key) {
      final row = analytics[key];
      if (row is! Map) return null;
      return _string(row['url']);
    }

    return GiphyGifModel(
      id: _string(data['id']) ?? '',
      title: _string(data['title']),
      previewUrl: previewUrl,
      sendUrl: sendUrl,
      analyticsViewUrl: analyticsUrl('onload'),
      analyticsClickUrl: analyticsUrl('onclick'),
      analyticsSendUrl: analyticsUrl('onsent'),
    );
  }
}
