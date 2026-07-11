/// Web platform implementation of the image renderer.
///
/// This library utilizes [Image.network] to render network images on web and
/// WebAssembly (WASM) targets, fully bypassing native platform dependencies and 'dart:io'.
library;

import 'package:flutter/material.dart';

/// Renders a network image on web platforms using standard browser HTTP caching.
///
/// * [url] is the dynamic, optimized target URL formatted for the web platform.
/// * [width] represents the layout width constraint assigned to the image.
/// * [height] represents the layout height constraint assigned to the image.
/// * [fit] determines how the image fits into its layout constraints.
/// * [placeholder] is an optional custom loader displayed while fetching the asset.
/// * [errorWidget] is an optional custom fallback widget shown if image loading fails.
/// * [fallbackUrl] is the original, raw image URL used as a recovery fallback path.
Widget renderImage({
  required String url,
  required double? width,
  required double? height,
  required BoxFit fit,
  required Widget? placeholder,
  required Widget? errorWidget,
  required String fallbackUrl,
}) {
  return Image.network(
    url,
    width: width,
    height: height,
    fit: fit,
    loadingBuilder: (context, child, loadingProgress) {
      if (loadingProgress == null) return child;
      return placeholder ??
          Container(
            color: const Color(0xFF1E1E24),
            alignment: Alignment.center,
            child: const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
    },
    errorBuilder: (context, error, stackTrace) =>
        errorWidget ?? Icon(Icons.image_not_supported_rounded, size: height),
  );
}
