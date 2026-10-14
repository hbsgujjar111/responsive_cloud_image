// Shopify CDN file-name size suffix.

import 'package:flutter/painting.dart' show BoxFit;

import '../url_sizing.dart';

// Matches a size suffix that is already in the file name, such as `_100x100`,
// `_300x` or `_x200`, so it is replaced instead of stacked.
final RegExp _existingSize = RegExp(r'_(?:\d+x\d*|x\d+)$');

/// Adds a `_WxH` size suffix before the file extension.
///
/// Shopify fits the image inside the requested box; it never crops, so every
/// fit except `fitWidth` and `fitHeight` uses the same suffix.
///
/// Returns `null` (use the original URL) when there is no file name with an
/// extension.
String? shopifyUrl(Uri uri, ImageSize size, BoxFit fit) {
  if (uri.pathSegments.isEmpty) return null;

  final String last = uri.pathSegments.last;
  final int dot = last.lastIndexOf('.');
  if (dot <= 0) return null;

  final String name = last.substring(0, dot).replaceFirst(_existingSize, '');
  final String extension = last.substring(dot);
  if (name.isEmpty) return null;

  final String suffix = switch (fit) {
    BoxFit.fitWidth => '_${size.width}x',
    BoxFit.fitHeight => '_x${size.height}',
    _ => '_${size.width}x${size.height}',
  };

  final List<String> segments = List<String>.of(uri.pathSegments);
  segments.removeLast();
  segments.add('$name$suffix$extension');
  return uri.replace(pathSegments: segments).toString();
}
