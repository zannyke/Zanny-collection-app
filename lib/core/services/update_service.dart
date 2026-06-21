import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import '../cloudflare/api_client.dart';
import '../theme/app_colors.dart';
import '../router/app_router.dart';

/// Version info fetched from Cloudflare R2 via the Worker API.
class AppVersionInfo {
  final String version;
  final int build;
  final String apkUrl;
  final String changelog;

  const AppVersionInfo({
    required this.version,
    required this.build,
    required this.apkUrl,
    required this.changelog,
  });

  factory AppVersionInfo.fromJson(Map<String, dynamic> json) => AppVersionInfo(
    version: json['version'] as String? ?? '1.0.0',
    build: (json['build'] as num?)?.toInt() ?? 1,
    apkUrl: json['apk_url'] as String? ?? '',
    changelog: json['changelog'] as String? ?? '',
  );
}

class UpdateService {
  UpdateService._();

  static const _channel = MethodChannel('com.example.zanny_collection/install');

  static const String currentVersion = '1.0.10';
  static const int currentBuild = 22;

  /// Check if the app is allowed to install packages (Android 8.0+)
  static Future<bool> checkInstallPermission() async {
    try {
      if (Platform.isAndroid) {
        return await _channel.invokeMethod<bool>('checkInstallPermission') ?? false;
      }
      return true;
    } catch (e) {
      debugPrint('⚠️ Error checking install permission: $e');
      return false;
    }
  }

  /// Request the user to grant package installation permission
  static Future<void> requestInstallPermission() async {
    try {
      if (Platform.isAndroid) {
        await _channel.invokeMethod('requestInstallPermission');
      }
    } catch (e) {
      debugPrint('⚠️ Error requesting install permission: $e');
    }
  }

  /// Check for update and call [onUpdateAvailable] if newer version exists.
  /// Returns true if an update is available, false otherwise.
  static Future<bool> checkForUpdate({
    required BuildContext context,
    bool showFeedback = false,
  }) async {
    try {
      final resp = await ApiClient.instance.get('/api/version');
      final info = AppVersionInfo.fromJson(resp.data as Map<String, dynamic>);

      if (info.build > currentBuild && info.apkUrl.isNotEmpty) {
        if (!context.mounted) return false;
        _showUpdateDialog(context, info);
        return true;
      } else {
        if (showFeedback) {
          scaffoldMessengerKey.currentState?.showSnackBar(
            const SnackBar(
              content: Text('Zanny Collection is up to date!'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return false;
      }
    } catch (e) {
      debugPrint('⚠️ Update check failed: $e');
      if (showFeedback) {
        scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text('Failed to check for updates: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return false;
    }
  }
  static void _showUpdateDialog(BuildContext context, AppVersionInfo info) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      builder: (ctx) => _UpdateBottomSheet(info: info),
    );
  }

  /// Download the APK and launch the system installer.
  static Future<void> downloadAndInstall(
    AppVersionInfo info,
    ValueNotifier<double> progressNotifier,
  ) async {
    final dir = Platform.isAndroid
        ? (await getExternalStorageDirectory() ?? await getTemporaryDirectory())
        : await getTemporaryDirectory();
    final filePath = '${dir.path}/zanny_collection_${info.version}_b${info.build}.apk';

    // Clean up any existing file to prevent conflicts/corruptions
    final file = File(filePath);
    if (file.existsSync()) {
      try {
        file.deleteSync();
      } catch (e) {
        debugPrint('⚠️ Failed to delete existing APK: $e');
      }
    }

    final dio = Dio();
    dio.options.headers['User-Agent'] = 'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Mobile Safari/537.36';
    await dio.download(
      info.apkUrl,
      filePath,
      onReceiveProgress: (received, total) {
        if (total > 0) progressNotifier.value = received / total;
      },
    );

    try {
      if (Platform.isAndroid) {
        final success = await _channel.invokeMethod<bool>('installApk', {'filePath': filePath});
        debugPrint('ℹ️ Native installApk result: $success');
      } else {
        final result = await OpenFile.open(filePath, type: 'application/vnd.android.package-archive');
        debugPrint('ℹ️ OpenFile result: ${result.type} - ${result.message}');
      }
    } catch (e) {
      debugPrint('⚠️ Error launching native package installer: $e');
      final result = await OpenFile.open(filePath, type: 'application/vnd.android.package-archive');
      debugPrint('ℹ️ OpenFile fallback result: ${result.type} - ${result.message}');
    }
  }
}

class _UpdateBottomSheet extends StatefulWidget {
  final AppVersionInfo info;
  const _UpdateBottomSheet({required this.info});

  @override
  State<_UpdateBottomSheet> createState() => _UpdateBottomSheetState();
}

class _UpdateBottomSheetState extends State<_UpdateBottomSheet> {
  bool _downloading = false;
  final ValueNotifier<double> _progress = ValueNotifier(0.0);

  @override
  void dispose() {
    _progress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.system_update_rounded, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Update Available',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.white, fontWeight: FontWeight.w700,
                        )),
                      Text('v${UpdateService.currentVersion} (b${UpdateService.currentBuild}) ➔ v${widget.info.version} (b${widget.info.build})',
                        style: theme.textTheme.bodySmall?.copyWith(color: Colors.white54)),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close, color: Colors.white38, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (widget.info.changelog.isNotEmpty) ...[
              Text(
                "WHAT'S NEW",
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.accentGold,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                widget.info.changelog,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white70,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
            ],
            if (_downloading) ...[
              ValueListenableBuilder<double>(
                valueListenable: _progress,
                builder: (_, value, __) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: value,
                        backgroundColor: Colors.white12,
                        color: Colors.white,
                        minHeight: 6,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('${(value * 100).toStringAsFixed(0)}% downloaded',
                      style: theme.textTheme.bodySmall?.copyWith(color: Colors.white54)),
                  ],
                ),
              ),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white54,
                        side: const BorderSide(color: Colors.white12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Later'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () async {
                        final hasPermission = await UpdateService.checkInstallPermission();
                        if (!hasPermission) {
                          if (!context.mounted) return;
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              backgroundColor: const Color(0xFF111111),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
                              ),
                              title: Text(
                                'Permission Required',
                                style: GoogleFonts.playfairDisplay(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              content: Text(
                                'To install this update, Zanny Collection needs permission to install unknown apps. Please enable this in the settings page that opens.',
                                style: GoogleFonts.inter(fontSize: 14, color: Colors.white70, height: 1.5),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: Text('Cancel', style: GoogleFonts.inter(color: Colors.white54)),
                                ),
                                TextButton(
                                  onPressed: () async {
                                    Navigator.pop(ctx);
                                    await UpdateService.requestInstallPermission();
                                  },
                                  child: Text(
                                    'Open Settings',
                                    style: GoogleFonts.inter(
                                      color: AppColors.accentGold,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                          return;
                        }

                        setState(() => _downloading = true);
                        try {
                          await UpdateService.downloadAndInstall(widget.info, _progress);
                          if (!context.mounted) return;
                          Navigator.pop(context);
                        } catch (e) {
                          if (!context.mounted) return;
                          setState(() => _downloading = false);
                          scaffoldMessengerKey.currentState?.showSnackBar(
                            const SnackBar(content: Text('Download failed. Please try again.')),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Update Now', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
