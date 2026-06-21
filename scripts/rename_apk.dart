import 'dart:io';

String _readVersion() {
  final pubspec = File('pubspec.yaml');
  if (!pubspec.existsSync()) {
    throw Exception('pubspec.yaml not found');
  }
  final lines = pubspec.readAsLinesSync();
  for (final line in lines) {
    if (line.trim().startsWith('version:')) {
      final parts = line.split(':');
      if (parts.length > 1) {
        final versionPart = parts[1].trim();
        // Return without build number, e.g. "1.0.0+1" -> "1.0.0"
        return versionPart.split('+').first;
      }
    }
  }
  return '1.0.0';
}

String _timestamp() {
  final now = DateTime.now();
  final year = now.year.toString();
  final month = now.month.toString().padLeft(2, '0');
  final day = now.day.toString().padLeft(2, '0');
  final hour = now.hour.toString().padLeft(2, '0');
  final minute = now.minute.toString().padLeft(2, '0');
  return '$year$month${day}_$hour$minute';
}

void main() async {
  try {
    final version = _readVersion();
    final stamp = _timestamp();
    final newName = 'zanny_collection_v${version}_$stamp.apk';

    // Paths where Flutter places release/debug/profile APKs:
    final pathsToCheck = [
      'build/app/outputs/flutter-apk/app-release.apk',
      'build/app/outputs/apk/release/app-release.apk',
    ];
    
    File? apkFile;
    String? foundDir;
    for (final path in pathsToCheck) {
      final file = File(path);
      if (file.existsSync()) {
        apkFile = file;
        foundDir = file.parent.path;
        break;
      }
    }
    
    if (apkFile == null) {
      // Let's also check if there is any .apk in output dirs
      final dirsToCheck = [
        'build/app/outputs/flutter-apk',
        'build/app/outputs/apk/release',
      ];
      for (final dirPath in dirsToCheck) {
        final dir = Directory(dirPath);
        if (dir.existsSync()) {
          final list = dir.listSync();
          for (final entity in list) {
            if (entity is File && entity.path.endsWith('.apk') && !entity.path.contains('zanny_collection_v')) {
              apkFile = entity;
              foundDir = dirPath;
              break;
            }
          }
        }
        if (apkFile != null) break;
      }
    }

    if (apkFile == null) {
      stderr.writeln('No release APK found in build outputs. Please run "flutter build apk --release" first.');
      exit(1);
    }

    final newPath = '$foundDir/$newName';
    await apkFile.rename(newPath);
    stdout.writeln('SUCCESS: APK renamed to $newName (located at $newPath)');
  } catch (e) {
    stderr.writeln('Error: $e');
    exit(1);
  }
}
