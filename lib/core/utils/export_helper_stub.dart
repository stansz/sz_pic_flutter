import 'dart:typed_data';

void downloadImage(Uint8List bytes, String filename, String mimeType) {
  // Stub implementation for non-web platforms. Should never be called without guarding kIsWeb.
  throw UnsupportedError('downloadImage is not supported on this platform');
}
