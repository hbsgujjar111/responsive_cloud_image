import 'package:cached_network_image/cached_network_image.dart';
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
