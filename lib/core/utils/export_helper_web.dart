import 'dart:developer' as developer;
import 'dart:js_interop';
import 'dart:typed_data';
import 'package:web/web.dart';

void downloadImage(Uint8List bytes, String filename, String mimeType) {
  developer.log('downloadImage(web) triggered for $filename', name: 'export_helper_web');
  // Create Blob from Uint8List using package:web directly
  // Convert Dart Uint8List to JavaScript Uint8Array
  final jsArray = bytes.toJS;
  final blob = Blob([jsArray].toJS, BlobPropertyBag(type: mimeType));
  final url = URL.createObjectURL(blob);
  HTMLAnchorElement()
    ..download = filename
    ..href = url
    ..click();
  URL.revokeObjectURL(url);
}
