/// The primary user-facing responsive image widget.
///
/// This library calculates widget bounds, multiplies by device pixel density,
/// and triggers platform-specific image rendering with optimization parameters.
library;

import 'package:flutter/material.dart';

import 'cloud_provider.dart';
import 'cloud_url_adapter.dart';
import 'image_renderer/image_renderer.dart';
import 'url_sizing.dart';

/// A widget that dynamically resizes image requests based on layout bounds.
///
/// [ResponsiveCloudImage] intercepts the layout phase, measures available physical
/// constraints, formats the source [imageUrl] with optimization parameters,
/// and renders a caching image frame on both native and web environments.
///
/// The image always fills the largest box the parent allows. When the parent
/// gives an unbounded width, the screen width is used. When it gives an
/// unbounded height, a 4:3 box derived from the width is used. While the box
/// has no area, nothing is requested.
///
/// If the optimized image fails to load, the original [imageUrl] is tried once
/// before [errorWidget] is shown.
class ResponsiveCloudImage extends StatelessWidget {
  /// The original high-resolution raw image URL from your database.
  final String imageUrl;

  /// The Cloud hosting or CDN provider serving this asset.
  final CloudProvider provider;

  /// How the image should be inscribed into the layout box.
  ///
  /// Also selects the provider's crop or resize mode, so [BoxFit.contain] does
  /// not request an already cropped image. [BoxFit.none] disables URL
  /// optimization.
  final BoxFit fit;

  /// How the image is aligned inside the layout box.
  final Alignment alignment;

  /// Requested sizes are rounded up to a multiple of this many physical pixels.
  ///
  /// A coarser step means fewer distinct URLs while a widget is resized or
  /// animated, so more requests are served from the cache. Use 1 to request the
  /// exact size.
  final int sizeStep;

  /// Optional cap, in physical pixels, for the larger side of the request.
  ///
  /// Supabase (2500 px) and Appwrite (4000 px) never exceed their own limit.
  /// Other providers default to 4096 px.
  final int? maxDimension;

  /// Optional output quality from 1 to 100 requested from the CDN.
  ///
  /// Sent to Supabase (limited to 20-100), Appwrite, Cloudinary, Imgix, Unsplash
  /// and Sanity. Ignored by Shopify, [CloudProvider.custom] and
  /// [CloudProvider.generic]. When null, the CDN's own default is used.
  final int? quality;

  /// Optional stable identity of the image, used for the disk cache on native
  /// platforms.
  ///
  /// Use it when [imageUrl] carries a changing part, such as the token of a
  /// signed URL, so the same picture is not downloaded again each time the URL
  /// changes. The size, fit and [quality] are added to the key automatically, so
  /// different renditions never overwrite each other. Ignored on the web, where
  /// the browser caches by URL.
  final String? cacheKey;

  /// Optional custom builder callback required if [provider] is set to [CloudProvider.custom].
  final String? Function(String url, double width, double height)?
  customUrlBuilder;

  /// Optional placeholder widget displayed during network image loading.
  final Widget? placeholder;

  /// Optional error fallback widget shown if image loading or resizing fails.
  final Widget? errorWidget;

  /// Optional HTTP headers sent with every image request, for example an
  /// `Authorization` header for a private bucket.
  final Map<String, String>? httpHeaders;

  /// Optional text announced by screen readers to describe the image.
  final String? semanticLabel;

  /// Creates a responsive cloud image loader.
  ///
  /// * [imageUrl] is the original, raw uncompressed image path.
  /// * [provider] is the selected CDN formatting engine. Defaults to [CloudProvider.generic].
  /// * [fit] is the aspect ratio layout inscription. Defaults to [BoxFit.cover].
  /// * [alignment] positions the image in its box. Defaults to [Alignment.center].
  /// * [sizeStep] is the rounding step for requested sizes. Defaults to 50.
  /// * [maxDimension] optionally caps the requested size.
  /// * [quality] optionally sets the CDN output quality (1-100).
  /// * [cacheKey] optionally sets a stable disk-cache identity (native only).
  /// * [customUrlBuilder] is required only if [provider] is [CloudProvider.custom].
  /// * [placeholder] is displayed while fetching the network asset.
  /// * [errorWidget] is shown if network or resizing transformations fail.
  /// * [httpHeaders] are sent with every image request.
  /// * [semanticLabel] describes the image for screen readers.
  const ResponsiveCloudImage({
    super.key,
    required this.imageUrl,
    this.provider = CloudProvider.generic,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.sizeStep = 50,
    this.maxDimension,
    this.quality,
    this.cacheKey,
    this.customUrlBuilder,
    this.placeholder,
    this.errorWidget,
    this.httpHeaders,
    this.semanticLabel,
  }) : assert(
         provider != CloudProvider.custom || customUrlBuilder != null,
         'customUrlBuilder is required when provider is CloudProvider.custom.',
       ),
       assert(sizeStep >= 1, 'sizeStep must be at least 1.'),
       assert(
         maxDimension == null || maxDimension > 0,
         'maxDimension must be greater than 0.',
       ),
       assert(
         quality == null || (quality >= 1 && quality <= 100),
         'quality must be between 1 and 100.',
       ),
       assert(
         cacheKey == null || cacheKey != '',
         'cacheKey must not be empty.',
       );

  @override
  Widget build(BuildContext context) {
    final double pixelRatio = MediaQuery.devicePixelRatioOf(context);
    final double screenWidth = MediaQuery.sizeOf(context).width;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double logicalWidth = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : screenWidth;

        final double logicalHeight = constraints.hasBoundedHeight
            ? constraints.maxHeight
            : logicalWidth * 0.75;

        // Nothing to show, and nothing worth downloading, in an empty box.
        if (logicalWidth <= 0 || logicalHeight <= 0) {
          return const SizedBox.shrink();
        }

        final String optimizedUrl = CloudUrlAdapter.buildUrl(
          originalUrl: imageUrl,
          provider: provider,
          width: logicalWidth * pixelRatio,
          height: logicalHeight * pixelRatio,
          fit: fit,
          sizeStep: sizeStep,
          maxDimension: maxDimension,
          quality: quality,
          customBuilder: customUrlBuilder,
        );

        final String? key = cacheKey;
        String? primaryKey;
        String? fallbackKey;
        if (key != null) {
          fallbackKey = '$key|original';
          primaryKey = fallbackKey;
          if (optimizedUrl != imageUrl) {
            final ImageSize? size = resolveImageSize(
              provider: provider,
              width: logicalWidth * pixelRatio,
              height: logicalHeight * pixelRatio,
              sizeStep: sizeStep,
              maxDimension: maxDimension,
            );
            if (size != null) {
              primaryKey =
                  '$key|${size.width}x${size.height}|${fit.name}|q$quality';
            }
          }
        }

        // Call the conditional renderer to load the best platform-native widget
        final Widget image = renderImage(
          url: optimizedUrl,
          width: logicalWidth,
          height: logicalHeight,
          fit: fit,
          alignment: alignment,
          placeholder: placeholder,
          errorWidget: errorWidget,
          fallbackUrl: imageUrl,
          httpHeaders: httpHeaders,
          cacheKey: primaryKey,
          fallbackCacheKey: fallbackKey,
        );

        final String? label = semanticLabel;
        if (label == null) return image;
        return Semantics(label: label, image: true, child: image);
      },
    );
  }
}
