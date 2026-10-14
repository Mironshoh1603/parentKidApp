/// Firestore va Realtime Database yo'llari — parentApp bilan BIR XIL bo'lishi shart.
/// (Ikkala ilovada nusxasi bor; o'zgartirganda ikkalasini ham yangilang.)
class FsPaths {
  static String family(String familyId) => 'families/$familyId';

  static String children(String familyId) => 'families/$familyId/children';
  static String child(String familyId, String childId) =>
      'families/$familyId/children/$childId';

  static String locations(String familyId, String childId) =>
      'families/$familyId/children/$childId/locations';

  static String geofences(String familyId) => 'families/$familyId/geofences';
  static String alerts(String familyId) => 'families/$familyId/alerts';

  static String commands(String familyId, String childId) =>
      'families/$familyId/children/$childId/commands';
  static String photos(String familyId, String childId) =>
      'families/$familyId/children/$childId/photos';

  /// Realtime Database — jonli joylashuv.
  static String liveLocation(String childId) => 'live/$childId';
}
