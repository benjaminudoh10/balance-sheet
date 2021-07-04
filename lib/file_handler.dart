// import 'dart:io';

// import 'package:path_provider/path_provider.dart';
// import 'package:permission_handler/permission_handler.dart';

// class FileHandler {
//   static Future<String> getDirectoryPath() async {
//     Directory directory;
//     if (Platform.isAndroid) {
//       directory = await getExternalStorageDirectory();
//     } else {
//       directory = await getTemporaryDirectory();
//     }

//     return directory.path;
//   }

//   static createCsv(String filename, String csv) async {
//     bool granted = await requestPermission(Permission.storage);
//     print('granted $granted');
//     if (!granted) {
//       return;
//     }

//     String path = await getDirectoryPath();
//     print('directory is $path');

//     var csvFile = File('$path/$filename.csv');
//     if (await csvFile.exists()) {
//       await csvFile.writeAsString(csv, mode: FileMode.append);
//     } else {
//       await csvFile.writeAsString(csv);
//     }
//   }

//   static Future<bool> requestPermission(Permission permission) async {
//     if (await permission.isGranted) {
//       return true;
//     } else {
//       var result = await permission.request();
//       if (result == PermissionStatus.granted) {
//         return true;
//       }
//     }
//     return false;
//   }
// }
