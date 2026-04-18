/// Logical JSON backup ([BackupService]) — bump [formatVersion] when the payload shape changes.
///
/// v5: optional top-level `savedViews` (same map as GetStorage key `saved_views_v1`).
class BackupConstants {
  static const String formatId = 'balanced_backup';
  static const int formatVersion = 5;
}
