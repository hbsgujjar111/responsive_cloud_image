/// Stub implementation of the platform-specific image renderer.
///
/// This library acts as the fallback compilation interface for platform-specific
/// image rendering. It is overridden at compile-time by conditional exports.
library;

import 'package:flutter/material.dart';

/// The base stub interface for rendering a platform-specific image.
///
/// This function throws an [UnsupportedError] if invoked directly without an
/// active platform-specific implementation (such as Native or Web).
///
/// * [url] is the dynamic, optimized target URL.
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
  throw UnsupportedError(
    'Cannot render image without platform implementation.',
  );
}
