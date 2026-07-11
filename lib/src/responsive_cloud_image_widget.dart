/// The primary user-facing responsive image widget.
///
/// This library calculates widget bounds, multiplies by device pixel density,
/// and triggers platform-specific image rendering with optimization parameters.
library;

import 'package:flutter/material.dart';

import 'cloud_providers.dart';
import 'image_renderer/image_renderer.dart';

/// A widget that dynamically resizes image requests based on layout bounds.
///
/// [ResponsiveCloudImage] intercepts the layout phase, measures available physical
/// constraints, formats the source [imageUrl] with optimization parameters,
/// and renders a caching image frame on both native and web environments.
class ResponsiveCloudImage extends StatelessWidget {
  /// The original high-resolution raw image URL from your database.
  final String imageUrl;

  /// The Cloud hosting or CDN provider serving this asset.
  final CloudProvider provider;

  /// How the image should be inscribed into the layout box.
  final BoxFit fit;

  /// Optional custom builder callback required if [provider] is set to [CloudProvider.custom].
  final String? Function(String url, double width, double height)?
  customUrlBuilder;

  /// Optional placeholder widget displayed during network image loading.
  final Widget? placeholder;

  /// Optional error fallback widget shown if image loading or resizing fails.
  final Widget? errorWidget;

  /// Creates a responsive cloud image loader.
  ///
  /// * [imageUrl] is the original, raw uncompressed image path.
  /// * [provider] is the selected CDN formatting engine. Defaults to [CloudProvider.generic].
  /// * [fit] is the aspect ratio layout inscription. Defaults to [BoxFit.cover].
  /// * [customUrlBuilder] is required only if [provider] is [CloudProvider.custom].
  /// * [placeholder] is displayed while fetching the network asset.
  /// * [errorWidget] is shown if network or resizing transformations fail.
  const ResponsiveCloudImage({
    super.key,
    required this.imageUrl,
    this.provider = CloudProvider.generic,
    this.fit = BoxFit.cover,
    this.customUrlBuilder,
    this.placeholder,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    final double pixelRatio = MediaQuery.of(context).devicePixelRatio;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double logicalWidth = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : MediaQuery.of(context).size.width;

        final double logicalHeight = constraints.hasBoundedHeight
            ? constraints.maxHeight
            : logicalWidth * 0.75;

        final double physicalWidth = logicalWidth * pixelRatio;
        final double physicalHeight = logicalHeight * pixelRatio;

        final String optimizedUrl = CloudUrlAdapter.buildUrl(
          originalUrl: imageUrl,
          provider: provider,
          width: physicalWidth,
          height: physicalHeight,
          customBuilder: customUrlBuilder,
        );

        // Call the conditional renderer to load the best platform-native widget
        return renderImage(
          url: optimizedUrl,
          width: logicalWidth,
          height: logicalHeight,
          fit: fit,
          placeholder: placeholder,
          errorWidget: errorWidget,
          fallbackUrl: imageUrl,
        );
      },
    );
  }
}
