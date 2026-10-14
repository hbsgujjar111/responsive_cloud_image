/// Web platform implementation of the image renderer.
///
/// This library utilizes [Image.network] to render network images on web and
/// WebAssembly (WASM) targets, fully bypassing native platform dependencies and 'dart:io'.
library;

import 'package:flutter/material.dart';

import 'default_widgets.dart';

/// Renders a network image on web platforms using standard browser HTTP caching.
///
/// If loading [url] fails and it differs from [fallbackUrl], the image is
/// requested once more from [fallbackUrl] before the error widget is shown.
///
/// * [url] is the dynamic, optimized target URL formatted for the web platform.
/// * [width] represents the layout width constraint assigned to the image.
/// * [height] represents the layout height constraint assigned to the image.
/// * [fit] determines how the image fits into its layout constraints.
/// * [alignment] positions the image inside its layout box.
/// * [placeholder] is an optional custom loader displayed while fetching the asset.
/// * [errorWidget] is an optional custom fallback widget shown if image loading fails.
/// * [fallbackUrl] is the original, raw image URL used as a recovery fallback path.
/// * [httpHeaders] are sent with every image request. On the web the server
///   must allow them through CORS.
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
  return Image.network(
    url,
    width: width,
    height: height,
    fit: fit,
    alignment: alignment,
    headers: httpHeaders,
    loadingBuilder: (context, child, loadingProgress) {
      if (loadingProgress == null) return child;
      return placeholder ?? buildDefaultPlaceholder(context);
    },
    errorBuilder: (context, error, stackTrace) {
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
