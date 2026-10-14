/// URL string-manipulation for every supported CDN.
///
/// This library turns an original image URL into the optimized URL of a cloud
/// storage provider or image CDN.
library;

import 'package:flutter/foundation.dart'
    show ErrorDescription, FlutterError, FlutterErrorDetails;
import 'package:flutter/painting.dart' show BoxFit;

import 'cloud_provider.dart';
import 'providers/appwrite.dart';
import 'providers/cloudinary.dart';
import 'providers/imgix_style.dart';
import 'providers/shopify.dart';
import 'providers/supabase.dart';
import 'url_sizing.dart';

/// A utility adapter to format original image URLs into optimized CDN URLs.
class CloudUrlAdapter {
  // Private constructor prevents instantiation of this static utility class.
  CloudUrlAdapter._();

  /// Transforms the [originalUrl] using the rules of the selected [provider].
  ///
  /// Pass [width] and [height] representing the target physical size in pixels.
  /// The size is rounded to whole pixels, rounded up to a multiple of
  /// [sizeStep], and capped so the larger side never exceeds the provider limit
  /// (2500 px for Supabase, 4000 px for Appwrite, 4096 px otherwise) or
  /// [maxDimension], keeping the aspect ratio.
  ///
  /// The original URL is returned unchanged when the size is not usable (zero,
  /// negative, NaN or infinite), when [fit] is [BoxFit.none], when the URL
  /// cannot be parsed, or when the URL is not one the [provider] can resize
  /// (for example a signed Supabase URL).
  ///
  /// * [originalUrl] is the initial uncompressed raw image path.
  /// * [provider] specifies the CDN host and its formatting engine.
  /// * [width] represents the calculated target physical pixel width.
  /// * [height] represents the calculated target physical pixel height.
  /// * [fit] selects the provider's crop or resize mode. Defaults to
  ///   [BoxFit.cover].
  /// * [sizeStep] is the step, in pixels, that requested sizes are rounded up
  ///   to. Defaults to 1 (exact size).
  /// * [maxDimension] is an optional cap, in pixels, for the larger side.
  /// * [customBuilder] is a callback triggered only if [provider] is
  ///   [CloudProvider.custom]. It receives the final whole-pixel size. An
  ///   exception it throws is reported with [FlutterError.reportError] and the
  ///   original URL is used.
  static String buildUrl({
    required String originalUrl,
    required CloudProvider provider,
    required double width,
    required double height,
    BoxFit fit = BoxFit.cover,
    int sizeStep = 1,
    int? maxDimension,
    String? Function(String url, double width, double height)? customBuilder,
  }) {
    if (originalUrl.isEmpty ||
        provider == CloudProvider.generic ||
        fit == BoxFit.none) {
      return originalUrl;
    }

    final ImageSize? size = resolveImageSize(
      provider: provider,
      width: width,
      height: height,
      sizeStep: sizeStep,
      maxDimension: maxDimension,
    );
    if (size == null) return originalUrl;

    if (provider == CloudProvider.custom) {
      return _buildCustom(originalUrl, size, customBuilder);
    }

    final Uri? uri = Uri.tryParse(originalUrl);
    if (uri == null) return originalUrl;

    final String? built = switch (provider) {
      CloudProvider.supabase => supabaseUrl(uri, size, fit),
      CloudProvider.appwrite => appwriteUrl(uri, size, fit),
      CloudProvider.cloudinary => cloudinaryUrl(uri, size, fit),
      CloudProvider.shopify => shopifyUrl(uri, size, fit),
      CloudProvider.imgix ||
      CloudProvider.unsplash ||
      CloudProvider.sanity => imgixStyleUrl(uri, size, fit),
      CloudProvider.custom || CloudProvider.generic => null,
    };
    return built ?? originalUrl;
  }

  static String _buildCustom(
    String originalUrl,
    ImageSize size,
    String? Function(String url, double width, double height)? customBuilder,
  ) {
    if (customBuilder == null) return originalUrl;
    try {
      return customBuilder(
            originalUrl,
            size.width.toDouble(),
            size.height.toDouble(),
          ) ??
          originalUrl;
    } catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'responsive_cloud_image',
          context: ErrorDescription('while building a custom image URL'),
        ),
      );
      return originalUrl;
    }
  }
}
