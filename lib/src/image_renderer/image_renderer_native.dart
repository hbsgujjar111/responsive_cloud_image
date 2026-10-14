/// Native platform implementation of the image renderer.
///
/// This library utilizes [CachedNetworkImage] to handle network image
/// loading, offline disk caching, and progressive fallback states.
library;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'default_widgets.dart';

/// Renders a network image with disk caching using [CachedNetworkImage].
///
/// If loading [url] fails and it differs from [fallbackUrl], the image is
/// requested once more from [fallbackUrl] before the error widget is shown.
///
/// * [url] is the dynamic, optimized target URL formatted for the native platform.
/// * [width] represents the layout width constraint assigned to the image.
/// * [height] represents the layout height constraint assigned to the image.
/// * [fit] determines how the image fits into its layout constraints.
/// * [alignment] positions the image inside its layout box.
/// * [placeholder] is an optional custom loader displayed while fetching the asset.
/// * [errorWidget] is an optional custom fallback widget shown if image loading fails.
/// * [fallbackUrl] is the original, raw image URL used as a recovery fallback path.
/// * [httpHeaders] are sent with every image request.
Widget renderImage({
  required String url,
  required double width,
  required double height,
  required BoxFit fit,
  required Alignment alignment,
  required Widget? placeholder,
  required Widget? errorWidget,
  required String fallbackUrl,
  required Map<String, String>? httpHeaders,
}) {
  return CachedNetworkImage(
    imageUrl: url,
    width: width,
    height: height,
    fit: fit,
    alignment: alignment,
    httpHeaders: httpHeaders,
    placeholder: (context, _) =>
        placeholder ?? buildDefaultPlaceholder(context),
    errorWidget: (context, failedUrl, error) {
      if (url != fallbackUrl) {
        return renderImage(
          url: fallbackUrl,
          width: width,
          height: height,
          fit: fit,
          alignment: alignment,
          placeholder: placeholder,
          errorWidget: errorWidget,
          fallbackUrl: fallbackUrl,
          httpHeaders: httpHeaders,
        );
      }
      return errorWidget ?? buildDefaultError(width, height);
    },
  );
}
