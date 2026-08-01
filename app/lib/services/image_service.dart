import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';

/// Image helper that hides web/mobile differences.
///
/// On web, XFile bytes are read via `readAsBytes` and converted to a data URL
/// so it can be stored as a string and displayed via `Image.network(dataUrl)`.
class ImageService {
  final ImagePicker _picker;
  ImageService({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  /// Maximum bytes we'll keep around. Beyond this, return null to avoid
  /// blowing past browser localStorage quotas.
  static const int maxBytes = 1_500_000; // ~1.5MB

  Future<String?> pickAsDataUrl({ImageSource source = ImageSource.gallery}) async {
    try {
      final x = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 78,
      );
      if (x == null) return null;
      final bytes = await x.readAsBytes();
      if (bytes.length > maxBytes) {
        // Best-effort downsize once more.
        final smaller = await _picker.pickImage(
          source: source,
          maxWidth: 1200,
          maxHeight: 1200,
          imageQuality: 60,
        );
        if (smaller == null) return null;
        final b2 = await smaller.readAsBytes();
        return _toDataUrl(b2);
      }
      return _toDataUrl(bytes);
    } catch (e) {
      return null;
    }
  }

  String _toDataUrl(Uint8List bytes) {
    final b64 = base64Encode(bytes);
    return 'data:image/jpeg;base64,$b64';
  }

  bool get isWeb => kIsWeb;
}
