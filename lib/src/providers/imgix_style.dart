// Imgix-style transformation. Imgix, Unsplash and Sanity all accept `w`, `h`
// and `fit` query parameters.

import 'package:flutter/painting.dart' show BoxFit;

import '../url_sizing.dart';

/// Adds `w`, `h` and `fit` to [uri], keeping every other query parameter.
///
/// A non-null [quality] is sent as `q`.
String imgixStyleUrl(Uri uri, ImageSize size, BoxFit fit, {int? quality}) {
  final Map<String, dynamic> query = <String, dynamic>{
    ...uri.queryParametersAll,
  };

  switch (fit) {
    case BoxFit.fitWidth:
      query.remove('h');
      query.remove('fit');
      query['w'] = '${size.width}';
    case BoxFit.fitHeight:
      query.remove('w');
      query.remove('fit');
      query['h'] = '${size.height}';
    default:
      query['w'] = '${size.width}';
      query['h'] = '${size.height}';
      query['fit'] = _fitMode(fit);
  }

  if (quality != null) query['q'] = '$quality';

  return uri.replace(queryParameters: query).toString();
}

String _fitMode(BoxFit fit) {
  return switch (fit) {
    BoxFit.contain => 'clip',
    BoxFit.scaleDown => 'max',
    BoxFit.fill => 'scale',
    _ => 'crop',
  };
}
