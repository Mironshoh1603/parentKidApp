import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../core/cloudinary_config.dart';

/// Cloudinary'ga IMZOSIZ (unsigned) rasm yuklash.
class CloudinaryService {
  /// Rasmni yuklaydi va `secure_url` ni qaytaradi. Xato bo'lsa `null`.
  Future<String?> uploadImage(File file) async {
    if (!CloudinaryConfig.isConfigured) {
      throw StateError(
          'Cloudinary sozlanmagan — cloudinary_config.dart ni to\'ldiring');
    }
    final req = http.MultipartRequest('POST', CloudinaryConfig.uploadUri)
      ..fields['upload_preset'] = CloudinaryConfig.unsignedPreset
      ..files.add(await http.MultipartFile.fromPath('file', file.path));

    final streamed = await req.send();
    final res = await http.Response.fromStream(streamed);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      return json['secure_url'] as String?;
    }
    return null;
  }
}
