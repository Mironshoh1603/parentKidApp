import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/firestore_paths.dart';
import 'cloudinary_service.dart';

enum PhotoUploadStatus { ok, notConfigured, noAuth, uploadFailed, error }

class PhotoUploadResult {
  final PhotoUploadStatus status;
  final String? url;
  const PhotoUploadResult(this.status, [this.url]);
  bool get ok => status == PhotoUploadStatus.ok;
}

/// OSHKORA rasm yuborish: Cloudinary'ga yuklaydi, so'ng `photos` kolleksiyasiga
/// yozadi. Bola rasm olinayotganini va yuborilayotganini KO'RADI.
class PhotoService {
  final FirebaseFirestore _db;
  final CloudinaryService _cloudinary;

  PhotoService(this._db, this._cloudinary);

  /// [source] — 'checkin' yoki 'sos'.
  Future<PhotoUploadResult> sendPhoto(File file, {String source = 'checkin'}) async {
    if (FirebaseAuth.instance.currentUser == null) {
      return const PhotoUploadResult(PhotoUploadStatus.noAuth);
    }
    final prefs = await SharedPreferences.getInstance();
    final familyId = prefs.getString('familyId');
    final childId = prefs.getString('childId');
    if (familyId == null || childId == null) {
      return const PhotoUploadResult(PhotoUploadStatus.noAuth);
    }

    try {
      final url = await _cloudinary.uploadImage(file);
      if (url == null) {
        return const PhotoUploadResult(PhotoUploadStatus.uploadFailed);
      }
      await _db.collection(FsPaths.photos(familyId, childId)).add({
        'url': url,
        'source': source,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return PhotoUploadResult(PhotoUploadStatus.ok, url);
    } on StateError {
      return const PhotoUploadResult(PhotoUploadStatus.notConfigured);
    } catch (_) {
      return const PhotoUploadResult(PhotoUploadStatus.error);
    }
  }
}
