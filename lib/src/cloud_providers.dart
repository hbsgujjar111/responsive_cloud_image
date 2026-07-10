enum CloudProvider {
  supabase,
  appwrite,
  cloudinary,
  imgix,
  unsplash,
  shopify,
  sanity,
  custom,
  generic,
}

class CloudUrlAdapter {
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
