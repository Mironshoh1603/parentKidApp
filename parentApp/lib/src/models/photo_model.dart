import 'package:cloud_firestore/cloud_firestore.dart';

/// Oshkora rasm — `families/{fid}/children/{cid}/photos/{id}`.
class PhotoModel {
  final String id;
  final String url; // Cloudinary URL
  final String source; // 'sos' | 'checkin'
  final DateTime createdAt;

  const PhotoModel({
    required this.id,
    required this.url,
    this.source = 'checkin',
    required this.createdAt,
  });

  factory PhotoModel.fromMap(String id, Map<String, dynamic> m) => PhotoModel(
        id: id,
        url: (m['url'] ?? '') as String,
        source: (m['source'] ?? 'checkin') as String,
        createdAt: (m['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );
}
