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
  throw UnsupportedError(
    'Cannot render image without platform implementation.',
  );
}
