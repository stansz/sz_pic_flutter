import 'dart:developer' as developer;
import 'dart:typed_data';
import 'package:web/web.dart';

void downloadImage(Uint8List bytes, String filename, String mimeType) {
  developer.log('downloadImage(web) triggered for $filename', name: 'export_helper_web');
  // Create Blob from Uint8List using package:web directly
  final blob = Blob(<BlobPart>[bytes], BlobPropertyBag(type: mimeType));
  final url = URL.createObjectURL(blob);
  HTMLAnchorElement()
    ..download = filename
    ..href = url
    ..click();
  URL.revokeObjectURL(url);
}
