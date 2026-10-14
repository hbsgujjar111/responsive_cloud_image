// Supabase Storage image transformation.

import 'package:flutter/painting.dart' show BoxFit;

import '../url_sizing.dart';

/// Rewrites a public Supabase Storage URL to its image-transformation endpoint
/// and adds `width`, `height` and `resize`.
///
/// Returns `null` (use the original URL) for anything that is not a public
/// object: signed and authenticated URLs carry their access token, and signed
/// transformations are fixed inside that token, so they cannot be resized here.
String? supabaseUrl(Uri uri, ImageSize size, BoxFit fit) {
  String path = uri.path;
  if (path.contains('/object/public/')) {
    path = path.replaceFirst('/object/public/', '/render/image/public/');
  } else if (!path.contains('/render/image/public/')) {
    return null;
  }

  final Map<String, dynamic> query = <String, dynamic>{
    ...uri.queryParametersAll,
  };

  switch (fit) {
    case BoxFit.fitWidth:
      query.remove('height');
      query.remove('resize');
      query['width'] = '${size.width}';
    case BoxFit.fitHeight:
      query.remove('width');
      query.remove('resize');
      query['height'] = '${size.height}';
    default:
      query['width'] = '${size.width}';
      query['height'] = '${size.height}';
      query['resize'] = _resizeMode(fit);
  }

  return uri.replace(path: path, queryParameters: query).toString();
}

String _resizeMode(BoxFit fit) {
  return switch (fit) {
    BoxFit.contain || BoxFit.scaleDown => 'contain',
    BoxFit.fill => 'fill',
    _ => 'cover',
  };
}
