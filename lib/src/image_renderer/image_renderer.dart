/// Conditional export router for platform-specific image rendering.
///
/// This library selects the appropriate image renderer (Native vs. Web/WASM)
/// based on the compilation environment flags.
library;

export 'image_renderer_stub.dart'
    if (dart.library.io) 'image_renderer_native.dart'
    if (dart.library.js_interop) 'image_renderer_web.dart';
