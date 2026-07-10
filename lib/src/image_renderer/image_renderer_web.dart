import 'package:flutter/material.dart';

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
