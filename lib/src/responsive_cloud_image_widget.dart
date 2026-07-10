import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'cloud_providers.dart';

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
    // Read the physical pixel ratio of the current device screen
    final double pixelRatio = MediaQuery.of(context).devicePixelRatio;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Fallback to screen width/height if layout is boundless (e.g. inside infinite scroll)
        final double logicalWidth = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : MediaQuery.of(context).size.width;

        final double logicalHeight = constraints.hasBoundedHeight
            ? constraints.maxHeight
            : logicalWidth * 0.75; // Default to standard 4:3 aspect ratio

        // Multiply logical widget constraints by screen density to compute raw target physical pixels
        final double physicalWidth = logicalWidth * pixelRatio;
        final double physicalHeight = logicalHeight * pixelRatio;

        final String optimizedUrl = CloudUrlAdapter.buildUrl(
          originalUrl: imageUrl,
          provider: provider,
          width: physicalWidth,
          height: physicalHeight,
          customBuilder: customUrlBuilder,
        );

        return CachedNetworkImage(
          imageUrl: optimizedUrl,
          width: logicalWidth,
          height: logicalHeight,
          fit: fit,
          placeholder: (context, url) =>
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
          errorWidget: (context, url, error) =>
              errorWidget ??
              Icon(Icons.image_not_supported_rounded, size: logicalHeight),
        );
      },
    );
  }
}
