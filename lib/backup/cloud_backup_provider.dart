/// Interface for cloud-based backup providers to be used by [BackupService].
abstract class CloudBackupProvider {
  /// Unique identifier for the provider (e.g., 'google_drive', 'dropbox').
  String get id;

  /// Returns whether the provider is authenticated and ready to use.
  Future<bool> isAuthenticated();

  /// Initiates the authentication flow for the user.
  Future<bool> authenticate();

  /// Uploads the provided bytes to the cloud storage.
  /// [fileName] is the name of the file to store.
  /// [data] is the content to upload.
  Future<bool> upload(String fileName, List<int> data);

  /// Downloads the specified file bytes from the cloud storage.
  Future<List<int>?> download(String fileName);

  /// Revokes access and clears local authentication state.
  Future<void> signOut();
}
