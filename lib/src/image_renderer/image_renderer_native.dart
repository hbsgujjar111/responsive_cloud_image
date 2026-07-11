/// Native platform implementation of the image renderer.
///
/// This library utilizes [CachedNetworkImage] to handle network image
/// loading, offline disk caching, and progressive fallback states.
library;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Renders a network image with disk caching using [CachedNetworkImage].
///
/// * [url] is the dynamic, optimized target URL formatted for the native platform.
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
  return CachedNetworkImage(
    imageUrl: url,
    width: width,
    height: height,
    fit: fit,
    placeholder: (context, _) =>
        placeholder ??
        Container(
          color: const Color(0xFF1E1E24),
          alignment: Alignment.center,
          child: const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
    errorWidget: (context, _, _) =>
        errorWidget ?? Icon(Icons.image_not_supported_rounded, size: height),
  );
}
