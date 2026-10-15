// Cloudinary delivery URL transformation.

import 'package:flutter/painting.dart' show BoxFit;

import '../url_sizing.dart';

/// Inserts a transformation segment right after `/upload/`.
///
/// A non-null [quality] is appended to the segment as `q_<quality>`.
///
/// Returns `null` (use the original URL) when the URL has no `upload` segment.
String? cloudinaryUrl(Uri uri, ImageSize size, BoxFit fit, {int? quality}) {
  final List<String> segments = List<String>.of(uri.pathSegments);
  final int uploadIndex = segments.indexOf('upload');
  if (uploadIndex == -1) return null;

  final String transformation = _transformation(size, fit);
  segments.insert(
    uploadIndex + 1,
    quality == null ? transformation : '$transformation,q_$quality',
  );
  return uri.replace(pathSegments: segments).toString();
}

String _transformation(ImageSize size, BoxFit fit) {
  final int w = size.width;
  final int h = size.height;
  return switch (fit) {
    BoxFit.fitWidth => 'w_$w,c_scale',
    BoxFit.fitHeight => 'h_$h,c_scale',
    BoxFit.contain => 'w_$w,h_$h,c_fit',
    BoxFit.scaleDown => 'w_$w,h_$h,c_limit',
    BoxFit.fill => 'w_$w,h_$h,c_scale',
    _ => 'w_$w,h_$h,c_fill',
  };
}
