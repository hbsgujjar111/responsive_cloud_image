import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:responsive_cloud_image/responsive_cloud_image.dart';

// These tests run on the Dart VM, where the native renderer
// (CachedNetworkImage) is selected. The web renderer is covered by
// responsive_cloud_image_web_test.dart (run with --platform chrome).

const String _unsplash =
    'https://images.unsplash.com/photo-1504384308090-c894fdcc538d';

/// Pumps [child] in a 400x800 logical window with the given pixel ratio.
Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  double dpr = 2.0,
}) async {
  tester.view.devicePixelRatio = dpr;
  tester.view.physicalSize = Size(400 * dpr, 800 * dpr);
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Align(alignment: Alignment.topLeft, child: child),
      ),
    ),
  );

  // CachedNetworkImage starts a real cache and network lookup that cannot
  // succeed inside a widget test. We only assert on the arguments it was
  // built with, so discard any error reported by that lookup.
  tester.takeException();
}

CachedNetworkImage _image(WidgetTester tester) =>
    tester.widget<CachedNetworkImage>(find.byType(CachedNetworkImage));

Map<String, String> _query(String url) => Uri.parse(url).queryParameters;

void main() {
  group('defaults and assertions', () {
    test('provider is generic, fit is cover, sizeStep is 50', () {
      const widget = ResponsiveCloudImage(imageUrl: _unsplash);
      expect(widget.provider, CloudProvider.generic);
      expect(widget.fit, BoxFit.cover);
      expect(widget.alignment, Alignment.center);
      expect(widget.sizeStep, 50);
      expect(widget.maxDimension, isNull);
      expect(widget.customUrlBuilder, isNull);
      expect(widget.placeholder, isNull);
      expect(widget.errorWidget, isNull);
      expect(widget.httpHeaders, isNull);
      expect(widget.semanticLabel, isNull);
    });

    test('custom provider without a builder fails in debug mode', () {
      expect(
        () => ResponsiveCloudImage(
          imageUrl: _unsplash,
          provider: CloudProvider.custom,
        ),
        throwsAssertionError,
      );
    });

    test('sizeStep below 1 fails in debug mode', () {
      expect(
        () => ResponsiveCloudImage(imageUrl: _unsplash, sizeStep: 0),
        throwsAssertionError,
      );
    });
  });

  group('URL sizing', () {
    testWidgets('multiplies the logical size by the pixel ratio', (
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
        dpr: 3.0,
      );

      final image = _image(tester);
      final query = _query(image.imageUrl);
      expect(query['w'], '300');
      expect(query['h'], '300');
      expect(query['fit'], 'crop');
      // The widget itself is laid out in logical pixels.
      expect(image.width, 100);
      expect(image.height, 100);
    });

    testWidgets('pixel ratio 1 requests the logical size', (
      WidgetTester tester,
    ) async {
      await _pump(
        tester,
        const SizedBox(
          width: 100,
          height: 50,
          child: ResponsiveCloudImage(
            imageUrl: _unsplash,
            provider: CloudProvider.unsplash,
          ),
        ),
        dpr: 1.0,
      );

      final query = _query(_image(tester).imageUrl);
      expect(query['w'], '100');
      expect(query['h'], '50');
    });

    testWidgets('sizes are rounded up to the default step of 50', (
      WidgetTester tester,
    ) async {
      await _pump(
        tester,
        const SizedBox(
          width: 101,
          height: 101,
          child: ResponsiveCloudImage(
            imageUrl: _unsplash,
            provider: CloudProvider.unsplash,
          ),
        ),
        dpr: 1.0,
      );

      final query = _query(_image(tester).imageUrl);
      expect(query['w'], '150');
      expect(query['h'], '150');
    });

    testWidgets('sizeStep 1 requests the exact size', (
      WidgetTester tester,
    ) async {
      await _pump(
        tester,
        const SizedBox(
          width: 101,
          height: 101,
          child: ResponsiveCloudImage(
            imageUrl: _unsplash,
            provider: CloudProvider.unsplash,
            sizeStep: 1,
          ),
        ),
        dpr: 1.0,
      );

      final query = _query(_image(tester).imageUrl);
      expect(query['w'], '101');
      expect(query['h'], '101');
    });

    testWidgets('maxDimension caps the requested size', (
      WidgetTester tester,
    ) async {
      await _pump(
        tester,
        const SizedBox(
          width: 200,
          height: 100,
          child: ResponsiveCloudImage(
            imageUrl: _unsplash,
            provider: CloudProvider.unsplash,
            maxDimension: 200,
          ),
        ),
        dpr: 2.0,
      );

      // Physical size would be 400x200; the larger side is capped at 200.
      final query = _query(_image(tester).imageUrl);
      expect(query['w'], '200');
      expect(query['h'], '100');
    });

    testWidgets('generic provider passes the URL through unchanged', (
      WidgetTester tester,
    ) async {
      await _pump(
        tester,
        const SizedBox(
          width: 100,
          height: 100,
          child: ResponsiveCloudImage(imageUrl: _unsplash),
        ),
      );

      expect(_image(tester).imageUrl, _unsplash);
    });

    testWidgets('custom builder receives the physical size', (
      WidgetTester tester,
    ) async {
      double? seenWidth;
      double? seenHeight;

      await _pump(
        tester,
        SizedBox(
          width: 200,
          height: 100,
          child: ResponsiveCloudImage(
            imageUrl: _unsplash,
            provider: CloudProvider.custom,
            customUrlBuilder: (url, width, height) {
              seenWidth = width;
              seenHeight = height;
              return '$url?custom=${width.round()}x${height.round()}';
            },
          ),
        ),
      );

      expect(seenWidth, 400.0);
      expect(seenHeight, 200.0);
      expect(_image(tester).imageUrl, '$_unsplash?custom=400x200');
    });
  });

  group('fit and alignment', () {
    testWidgets('fit is forwarded to the image and selects the CDN mode', (
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
            fit: BoxFit.contain,
          ),
        ),
      );

      final image = _image(tester);
      expect(image.fit, BoxFit.contain);
      expect(_query(image.imageUrl)['fit'], 'clip');
    });

    testWidgets('alignment is forwarded to the image', (
      WidgetTester tester,
    ) async {
      await _pump(
        tester,
        const SizedBox(
          width: 100,
          height: 100,
          child: ResponsiveCloudImage(
            imageUrl: _unsplash,
            alignment: Alignment.topLeft,
          ),
        ),
      );

      expect(_image(tester).alignment, Alignment.topLeft);
    });
  });

  group('headers and semantics', () {
    testWidgets('httpHeaders are forwarded to the image request', (
      WidgetTester tester,
    ) async {
      await _pump(
        tester,
        const SizedBox(
          width: 100,
          height: 100,
          child: ResponsiveCloudImage(
            imageUrl: _unsplash,
            httpHeaders: <String, String>{'Authorization': 'Bearer token'},
          ),
        ),
      );

      expect(_image(tester).httpHeaders, <String, String>{
        'Authorization': 'Bearer token',
      });
    });

    testWidgets('semanticLabel wraps the image in a labelled Semantics', (
      WidgetTester tester,
    ) async {
      await _pump(
        tester,
        const SizedBox(
          width: 100,
          height: 100,
          child: ResponsiveCloudImage(
            imageUrl: _unsplash,
            semanticLabel: 'Product photo',
          ),
        ),
      );

      expect(
        find.byWidgetPredicate(
          (Widget w) => w is Semantics && w.properties.label == 'Product photo',
        ),
        findsOneWidget,
      );
    });
  });

  group('error fallback', () {
    // The errorWidget callback is invoked directly: a real load failure needs
    // a network, which a widget test does not have.
    testWidgets('retries the original URL, then shows the error widget', (
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

      final context = tester.element(find.byType(CachedNetworkImage));
      final first = _image(tester);
      expect(first.imageUrl, isNot(_unsplash));

      final retry = first.errorWidget!(context, first.imageUrl, Exception('x'));
      expect(retry, isA<CachedNetworkImage>());
      final second = retry as CachedNetworkImage;
      expect(second.imageUrl, _unsplash);

      final last = second.errorWidget!(
        context,
        second.imageUrl,
        Exception('x'),
      );
      expect(last, isA<Text>());
    });

    testWidgets('generic provider has nothing to retry', (
      WidgetTester tester,
    ) async {
      await _pump(
        tester,
        const SizedBox(
          width: 100,
          height: 100,
          child: ResponsiveCloudImage(
            imageUrl: _unsplash,
            errorWidget: Text('failed'),
          ),
        ),
      );

      final context = tester.element(find.byType(CachedNetworkImage));
      final image = _image(tester);
      final shown = image.errorWidget!(context, image.imageUrl, Exception('x'));
      expect(shown, isA<Text>());
    });

    testWidgets('default error icon is small, not as tall as the image', (
      WidgetTester tester,
    ) async {
      await _pump(
        tester,
        const SizedBox(
          width: 100,
          height: 700,
          child: ResponsiveCloudImage(imageUrl: _unsplash),
        ),
      );

      final context = tester.element(find.byType(CachedNetworkImage));
      final image = _image(tester);
      final shown = image.errorWidget!(context, image.imageUrl, Exception('x'));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: SizedBox(width: 100, height: 700, child: shown)),
        ),
      );
      final icon = tester.widget<Icon>(find.byType(Icon));
      expect(icon.size, lessThanOrEqualTo(48));
      expect(icon.size, greaterThanOrEqualTo(16));
    });
  });

  group('constraints', () {
    // Documented behaviour (see the class docs): with an unbounded height the
    // widget uses a 4:3 box derived from the width.
    testWidgets('unbounded height falls back to a 4:3 box', (
      WidgetTester tester,
    ) async {
      await _pump(
        tester,
        const SizedBox(
          width: 200,
          child: SingleChildScrollView(
            child: ResponsiveCloudImage(
              imageUrl: _unsplash,
              provider: CloudProvider.unsplash,
            ),
          ),
        ),
      );

      final image = _image(tester);
      final query = _query(image.imageUrl);
      expect(image.width, 200);
      expect(image.height, 150);
      expect(query['w'], '400');
      expect(query['h'], '300');
    });

    testWidgets('zero-size layout does not request any image', (
      WidgetTester tester,
    ) async {
      await _pump(
        tester,
        const SizedBox(
          width: 0,
          height: 0,
          child: ResponsiveCloudImage(
            imageUrl: _unsplash,
            provider: CloudProvider.unsplash,
          ),
        ),
      );

      expect(find.byType(CachedNetworkImage), findsNothing);
    });
  });
}
