// Internal helpers that turn a measured size into the whole-pixel size that is
// actually requested from a CDN. Not exported from the package.

import 'dart:math' as math;

import 'cloud_provider.dart';

/// Size, in whole physical pixels, requested from a CDN.
class ImageSize {
  /// Creates a requested size.
  const ImageSize(this.width, this.height);

  /// Requested width in physical pixels.
  final int width;

  /// Requested height in physical pixels.
  final int height;
}

/// Largest side requested from providers that have no documented hard limit.
const int defaultMaxDimension = 4096;

/// Largest side a provider accepts, or `null` when none is documented.
int? _hardLimit(CloudProvider provider) {
  return switch (provider) {
    CloudProvider.supabase => 2500,
    CloudProvider.appwrite => 4000,
    _ => null,
  };
}

/// Rounds a measured size to whole pixels, then up to a multiple of
/// [sizeStep], then scales it down (keeping the aspect ratio) so the larger
/// side stays within the provider limit and [maxDimension].
///
/// Returns `null` when the size is not usable (zero, negative, NaN or
/// infinite), so the caller can fall back to the original URL.
ImageSize? resolveImageSize({
  required CloudProvider provider,
  required double width,
  required double height,
  required int sizeStep,
  required int? maxDimension,
}) {
  if (!width.isFinite || !height.isFinite || width <= 0 || height <= 0) {
    return null;
  }

  // Clamp first so absurd values cannot overflow the integer maths below.
  int w = width.clamp(1.0, 100000.0).round();
  int h = height.clamp(1.0, 100000.0).round();

  if (sizeStep > 1) {
    w = _roundUp(w, sizeStep);
    h = _roundUp(h, sizeStep);
  }

  final int cap = _cap(provider, maxDimension);
  final int longest = math.max(w, h);
  if (longest > cap) {
    final double scale = cap / longest;
    w = math.max(1, (w * scale).round());
    h = math.max(1, (h * scale).round());
  }

  return ImageSize(w, h);
}

int _roundUp(int value, int step) => ((value + step - 1) ~/ step) * step;

int _cap(CloudProvider provider, int? maxDimension) {
  final int? requested = (maxDimension != null && maxDimension > 0)
      ? maxDimension
      : null;
  final int? hard = _hardLimit(provider);
  if (hard != null) {
    return requested == null ? hard : math.min(hard, requested);
  }
  return requested ?? defaultMaxDimension;
}
