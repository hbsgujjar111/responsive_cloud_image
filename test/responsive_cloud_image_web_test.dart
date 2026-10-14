@TestOn('browser')
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:responsive_cloud_image/responsive_cloud_image.dart';

// Run with: flutter test --platform chrome test/responsive_cloud_image_web_test.dart
// On the Dart VM this file is skipped by @TestOn('browser').

const String _unsplash =
    'https://images.unsplash.com/photo-1504384308090-c894fdcc538d';

Future<void> _pump(WidgetTester tester, Widget child) async {
  tester.view.devicePixelRatio = 3.0;
  tester.view.physicalSize = const Size(1200, 2400);
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Align(alignment: Alignment.topLeft, child: child),
      ),
    ),
  );
  // Network access is not available in the test harness; ignore load errors.
  tester.takeException();
}

void main() {
  testWidgets('web renderer uses Image.network with the optimized URL', (
    WidgetTester tester,
  ) async {
    await _pump(
      tester,
      const SizedBox(
        width: 100,
        height: 100,
        child: ResponsiveCloudImage(
          imageUrl: _unsplash,
          provider: CloudProvider.unsplash,
        ),
      ),
    );

    final image = tester.widget<Image>(find.byType(Image));
    final provider = image.image as NetworkImage;
    final query = Uri.parse(provider.url).queryParameters;
    expect(query['w'], '300');
    expect(query['h'], '300');
    expect(query['fit'], 'crop');
    expect(image.width, 100);
    expect(image.height, 100);
  });

  testWidgets('web renderer retries the original URL, then shows the error', (
    WidgetTester tester,
  ) async {
    await _pump(
      tester,
      const SizedBox(
        width: 100,
        height: 100,
        child: ResponsiveCloudImage(
          imageUrl: _unsplash,
          provider: CloudProvider.unsplash,
          errorWidget: Text('failed'),
        ),
      ),
    );

    final context = tester.element(find.byType(Image));
    final first = tester.widget<Image>(find.byType(Image));

    final retry = first.errorBuilder!(context, Exception('x'), null);
    expect(retry, isA<Image>());
    final second = retry as Image;
    expect((second.image as NetworkImage).url, _unsplash);

    final last = second.errorBuilder!(context, Exception('x'), null);
    expect(last, isA<Text>());
  });
}
