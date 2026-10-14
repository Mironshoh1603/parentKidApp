/// Cloudinary sozlamalari — OSHKORA rasm (SOS / check-in) yuklash uchun.
///
/// Bular MAXFIY EMAS: `cloudName` va `unsignedPreset` mijoz ilovasida ochiq
/// bo'ladi (imzosiz yuklash shunga mo'ljallangan). Shuning uchun repo'ga
/// qo'yish xavfsiz. Lekin faqat IMZOSIZ (unsigned) presetdan foydalaning va
/// Cloudinard'da preset uchun papka + hajm cheklovini yoqing.
///
/// Sozlash (bir marta):
///  1. https://cloudinary.com — bepul akkaunt oching.
///  2. Dashboard → "Cloud name" ni `cloudName` ga yozing.
///  3. Settings → Upload → "Add upload preset" → Signing Mode = **Unsigned** →
///     preset nomini `unsignedPreset` ga yozing.
///  4. (Tavsiya) presetga "Folder" (masalan `family_safety`) va format/hajm
///     cheklovlarini qo'ying.
class CloudinaryConfig {
  /// Cloudinary "Cloud name" (Dashboard'da ko'rsatilgan).
  static const String cloudName = 'YOUR_CLOUD_NAME';

  /// Imzosiz (unsigned) upload preset nomi.
  static const String unsignedPreset = 'YOUR_UNSIGNED_PRESET';

  /// Sozlanganmi? (placeholder qoldirilmaganmi)
  static bool get isConfigured =>
      cloudName != 'YOUR_CLOUD_NAME' &&
      unsignedPreset != 'YOUR_UNSIGNED_PRESET' &&
      cloudName.isNotEmpty &&
      unsignedPreset.isNotEmpty;

  static Uri get uploadUri =>
      Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');
}
