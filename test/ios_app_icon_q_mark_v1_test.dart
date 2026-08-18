import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

/// iOS AppIcon slots must keep Flutter Contents.json mappings and ship
/// opaque RGB artwork (no alpha on the 1024 marketing icon).
void main() {
  const iconset = 'ios/Runner/Assets.xcassets/AppIcon.appiconset';
  const contentsPath = '$iconset/Contents.json';

  late Map<String, dynamic> contents;
  late List<Map<String, dynamic>> images;

  setUpAll(() {
    contents =
        jsonDecode(File(contentsPath).readAsStringSync()) as Map<String, dynamic>;
    images = (contents['images'] as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  });

  test('Contents.json still maps every required iPhone/iPad/App Store slot', () {
    expect(
      images.map((e) => '${e['idiom']}|${e['size']}|${e['scale']}|${e['filename']}'),
      [
        'iphone|20x20|2x|Icon-App-20x20@2x.png',
        'iphone|20x20|3x|Icon-App-20x20@3x.png',
        'iphone|29x29|1x|Icon-App-29x29@1x.png',
        'iphone|29x29|2x|Icon-App-29x29@2x.png',
        'iphone|29x29|3x|Icon-App-29x29@3x.png',
        'iphone|40x40|2x|Icon-App-40x40@2x.png',
        'iphone|40x40|3x|Icon-App-40x40@3x.png',
        'iphone|60x60|2x|Icon-App-60x60@2x.png',
        'iphone|60x60|3x|Icon-App-60x60@3x.png',
        'ipad|20x20|1x|Icon-App-20x20@1x.png',
        'ipad|20x20|2x|Icon-App-20x20@2x.png',
        'ipad|29x29|1x|Icon-App-29x29@1x.png',
        'ipad|29x29|2x|Icon-App-29x29@2x.png',
        'ipad|40x40|1x|Icon-App-40x40@1x.png',
        'ipad|40x40|2x|Icon-App-40x40@2x.png',
        'ipad|76x76|1x|Icon-App-76x76@1x.png',
        'ipad|76x76|2x|Icon-App-76x76@2x.png',
        'ipad|83.5x83.5|2x|Icon-App-83.5x83.5@2x.png',
        'ios-marketing|1024x1024|1x|Icon-App-1024x1024@1x.png',
      ],
    );
  });

  test('every mapped AppIcon PNG exists at the exact pixel size', () {
    for (final entry in images) {
      final filename = entry['filename'] as String;
      final file = File('$iconset/$filename');
      expect(file.existsSync(), isTrue, reason: 'missing $filename');

      final expected = _pixelSize(entry['size'] as String, entry['scale'] as String);
      final png = _readPng(file);
      expect(png.width, expected, reason: '$filename width');
      expect(png.height, expected, reason: '$filename height');
    }
  });

  test('1024 App Store icon is RGB with no alpha', () {
    final png = _readPng(File('$iconset/Icon-App-1024x1024@1x.png'));
    expect(png.width, 1024);
    expect(png.height, 1024);
    expect(png.colorType, 2, reason: 'PNG color type 2 is RGB (6 would be RGBA)');
    expect(png.hasTrns, isFalse);
  });
}

int _pixelSize(String size, String scale) {
  final edge = double.parse(size.split('x').first);
  final factor = int.parse(scale.replaceAll('x', ''));
  return (edge * factor).round();
}

class _PngInfo {
  const _PngInfo({
    required this.width,
    required this.height,
    required this.colorType,
    required this.hasTrns,
  });

  final int width;
  final int height;
  final int colorType;
  final bool hasTrns;
}

_PngInfo _readPng(File file) {
  final bytes = file.readAsBytesSync();
  expect(
    bytes.sublist(0, 8),
    [137, 80, 78, 71, 13, 10, 26, 10],
    reason: '${file.path} is not a PNG',
  );

  final data = ByteData.sublistView(bytes);
  var offset = 8;
  var width = 0;
  var height = 0;
  var colorType = -1;
  var hasTrns = false;

  while (offset + 12 <= bytes.length) {
    final length = data.getUint32(offset);
    final type = String.fromCharCodes(bytes.sublist(offset + 4, offset + 8));
    final payloadStart = offset + 8;
    if (type == 'IHDR') {
      width = data.getUint32(payloadStart);
      height = data.getUint32(payloadStart + 4);
      colorType = bytes[payloadStart + 9];
    } else if (type == 'tRNS') {
      hasTrns = true;
    } else if (type == 'IEND') {
      break;
    }
    offset += 12 + length;
  }

  return _PngInfo(
    width: width,
    height: height,
    colorType: colorType,
    hasTrns: hasTrns,
  );
}
