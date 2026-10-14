/// Supported cloud storage and CDN providers.
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
