import 'package:flutter/material.dart';
import 'package:responsive_cloud_image/responsive_cloud_image.dart';

// Supabase, Appwrite and Sanity serve images from your own project, so there
// is no shared demo file. Paste a public image URL from your own project to
// see each card load. While a constant is empty, its card shows a hint.
const String _supabaseImageUrl = '';
const String _appwriteImageUrl = '';
const String _sanityImageUrl = '';

void main() {
  runApp(const ResponsiveCloudImageDemoApp());
}

class ResponsiveCloudImageDemoApp extends StatelessWidget {
  const ResponsiveCloudImageDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true).copyWith(
        scaffoldBackgroundColor: const Color(0xFF0C0C0E),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
      ),
      home: const DemoGalleryScreen(),
    );
  }
}

class DemoGalleryScreen extends StatelessWidget {
  const DemoGalleryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Responsive CDN Loader Demo'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                'This screen demonstrates live, on-the-fly responsive image resizing across multiple hosting backends. Each widget calculates its parent bounds, multiplies by device pixel density, and downloads the optimal thumbnail size.',
                style: TextStyle(color: Colors.grey, height: 1.5, fontSize: 13),
              ),
            ),
            const SizedBox(height: 28),

            // 1. UNSPLASH
            _buildImageCard(
              title: '1. Unsplash CDN',
              subtitle: 'Active Query Transform (?w=x&h=y)',
              child: const ResponsiveCloudImage(
                imageUrl:
                    'https://images.unsplash.com/photo-1504384308090-c894fdcc538d',
                provider: CloudProvider.unsplash,
              ),
            ),

            // 2. CLOUDINARY
            _buildImageCard(
              title: '2. Cloudinary Enterprise CDN',
              subtitle: 'Path Injection Transform (/upload/w_x,h_y,c_fill/)',
              child: const ResponsiveCloudImage(
                imageUrl:
                    'https://res.cloudinary.com/demo/image/upload/sample.jpg',
                provider: CloudProvider.cloudinary,
              ),
            ),

            // 3. IMGIX
            _buildImageCard(
              title: '3. Imgix Processing Network',
              subtitle: 'Active Query Transform (?w=x&h=y&fit=crop)',
              child: const ResponsiveCloudImage(
                imageUrl: 'https://assets.imgix.net/examples/bridge.jpg',
                provider: CloudProvider.imgix,
              ),
            ),

            // 4. SHOPIFY CDN
            _buildImageCard(
              title: '4. Shopify Global Storefront CDN',
              subtitle: 'Filename Suffix Insertion (filename_300x300.jpg)',
              child: const ResponsiveCloudImage(
                imageUrl:
                    'https://cdn.shopify.com/static/sample-images/garnished.jpeg',
                provider: CloudProvider.shopify,
              ),
            ),

            // 5. CUSTOM CALLBACK (Self-Hosted Laravel, .NET, Node.js)
            _buildImageCard(
              title: '5. Custom Backend Adapter Callback',
              subtitle:
                  'Demonstrated via Unsplash base applying black-and-white filters',
              child: ResponsiveCloudImage(
                imageUrl:
                    'https://images.unsplash.com/photo-1504384308090-c894fdcc538d',
                provider: CloudProvider.custom,
                customUrlBuilder: (url, width, height) {
                  return '$url?w=${width.round()}&h=${height.round()}&fit=crop&sat=-100';
                },
              ),
            ),

            // 6. GENERIC / FALLBACK
            _buildImageCard(
              title: '6. Generic Fallback Renderer',
              subtitle:
                  'Passes unaltered raw URL directly to standard cached frame',
              child: const ResponsiveCloudImage(
                imageUrl:
                    'https://images.unsplash.com/photo-1534528741775-53994a69daeb',
                provider: CloudProvider.generic,
              ),
            ),

            // 7. SUPABASE STORAGE
            _buildImageCard(
              title: '7. Supabase Storage Public Bucket',
              subtitle:
                  'Storage API Query Transform (Rewriting /object/ to /render/image/)',
              child: _imageOrHint(
                url: _supabaseImageUrl,
                provider: CloudProvider.supabase,
                hint:
                    'Set _supabaseImageUrl in example/lib/main.dart to a '
                    'public object URL from your Supabase project. '
                    'Transformations need a paid plan; on a free plan the '
                    'original image is shown instead.',
              ),
            ),

            // 8. APPWRITE STORAGE
            _buildImageCard(
              title: '8. Appwrite Cloud Storage',
              subtitle:
                  'Storage API Preview Transform (Authorized with ?project=)',
              child: _imageOrHint(
                url: _appwriteImageUrl,
                provider: CloudProvider.appwrite,
                hint:
                    'Set _appwriteImageUrl in example/lib/main.dart to a '
                    '/preview URL from an Appwrite bucket that gives the '
                    '"Any" role Read permission.',
              ),
            ),

            // 9. SANITY.IO
            _buildImageCard(
              title: '9. Sanity.io Content Lake CDN',
              subtitle: 'Content API Query Transform (?w=x&h=y)',
              child: _imageOrHint(
                url: _sanityImageUrl,
                provider: CloudProvider.sanity,
                hint:
                    'Set _sanityImageUrl in example/lib/main.dart to a '
                    'cdn.sanity.io image URL from a public dataset.',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imageOrHint({
    required String url,
    required CloudProvider provider,
    required String hint,
  }) {
    if (url.isEmpty) return _AddUrlHint(message: hint);
    return ResponsiveCloudImage(imageUrl: url, provider: provider);
  }

  Widget _buildImageCard({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 28.0),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF131316),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: .06)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.blueAccent.withValues(alpha: .8),
                    ),
                  ),
                ],
              ),
            ),
            AspectRatio(
              aspectRatio: 16 / 9,
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(19),
                  bottomRight: Radius.circular(19),
                ),
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shown in place of an image until the matching URL constant is filled in.
class _AddUrlHint extends StatelessWidget {
  const _AddUrlHint({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF1B1B20),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 12,
              height: 1.5,
            ),
          ),
        ),
      ),
    );
  }
}
