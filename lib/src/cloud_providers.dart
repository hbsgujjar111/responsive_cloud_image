/// Cloud storage and CDN provider configurations.
///
/// This library defines the supported CDN types and handles the URL string-manipulation
/// algorithms for each of those endpoints.
library;

/// Supported cloud storage and CDN providers.
enum CloudProvider {
  /// Supabase Storage dynamic image resizing.
  supabase,

  /// Appwrite Storage dynamic image resizing.
  appwrite,

  /// Cloudinary image delivery network.
  cloudinary,

  /// Imgix image processing CDN.
  imgix,

  /// Unsplash dynamic image delivery.
  unsplash,

  /// Shopify storefront CDN.
  shopify,

  /// Sanity.io Content Lake CDN.
  sanity,

  /// Custom user-defined image resizing scheme.
  custom,

  /// Generic fallback (original unaltered URL).
  generic,
}

/// A utility adapter to format original image URLs into optimized CDN URLs.
class CloudUrlAdapter {
  // Private constructor prevents instantiation of this static utility class.
  CloudUrlAdapter._();

  /// Transforms the [originalUrl] using the rules of the selected [provider].
  ///
  /// Pass [width] and [height] representing the target physical size in pixels.
  /// If [provider] is [CloudProvider.custom], supply [customBuilder].
  ///
  /// * [originalUrl] is the initial uncompressed raw image path.
  /// * [provider] specifies the CDN host and its formatting engine.
  /// * [width] represents the calculated target physical pixel width.
  /// * [height] represents the calculated target physical pixel height.
  /// * [customBuilder] is a callback triggered only if [provider] is [CloudProvider.custom].
  static String buildUrl({
    required String originalUrl,
    required CloudProvider provider,
    required double width,
    required double height,
    String? Function(String url, double width, double height)? customBuilder,
  }) {
    if (width <= 0 || height <= 0) return originalUrl;

    final int targetW = width.round();
    final int targetH = height.round();
    final Uri uri = Uri.parse(originalUrl);

    switch (provider) {
      case CloudProvider.supabase:
        // FIX: Supabase resizing requires changing '/object/public/' to '/render/image/public/'
        String path = uri.path;
        if (path.contains('/object/public/')) {
          path = path.replaceAll('/object/public/', '/render/image/public/');
        }
        return uri
            .replace(
              path: path,
              queryParameters: {
                ...uri.queryParameters,
                'width': '$targetW',
                'height': '$targetH',
                'resize': 'cover',
              },
            )
            .toString();

      case CloudProvider.appwrite:
        // Appwrite expects ?width=x&height=y&crop=center (preserving project parameters)
        return uri
            .replace(
              queryParameters: {
                ...uri.queryParameters,
                'width': '$targetW',
                'height': '$targetH',
                'crop': 'center',
              },
            )
            .toString();

      case CloudProvider.cloudinary:
        final List<String> segments = List.from(uri.pathSegments);
        final int uploadIndex = segments.indexOf('upload');
        if (uploadIndex != -1) {
          segments.insert(uploadIndex + 1, 'w_$targetW,h_$targetH,c_fill');
        }
        return uri.replace(pathSegments: segments).toString();

      case CloudProvider.imgix:
        return uri
            .replace(
              queryParameters: {
                ...uri.queryParameters,
                'w': '$targetW',
                'h': '$targetH',
                'fit': 'crop',
              },
            )
            .toString();

      case CloudProvider.unsplash:
        return uri
            .replace(
              queryParameters: {
                ...uri.queryParameters,
                'w': '$targetW',
                'h': '$targetH',
                'fit': 'crop',
              },
            )
            .toString();

      case CloudProvider.shopify:
        if (uri.pathSegments.isEmpty) return originalUrl;
        final String lastSegment = uri.pathSegments.last;
        final int dotIndex = lastSegment.lastIndexOf('.');
        if (dotIndex != -1) {
          final String name = lastSegment.substring(0, dotIndex);
          final String ext = lastSegment.substring(dotIndex);
          final String newLastSegment = '${name}_${targetW}x$targetH$ext';

          final List<String> segments = List.from(uri.pathSegments);
          segments.removeLast();
          segments.add(newLastSegment);

          return uri.replace(pathSegments: segments).toString();
        }
        return originalUrl;

      case CloudProvider.sanity:
        return uri
            .replace(
              queryParameters: {
                ...uri.queryParameters,
                'w': '$targetW',
                'h': '$targetH',
                'fit': 'crop',
              },
            )
            .toString();

      case CloudProvider.custom:
        if (customBuilder != null) {
          return customBuilder(originalUrl, width, height) ?? originalUrl;
        }
        return originalUrl;

      case CloudProvider.generic:
        return originalUrl;
    }
  }
}
