// Appwrite Storage image preview transformation.

import 'package:flutter/painting.dart' show BoxFit;

import '../url_sizing.dart';

/// Adds `width`, `height` and `gravity` to an Appwrite preview URL, keeping the
/// `project` parameter and any other query parameter.
///
/// Appwrite crops when both dimensions are sent and keeps the aspect ratio when
/// only one is, so the modes that must not crop send a single dimension.
String appwriteUrl(Uri uri, ImageSize size, BoxFit fit) {
  final Map<String, dynamic> query = <String, dynamic>{
    ...uri.queryParametersAll,
  };

  switch (fit) {
    case BoxFit.contain:
    case BoxFit.scaleDown:
    case BoxFit.fill:
    case BoxFit.fitWidth:
      query.remove('height');
      query['width'] = '${size.width}';
    case BoxFit.fitHeight:
      query.remove('width');
      query['height'] = '${size.height}';
    default:
      query['width'] = '${size.width}';
      query['height'] = '${size.height}';
      query.putIfAbsent('gravity', () => 'center');
  }

  return uri.replace(queryParameters: query).toString();
}
