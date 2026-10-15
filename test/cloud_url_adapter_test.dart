import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:responsive_cloud_image/responsive_cloud_image.dart';

/// Builds a URL with default sizes so each test only states what it cares about.
String _build(
  String url,
  CloudProvider provider, {
  double width = 300,
  double height = 200,
  BoxFit fit = BoxFit.cover,
  int sizeStep = 1,
  int? maxDimension,
  int? quality,
  String? Function(String url, double width, double height)? custom,
}) {
  return CloudUrlAdapter.buildUrl(
    originalUrl: url,
    provider: provider,
    width: width,
    height: height,
    fit: fit,
    sizeStep: sizeStep,
    maxDimension: maxDimension,
    quality: quality,
    customBuilder: custom,
  );
}

const String _supabase =
    'https://abc.supabase.co/storage/v1/object/public/images/car.png';
const String _appwrite =
    'https://cloud.appwrite.io/v1/storage/buckets/b1/files/f1/preview?project=p1';
const String _cloudinary =
    'https://res.cloudinary.com/demo/image/upload/sample.jpg';
const String _shopify =
    'https://cdn.shopify.com/s/files/1/0001/products/shoe.jpg?v=123';

/// Providers that use Imgix-style `w`, `h` and `fit` query parameters.
const Map<CloudProvider, String> _queryStyle = <CloudProvider, String>{
  CloudProvider.unsplash:
      'https://images.unsplash.com/photo-1504384308090-c894fdcc538d',
  CloudProvider.imgix: 'https://assets.imgix.net/examples/bridge.jpg',
  CloudProvider.sanity:
      'https://cdn.sanity.io/images/zp7mbokg/production/G3i4emG6B8JnTmGoN0UjgAp8-300x450.jpg',
};

Map<String, String> _query(String url) => Uri.parse(url).queryParameters;

void main() {
  group('guards and API surface', () {
    test('CloudProvider keeps its 9 documented values', () {
      // Adding or removing a value is a public API change (it can break
      // exhaustive switches in user code). Update this test on purpose.
      expect(CloudProvider.values, hasLength(9));
    });

    test('non-positive width returns the original URL', () {
      const url = 'https://images.unsplash.com/photo-1';
      expect(_build(url, CloudProvider.unsplash, width: 0), url);
      expect(_build(url, CloudProvider.unsplash, width: -10), url);
    });

    test('non-positive height returns the original URL', () {
      const url = 'https://images.unsplash.com/photo-1';
      expect(_build(url, CloudProvider.unsplash, height: 0), url);
      expect(_build(url, CloudProvider.unsplash, height: -1), url);
    });

    test('NaN width returns the original URL', () {
      expect(
        _build(_supabase, CloudProvider.supabase, width: double.nan),
        _supabase,
      );
    });

    test('infinite height returns the original URL', () {
      expect(
        _build(_supabase, CloudProvider.supabase, height: double.infinity),
        _supabase,
      );
    });

    test('generic returns the original URL untouched', () {
      expect(_build(_supabase, CloudProvider.generic), _supabase);
    });

    test('BoxFit.none returns the original URL', () {
      final url = _queryStyle[CloudProvider.unsplash]!;
      expect(_build(url, CloudProvider.unsplash, fit: BoxFit.none), url);
    });

    test('empty URL is returned as is', () {
      expect(_build('', CloudProvider.unsplash), '');
    });

    test('malformed URL returns the original instead of throwing', () {
      // An invalid port makes Uri.parse throw a FormatException.
      const url = 'http://host:abc/x.png';
      expect(_build(url, CloudProvider.unsplash), url);
    });

    test('sizes are rounded to whole pixels', () {
      final query = _query(
        _build(
          _queryStyle[CloudProvider.unsplash]!,
          CloudProvider.unsplash,
          width: 299.5,
          height: 199.4,
        ),
      );
      expect(query['w'], '300');
      expect(query['h'], '199');
    });
  });

  group('size step and caps', () {
    final url = _queryStyle[CloudProvider.unsplash]!;

    test('sizeStep rounds each side up to a multiple of the step', () {
      final query = _query(
        _build(
          url,
          CloudProvider.unsplash,
          width: 301.2,
          height: 199.6,
          sizeStep: 50,
        ),
      );
      expect(query['w'], '350');
      expect(query['h'], '200');
    });

    test('exact multiples of the step are unchanged', () {
      final query = _query(_build(url, CloudProvider.unsplash, sizeStep: 50));
      expect(query['w'], '300');
      expect(query['h'], '200');
    });

    test('maxDimension scales both sides down and keeps the aspect ratio', () {
      final query = _query(
        _build(
          url,
          CloudProvider.unsplash,
          width: 1000,
          height: 500,
          maxDimension: 500,
        ),
      );
      expect(query['w'], '500');
      expect(query['h'], '250');
    });

    test('providers without a documented limit are capped at 4096', () {
      final query = _query(
        _build(url, CloudProvider.unsplash, width: 8192, height: 4096),
      );
      expect(query['w'], '4096');
      expect(query['h'], '2048');
    });

    test('supabase never requests more than 2500 px', () {
      final query = _query(
        _build(_supabase, CloudProvider.supabase, width: 5000, height: 4000),
      );
      expect(int.parse(query['width']!), lessThanOrEqualTo(2500));
      expect(int.parse(query['height']!), lessThanOrEqualTo(2500));
    });

    test('appwrite never requests more than 4000 px', () {
      final query = _query(
        _build(_appwrite, CloudProvider.appwrite, width: 9000, height: 9000),
      );
      expect(int.parse(query['width']!), lessThanOrEqualTo(4000));
      expect(int.parse(query['height']!), lessThanOrEqualTo(4000));
    });
  });

  group('query-style providers (unsplash, imgix, sanity)', () {
    _queryStyle.forEach((provider, url) {
      final name = provider.name;

      test('$name: cover adds w, h, fit=crop; host and path unchanged', () {
        final result = Uri.parse(_build(url, provider));
        final original = Uri.parse(url);
        expect(result.host, original.host);
        expect(result.path, original.path);
        expect(result.queryParameters, <String, String>{
          'w': '300',
          'h': '200',
          'fit': 'crop',
        });
      });

      test('$name: keeps existing params and overrides w', () {
        final query = _query(_build('$url?auto=format&w=9999', provider));
        expect(query['auto'], 'format');
        expect(query['w'], '300');
        expect(query['h'], '200');
      });

      test('$name: keeps repeated query keys', () {
        final result = Uri.parse(_build('$url?tag=a&tag=b', provider));
        expect(result.queryParametersAll['tag'], <String>['a', 'b']);
      });

      test('$name: contain, scaleDown and fill map to clip, max, scale', () {
        expect(
          _query(_build(url, provider, fit: BoxFit.contain)),
          <String, String>{'w': '300', 'h': '200', 'fit': 'clip'},
        );
        expect(
          _query(_build(url, provider, fit: BoxFit.scaleDown))['fit'],
          'max',
        );
        expect(_query(_build(url, provider, fit: BoxFit.fill))['fit'], 'scale');
      });

      test('$name: fitWidth sends only w, fitHeight sends only h', () {
        expect(
          _query(_build(url, provider, fit: BoxFit.fitWidth)),
          <String, String>{'w': '300'},
        );
        expect(
          _query(_build(url, provider, fit: BoxFit.fitHeight)),
          <String, String>{'h': '200'},
        );
      });

      test('$name: fitWidth drops a stale h from the original URL', () {
        final query = _query(
          _build('$url?h=100', provider, fit: BoxFit.fitWidth),
        );
        expect(query, <String, String>{'w': '300'});
      });
    });
  });

  group('supabase', () {
    test('rewrites /object/public/ to /render/image/public/', () {
      final result = Uri.parse(_build(_supabase, CloudProvider.supabase));
      expect(result.host, 'abc.supabase.co');
      expect(result.path, '/storage/v1/render/image/public/images/car.png');
      expect(result.queryParameters, <String, String>{
        'width': '300',
        'height': '200',
        'resize': 'cover',
      });
    });

    test('keeps existing query parameters', () {
      final query = _query(
        _build('$_supabase?download=1', CloudProvider.supabase),
      );
      expect(query['download'], '1');
      expect(query['width'], '300');
    });

    test('leaves an already-rewritten /render/image/ path alone', () {
      const url =
          'https://abc.supabase.co/storage/v1/render/image/public/images/car.png';
      final result = Uri.parse(_build(url, CloudProvider.supabase));
      expect(result.path, Uri.parse(url).path);
      expect(result.queryParameters['width'], '300');
    });

    test('only the first /object/public/ is rewritten', () {
      final result = Uri.parse(
        _build(
          'https://abc.supabase.co/storage/v1/object/public/a/object/public/b.png',
          CloudProvider.supabase,
        ),
      );
      expect(
        result.path,
        '/storage/v1/render/image/public/a/object/public/b.png',
      );
    });

    test('signed URLs are returned unchanged', () {
      const url =
          'https://abc.supabase.co/storage/v1/object/sign/images/car.png?token=t';
      expect(_build(url, CloudProvider.supabase), url);
    });

    test('authenticated URLs are returned unchanged', () {
      const url =
          'https://abc.supabase.co/storage/v1/object/authenticated/images/car.png';
      expect(_build(url, CloudProvider.supabase), url);
    });

    test('fit maps to the resize parameter', () {
      String? resize(BoxFit fit) =>
          _query(_build(_supabase, CloudProvider.supabase, fit: fit))['resize'];
      expect(resize(BoxFit.cover), 'cover');
      expect(resize(BoxFit.contain), 'contain');
      expect(resize(BoxFit.scaleDown), 'contain');
      expect(resize(BoxFit.fill), 'fill');
    });

    test('fitWidth and fitHeight send a single dimension', () {
      expect(
        _query(_build(_supabase, CloudProvider.supabase, fit: BoxFit.fitWidth)),
        <String, String>{'width': '300'},
      );
      expect(
        _query(
          _build(_supabase, CloudProvider.supabase, fit: BoxFit.fitHeight),
        ),
        <String, String>{'height': '200'},
      );
    });
  });

  group('appwrite', () {
    test('cover keeps the project param and sends width, height, gravity', () {
      final result = Uri.parse(_build(_appwrite, CloudProvider.appwrite));
      expect(result.path, Uri.parse(_appwrite).path);
      expect(result.queryParameters, <String, String>{
        'project': 'p1',
        'width': '300',
        'height': '200',
        'gravity': 'center',
      });
    });

    test('keeps a gravity that is already in the URL', () {
      final query = _query(
        _build('$_appwrite&gravity=top', CloudProvider.appwrite),
      );
      expect(query['gravity'], 'top');
    });

    test('contain and scaleDown send only the width (no cropping)', () {
      for (final fit in <BoxFit>[BoxFit.contain, BoxFit.scaleDown]) {
        expect(
          _query(_build(_appwrite, CloudProvider.appwrite, fit: fit)),
          <String, String>{'project': 'p1', 'width': '300'},
        );
      }
    });

    test('fitHeight sends only the height', () {
      expect(
        _query(
          _build(_appwrite, CloudProvider.appwrite, fit: BoxFit.fitHeight),
        ),
        <String, String>{'project': 'p1', 'height': '200'},
      );
    });
  });

  group('cloudinary', () {
    List<String> segments(BoxFit fit) => Uri.parse(
      _build(_cloudinary, CloudProvider.cloudinary, fit: fit),
    ).pathSegments;

    test('cover inserts c_fill right after /upload/', () {
      expect(segments(BoxFit.cover), <String>[
        'demo',
        'image',
        'upload',
        'w_300,h_200,c_fill',
        'sample.jpg',
      ]);
    });

    test('fit maps to the crop mode', () {
      expect(segments(BoxFit.contain)[3], 'w_300,h_200,c_fit');
      expect(segments(BoxFit.scaleDown)[3], 'w_300,h_200,c_limit');
      expect(segments(BoxFit.fill)[3], 'w_300,h_200,c_scale');
      expect(segments(BoxFit.fitWidth)[3], 'w_300,c_scale');
      expect(segments(BoxFit.fitHeight)[3], 'h_200,c_scale');
    });

    test('keeps version and folder segments after the transformation', () {
      final result = Uri.parse(
        _build(
          'https://res.cloudinary.com/demo/image/upload/v1234/folder/sample.jpg',
          CloudProvider.cloudinary,
        ),
      );
      expect(result.pathSegments, <String>[
        'demo',
        'image',
        'upload',
        'w_300,h_200,c_fill',
        'v1234',
        'folder',
        'sample.jpg',
      ]);
    });

    test('keeps the query string', () {
      final query = _query(
        _build('$_cloudinary?_a=abc', CloudProvider.cloudinary),
      );
      expect(query['_a'], 'abc');
    });

    test(
      'URL without an /upload/ segment is left equivalent to the original',
      () {
        const url = 'https://example.com/a/b.jpg';
        expect(
          Uri.parse(_build(url, CloudProvider.cloudinary)),
          Uri.parse(url),
        );
      },
    );
  });

  group('shopify', () {
    test('adds _WxH before the extension and keeps the query', () {
      final result = Uri.parse(_build(_shopify, CloudProvider.shopify));
      expect(result.pathSegments.last, 'shoe_300x200.jpg');
      expect(
        result.pathSegments.sublist(0, result.pathSegments.length - 1),
        <String>['s', 'files', '1', '0001', 'products'],
      );
      expect(result.queryParameters, <String, String>{'v': '123'});
    });

    test('fitWidth uses _Wx and fitHeight uses _xH', () {
      String last(BoxFit fit) => Uri.parse(
        _build(_shopify, CloudProvider.shopify, fit: fit),
      ).pathSegments.last;
      expect(last(BoxFit.fitWidth), 'shoe_300x.jpg');
      expect(last(BoxFit.fitHeight), 'shoe_x200.jpg');
    });

    test('uses the last dot as the extension separator', () {
      final result = Uri.parse(
        _build(
          'https://cdn.shopify.com/s/files/my.shoe.v2.jpg',
          CloudProvider.shopify,
        ),
      );
      expect(result.pathSegments.last, 'my.shoe.v2_300x200.jpg');
    });

    test('file name without an extension returns the original string', () {
      const url = 'https://cdn.shopify.com/s/files/shoe';
      expect(_build(url, CloudProvider.shopify), url);
    });

    test('URL with no path returns the original string', () {
      const url = 'https://cdn.shopify.com';
      expect(_build(url, CloudProvider.shopify), url);
    });
  });

  group('custom', () {
    test(
      'builder receives the original URL and the final whole-pixel size',
      () {
        String? seenUrl;
        double? seenWidth;
        double? seenHeight;
        _build(
          _supabase,
          CloudProvider.custom,
          width: 300.4,
          height: 200.6,
          custom: (url, width, height) {
            seenUrl = url;
            seenWidth = width;
            seenHeight = height;
            return 'x';
          },
        );
        expect(seenUrl, _supabase);
        expect(seenWidth, 300.0);
        expect(seenHeight, 201.0);
      },
    );

    test('builder size follows sizeStep and maxDimension', () {
      double? seenWidth;
      double? seenHeight;
      _build(
        _supabase,
        CloudProvider.custom,
        width: 1000,
        height: 500,
        maxDimension: 500,
        custom: (url, width, height) {
          seenWidth = width;
          seenHeight = height;
          return null;
        },
      );
      expect(seenWidth, 500.0);
      expect(seenHeight, 250.0);
    });

    test('builder result is returned as is', () {
      final result = _build(
        _supabase,
        CloudProvider.custom,
        custom: (url, width, height) =>
            'https://cdn.example.com/${width.round()}',
      );
      expect(result, 'https://cdn.example.com/300');
    });

    test('builder returning null falls back to the original URL', () {
      expect(
        _build(_supabase, CloudProvider.custom, custom: (_, _, _) => null),
        _supabase,
      );
    });

    test('missing builder falls back to the original URL', () {
      expect(_build(_supabase, CloudProvider.custom), _supabase);
    });

    test(
      'a throwing builder is reported and falls back to the original URL',
      () {
        final reported = <FlutterErrorDetails>[];
        final previous = FlutterError.onError;
        FlutterError.onError = reported.add;
        addTearDown(() => FlutterError.onError = previous);

        final result = _build(
          _supabase,
          CloudProvider.custom,
          custom: (_, _, _) => throw StateError('boom'),
        );

        expect(result, _supabase);
        expect(reported, hasLength(1));
        expect(reported.single.exception, isA<StateError>());
      },
    );
  });

  group('quality', () {
    _queryStyle.forEach((provider, url) {
      test('${provider.name}: quality is sent as q', () {
        expect(_query(_build(url, provider, quality: 80))['q'], '80');
      });
    });

    test('no quality means no quality parameter on any provider', () {
      for (final provider in CloudProvider.values) {
        final url = switch (provider) {
          CloudProvider.supabase => _supabase,
          CloudProvider.appwrite => _appwrite,
          CloudProvider.cloudinary => _cloudinary,
          CloudProvider.shopify => _shopify,
          _ => _queryStyle[provider] ?? _queryStyle.values.first,
        };
        final result = _build(url, provider, custom: (u, w, h) => u);
        expect(result, isNot(contains('quality')), reason: provider.name);
        expect(result, isNot(contains('q=')), reason: provider.name);
        expect(result, isNot(contains('q_')), reason: provider.name);
      }
    });

    test('supabase: quality is sent and limited to 20-100', () {
      expect(
        _query(
          _build(_supabase, CloudProvider.supabase, quality: 80),
        )['quality'],
        '80',
      );
      expect(
        _query(
          _build(_supabase, CloudProvider.supabase, quality: 5),
        )['quality'],
        '20',
      );
      expect(
        _query(
          _build(_supabase, CloudProvider.supabase, quality: 150),
        )['quality'],
        '100',
      );
    });

    test('appwrite: quality is sent and the project parameter is kept', () {
      final query = _query(
        _build(_appwrite, CloudProvider.appwrite, quality: 70),
      );
      expect(query['quality'], '70');
      expect(query['project'], 'p1');
    });

    test('cloudinary: quality is appended to the transformation', () {
      final result = _build(_cloudinary, CloudProvider.cloudinary, quality: 70);
      expect(
        result,
        'https://res.cloudinary.com/demo/image/upload/w_300,h_200,c_fill,q_70/sample.jpg',
      );
    });

    test('shopify and generic ignore quality', () {
      expect(
        _build(_shopify, CloudProvider.shopify, quality: 70),
        _build(_shopify, CloudProvider.shopify),
      );
      expect(
        _build(
          _queryStyle[CloudProvider.unsplash]!,
          CloudProvider.generic,
          quality: 70,
        ),
        _queryStyle[CloudProvider.unsplash]!,
      );
    });

    test('out-of-range quality is limited to 1-100', () {
      final url = _queryStyle[CloudProvider.imgix]!;
      expect(_query(_build(url, CloudProvider.imgix, quality: 0))['q'], '1');
      expect(
        _query(_build(url, CloudProvider.imgix, quality: 500))['q'],
        '100',
      );
    });

    test('quality overrides a q already in the URL', () {
      final url = '${_queryStyle[CloudProvider.imgix]!}?q=10';
      expect(_query(_build(url, CloudProvider.imgix, quality: 90))['q'], '90');
    });
  });
}
