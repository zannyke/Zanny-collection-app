package com.example.zanny_collection

import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.zanny_collection/install"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "checkInstallPermission") {
                val canInstall = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    packageManager.canRequestPackageInstalls()
                } else {
                    true
                }
                result.success(canInstall)
            } else if (call.method == "requestInstallPermission") {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    val intent = Intent(Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES).apply {
                        data = Uri.parse("package:$packageName")
                    }
                    startActivity(intent)
                    result.success(true)
                } else {
                    result.success(false)
                }
            } else if (call.method == "installApk") {
                val filePath = call.argument<String>("filePath")
                if (filePath == null) {
                    result.error("INVALID_ARGUMENT", "filePath is null", null)
                    return@setMethodCallHandler
                }
                try {
                    val file = File(filePath)
                    if (!file.exists()) {
                        result.error("FILE_NOT_FOUND", "APK file not found at $filePath", null)
                        return@setMethodCallHandler
                    }
                    val apkUri = FileProvider.getUriForFile(
                        this,
                        "$packageName.fileprovider",
                        file
                    )
                    val intent = Intent(Intent.ACTION_VIEW).apply {
                        setDataAndType(apkUri, "application/vnd.android.package-archive")
                        addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    }
                    
                    // On Android 11+ (API 30+), grant URI permission to installer apps explicitly
                    val resInfoList = packageManager.queryIntentActivities(intent, PackageManager.MATCH_DEFAULT_ONLY)
                    for (resolveInfo in resInfoList) {
                        val pkgName = resolveInfo.activityInfo.packageName
                        grantUriPermission(pkgName, apkUri, Intent.FLAG_GRANT_READ_URI_PERMISSION)
                    }

                    startActivity(intent)
                    result.success(true)
                } catch (e: Exception) {
                    result.error("INSTALL_ERROR", "Failed to launch installer: ${e.message}", e.toString())
                }
            } else {
                result.notImplemented()
            }
        }
    }
}
