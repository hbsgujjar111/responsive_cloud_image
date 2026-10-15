## 1.2.0

### Added

* `quality` (1-100): optional output quality requested from the CDN. It is sent as `quality` to
  Supabase (limited to the documented 20-100 range) and Appwrite, as `q` to Imgix, Unsplash and Sanity,
  and as `q_<value>` to Cloudinary. Shopify, `CloudProvider.custom` and `CloudProvider.generic`
  ignore it. When it is not set, nothing changes.
* `cacheKey`: a stable identity for the disk cache on native platforms, for images whose URL carries a
  changing part such as the token of a signed URL. The size, `fit` and `quality` are added to the key
  automatically, so different renditions never overwrite each other. The original-URL fallback gets its
  own key. Ignored on the web, where the browser caches by URL.
* `CloudUrlAdapter.buildUrl` accepts the same `quality` argument.

### Notes

* Nothing changes for existing code: both new parameters are optional and default to `null`.

## 1.1.0

### Fixed

* Allow `cached_network_image` 3.4.1 up to (but not including) 5.0.0, so apps already on 4.x can install
  this package. This also restores the full pub.dev dependency score.
* The original `imageUrl` is now tried once when the optimized image fails to load, as the README always
  promised, before `errorWidget` is shown. Previously the fallback URL was passed around but never used.
* A zero-size layout (for example the first frame of an expand animation) no longer downloads the
  full-size original. Nothing is requested until the box has an area.
* `CloudUrlAdapter.buildUrl` no longer throws on `NaN`, infinite or malformed input, and a throwing
  `customUrlBuilder` is reported through `FlutterError.reportError` and falls back to the original URL
  instead of crashing the build.
* Requested sizes are capped: 2500 px for Supabase, 4000 px for Appwrite and 4096 px otherwise
  (the aspect ratio is kept). Large widgets on high-density screens no longer ask for sizes the
  provider rejects.
* `fit` is respected. `BoxFit.contain`, `scaleDown`, `fill`, `fitWidth` and `fitHeight` now select the
  matching crop or resize mode of each provider instead of always requesting a cropped image.
  `BoxFit.none` skips URL optimization.
* Supabase: signed and authenticated URLs are returned unchanged (their parameters are ignored by the
  server), and only the first `/object/public/` is rewritten.
* Appwrite: sends the documented `gravity` parameter instead of `crop`.
* Shopify: an existing `_WxH` suffix is replaced instead of stacked.
* Repeated query parameters are preserved for the query-string providers.
* The default error icon no longer scales with the full image height, and the default placeholder now
  follows the app theme instead of a fixed dark colour.

### Added

* `sizeStep` (default 50): requested sizes are rounded up to a multiple of this value, so resizing or
  animating a widget reuses cached images instead of requesting a new URL every frame. Use `1` for the
  exact size.
* `maxDimension`: optional cap for the larger side of the request.
* `httpHeaders`: headers sent with every image request, for example for private buckets.
* `alignment` and `semanticLabel`.
* `CloudUrlAdapter.buildUrl` accepts `fit`, `sizeStep` and `maxDimension`.
* Debug assertions for `provider: custom` without a `customUrlBuilder`, `sizeStep < 1` and
  `maxDimension <= 0`.
* Unit and widget tests, including a Chrome test for the web renderer.
* `topics` and `screenshots` in `pubspec.yaml`.

### Changed

* The minimum SDK is now Dart 3.8 / Flutter 3.32 (was Dart 3.11.5 and a placeholder Flutter constraint).
* Requested sizes are now rounded up to the next multiple of `sizeStep` (default 50), so URLs differ
  from 1.0.x. Set `sizeStep: 1` for the old exact sizes.
* `customUrlBuilder` now receives the final whole-pixel size (after rounding and capping).
* Internal restructure: `cloud_providers.dart` is split into `cloud_provider.dart`,
  `cloud_url_adapter.dart` and one file per provider under `providers/`. The public API is unchanged.
* The example app's Android main manifest and macOS entitlements now allow network access.

## 1.0.2

* Added complete public API documentation (Dartdoc comments) across all exported libraries, widgets,
  classes, and enum values.
* Optimized the public API footprint by making the `CloudUrlAdapter` constructor private.
* Resolved all static analysis warnings regarding API documentation coverage.

## 1.0.1

* Fixed platform compatibility analyzer warnings.
* Restored full 100% WASM compatibility.
* Added conditional compilation for Web, Mobile, and Desktop targets.

## 1.0.0

* Initial release