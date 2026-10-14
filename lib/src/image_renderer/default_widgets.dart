// Default placeholder and error widgets shared by every platform renderer.
// Imports only Flutter material, so it is safe on native, web and WASM.

import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Neutral loading widget that follows the ambient theme.
Widget buildDefaultPlaceholder(BuildContext context) {
  return ColoredBox(
    color: Theme.of(context).colorScheme.surfaceContainerHighest,
    child: const Center(
      child: SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    ),
  );
}

/// Error icon sized to the available box, never larger than 48 logical pixels.
Widget buildDefaultError(double width, double height) {
  final double side = math.min(width, height);
  final double iconSize = (side * 0.4).clamp(16.0, 48.0).toDouble();
  return Center(child: Icon(Icons.image_not_supported_rounded, size: iconSize));
}
