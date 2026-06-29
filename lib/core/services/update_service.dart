import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import '../cloudflare/api_client.dart';
import '../theme/app_colors.dart';
import '../../shared/providers/auth_provider.dart';
import '../../shared/widgets/custom_feedback.dart';

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

  static const String currentVersion = '1.0.25';
  static const int currentBuild = 44;

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
      final resp = await ApiClient.instance.get(
        '/api/version',
        queryParameters: {'t': DateTime.now().millisecondsSinceEpoch.toString()},
      );
      final info = AppVersionInfo.fromJson(resp.data as Map<String, dynamic>);

      if (info.build > currentBuild && info.apkUrl.isNotEmpty) {
        if (!context.mounted) return false;
        _showUpdateDialog(context, info);
        return true;
      } else {
        if (showFeedback && context.mounted) {
          ZannyFeedback.showSuccess(context, 'Zanny Collection is up to date!');
        }
        return false;
      }
    } catch (e) {
      debugPrint('⚠️ Update check failed: $e');
      if (showFeedback && context.mounted) {
        ZannyFeedback.showError(context, 'Failed to check for updates: $e');
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
        if (success != true) {
          throw PlatformException(
            code: 'INSTALL_FAILED',
            message: 'Native installer failed to launch or returned false',
          );
        }
      } else {
        final result = await OpenFile.open(filePath, type: 'application/vnd.android.package-archive');
        if (result.type != ResultType.done) {
          throw Exception('OpenFile failed: ${result.message}');
        }
      }
    } catch (e) {
      debugPrint('⚠️ Error launching native package installer: $e. Trying fallback...');
      final result = await OpenFile.open(filePath, type: 'application/vnd.android.package-archive');
      if (result.type != ResultType.done) {
        throw Exception('Installation failed: ${result.message} (Details: $e)');
      }
    }
  }
}

class _UpdateBottomSheet extends ConsumerStatefulWidget {
  final AppVersionInfo info;
  const _UpdateBottomSheet({required this.info});

  @override
  ConsumerState<_UpdateBottomSheet> createState() => _UpdateBottomSheetState();
}

class _UpdateBottomSheetState extends ConsumerState<_UpdateBottomSheet> with TickerProviderStateMixin {
  bool _downloading = false;
  final ValueNotifier<double> _progress = ValueNotifier(0.0);

  late AnimationController _entryController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _fadeAnimation = CurvedAnimation(parent: _entryController, curve: Curves.easeIn);
    _slideAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(parent: _entryController, curve: Curves.easeOutCubic),
    );

    _entryController.forward();
  }

  @override
  void dispose() {
    _entryController.dispose();
    _progress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final isAdmin = user?.isAdmin == true;

    // Simplified non-technical explanation for regular users, technical logs for admin
    final displayChangelog = isAdmin
        ? widget.info.changelog
        : "This update contains performance improvements, minor bug fixes, and stability updates to provide a smoother shopping experience.";

    return AnimatedBuilder(
      animation: _entryController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0.0, _slideAnimation.value),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 25,
              offset: const Offset(0, 12),
            )
          ]
        ),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Download/Success icon
                  ValueListenableBuilder<double>(
                    valueListenable: _progress,
                    builder: (ctx, value, _) {
                      final isSuccess = value >= 1.0 && _downloading;
                      return Container(
                        width: 56, height: 56,
                        decoration: BoxDecoration(
                          color: isSuccess
                              ? const Color(0xFF10B981).withValues(alpha: 0.08)
                              : Colors.grey.shade100,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSuccess
                                ? const Color(0xFF10B981).withValues(alpha: 0.15)
                                : Colors.grey.shade300,
                            width: 1.5,
                          ),
                        ),
                        child: Icon(
                          isSuccess ? Icons.check_circle_rounded : Icons.cloud_download_rounded,
                          color: isSuccess ? const Color(0xFF10B981) : Colors.black87,
                          size: 26,
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('System Update Available',
                          style: GoogleFonts.inter(
                            color: Colors.black87,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                          )),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFBBF24).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFFBBF24).withValues(alpha: 0.25)),
                              ),
                              child: Text(
                                'v${UpdateService.currentVersion}',
                                style: GoogleFonts.inter(
                                  color: const Color(0xFFFBBF24),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 6),
                              child: Icon(Icons.arrow_forward_rounded, color: Colors.black38, size: 14),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.25)),
                              ),
                              child: Text(
                                'v${widget.info.version}',
                                style: GoogleFonts.inter(
                                  color: const Color(0xFF10B981),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.05),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close, color: Colors.black54, size: 18),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                "WHAT'S NEW",
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: Colors.black54, // Muted grey heading
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
                ),
                child: Text(
                  displayChangelog,
                  style: GoogleFonts.inter(
                    color: Colors.black87,
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              if (_downloading) ...[
                ValueListenableBuilder<double>(
                  valueListenable: _progress,
                  builder: (_, value, __) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Stacked dual progress bar
                      Container(
                        height: 28,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(13),
                          child: Stack(
                            children: [
                              // Older version representation (Base orange/yellow track)
                              Container(
                                color: Colors.amber.shade200,
                              ),
                              // Newer version overriding progress (Green track overlay)
                              FractionallySizedBox(
                                widthFactor: value,
                                child: Container(
                                  color: const Color(0xFF10B981), // Premium Green
                                ),
                              ),
                              // Centered or spaced percentage and labels overlay
                              Positioned.fill(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 14),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'v${UpdateService.currentVersion}',
                                        style: GoogleFonts.inter(
                                          color: Colors.black87,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      Text(
                                        '${(value * 100).toStringAsFixed(0)}%',
                                        style: GoogleFonts.inter(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w900,
                                          shadows: [
                                            const Shadow(color: Colors.black45, blurRadius: 4, offset: Offset(0, 1))
                                          ],
                                        ),
                                      ),
                                      Text(
                                        'v${widget.info.version}',
                                        style: GoogleFonts.inter(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          shadows: [
                                            const Shadow(color: Colors.black45, blurRadius: 4, offset: Offset(0, 1))
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            value < 1.0 ? 'Downloading new version...' : 'Installing update...',
                            style: GoogleFonts.inter(
                              color: Colors.black54,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
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
                          foregroundColor: Colors.black87,
                          side: BorderSide(color: Colors.grey.shade300),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text('Later', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(width: 14),
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
                                backgroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  side: BorderSide(color: Colors.grey.shade300),
                                ),
                                title: Text(
                                  'Permission Required',
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black87,
                                  ),
                                ),
                                content: Text(
                                  'To install this update, Zanny Collection needs permission to install unknown apps. Please enable this in the settings page.',
                                  style: GoogleFonts.inter(fontSize: 13, color: Colors.black54, height: 1.5),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx),
                                    child: Text('Cancel', style: GoogleFonts.inter(color: Colors.black54)),
                                  ),
                                  TextButton(
                                    onPressed: () async {
                                      Navigator.pop(ctx);
                                      await UpdateService.requestInstallPermission();
                                    },
                                    child: Text(
                                      'Open Settings',
                                      style: GoogleFonts.inter(
                                        color: Colors.black87,
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
                            _showErrorDialog(context, e);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black87, // Black matching streetwear system colors
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 0,
                        ),
                        child: Text('Update Now', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _showErrorDialog(BuildContext context, Object error) {
    final user = ref.read(currentUserProvider);
    final isAdmin = user?.isAdmin == true;
    final errorMessage = error.toString().replaceAll('Exception: ', '');

    showDialog(
      context: context,
      builder: (ctx) {
        bool showDetails = false;
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: const Color(0xFF070B19),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: BorderSide(color: const Color(0xFF1E3A8A).withValues(alpha: 0.35)),
              ),
              contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
                    ),
                    child: const Icon(
                      Icons.warning_amber_rounded,
                      color: AppColors.error,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Update Interrupted',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'We encountered an issue while downloading the system update. Please verify your internet connection and try again.',
                    style: GoogleFonts.inter(
                      color: Colors.white70,
                      fontSize: 13,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (isAdmin) ...[
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: () {
                        setStateDialog(() {
                          showDetails = !showDetails;
                        });
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              showDetails ? 'Hide Details' : 'Show Technical Details',
                              style: GoogleFonts.inter(
                                color: const Color(0xFF60A5FA),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              showDetails ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                              color: const Color(0xFF60A5FA),
                              size: 14,
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (showDetails) ...[
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        constraints: const BoxConstraints(maxHeight: 120),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.02),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
                        ),
                        child: SingleChildScrollView(
                          child: SelectableText(
                            errorMessage,
                            style: GoogleFonts.firaCode(
                              color: Colors.white54,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ],
              ),
              actionsAlignment: MainAxisAlignment.center,
              actionsPadding: const EdgeInsets.only(bottom: 20),
              actions: [
                SizedBox(
                  width: 140,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      'Dismiss',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
