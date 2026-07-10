// Uses dart.library.js_interop as officially recommended for WASM compatibility
export 'image_renderer_stub.dart'
    if (dart.library.io) 'image_renderer_native.dart'
    if (dart.library.js_interop) 'image_renderer_web.dart';
