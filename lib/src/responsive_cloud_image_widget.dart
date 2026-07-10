import 'package:flutter/material.dart';

import 'cloud_providers.dart';
import 'image_renderer/image_renderer.dart';

class ResponsiveCloudImage extends StatelessWidget {
  final String imageUrl;
  final CloudProvider provider;
  final BoxFit fit;
  final String? Function(String url, double width, double height)?
  customUrlBuilder;
  final Widget? placeholder;
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
