import 'package:balance_sheet/backup/cloud_backup_provider.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;

class GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  GoogleAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _client.send(request);
  }
}

/// Google Drive implementation of [CloudBackupProvider].
class GoogleDriveProvider implements CloudBackupProvider {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: <String>[drive.DriveApi.driveFileScope],
  );

  @override
  String get id => 'google_drive';

  @override
  Future<bool> isAuthenticated() async => await _googleSignIn.isSignedIn();

  @override
  Future<bool> authenticate() async => (await _googleSignIn.signIn()) != null;

  @override
  Future<bool> upload(String fileName, List<int> data) async {
    final GoogleSignInAccount? account =
        _googleSignIn.currentUser ?? await _googleSignIn.signInSilently();
    if (account == null) return false;

    final authHeaders = await account.authHeaders;
    final authenticateClient = GoogleAuthClient(authHeaders);
    final driveApi = drive.DriveApi(authenticateClient);

    final files =
        await driveApi.files.list(q: "name = '$fileName' and trashed = false");
    if (files.files != null && files.files!.isNotEmpty) {
      final fileId = files.files!.first.id!;
      await driveApi.files.update(
        drive.File(),
        fileId,
        uploadMedia: drive.Media(Stream.value(data), data.length),
      );
    } else {
      await driveApi.files.create(
        drive.File(name: fileName),
        uploadMedia: drive.Media(Stream.value(data), data.length),
      );
    }
    return true;
  }

  @override
  Future<List<int>?> download(String fileName) async {
    final GoogleSignInAccount? account =
        _googleSignIn.currentUser ?? await _googleSignIn.signInSilently();
    if (account == null) return null;

    final authHeaders = await account.authHeaders;
    final authenticateClient = GoogleAuthClient(authHeaders);
    final driveApi = drive.DriveApi(authenticateClient);

    final files =
        await driveApi.files.list(q: "name = '$fileName' and trashed = false");
    if (files.files == null || files.files!.isEmpty) return null;

    final fileId = files.files!.first.id!;
    final drive.Media media = await driveApi.files.get(
      fileId,
      downloadOptions: drive.DownloadOptions.fullMedia,
    ) as drive.Media;

    final List<int> data = [];
    await for (final chunk in media.stream) {
      data.addAll(chunk);
    }
    return data;
  }

  @override
  Future<void> signOut() async => await _googleSignIn.signOut();
}
