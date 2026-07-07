package com.example.zanny_collection

import android.app.DownloadManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.Settings
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.zanny_collection/install"
    private var downloadId: Long = -1
    private var downloadReceiver: BroadcastReceiver? = null

    override fun onDestroy() {
        if (downloadReceiver != null) {
            try {
                unregisterReceiver(downloadReceiver)
            } catch (e: Exception) {
                // Ignore if already unregistered
            }
            downloadReceiver = null
        }
        super.onDestroy()
    }

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
                    installApkFromFile(file)
                    result.success(true)
                } catch (e: Exception) {
                    result.error("INSTALL_ERROR", "Failed to launch installer: ${e.message}", e.toString())
                }
            } else if (call.method == "downloadAndInstallApkInBackground") {
                val apkUrl = call.argument<String>("apkUrl")
                val versionName = call.argument<String>("versionName")
                if (apkUrl == null || versionName == null) {
                    result.error("INVALID_ARGUMENT", "apkUrl or versionName is null", null)
                    return@setMethodCallHandler
                }
                try {
                    startBackgroundDownload(apkUrl, versionName)
                    result.success(true)
                } catch (e: Exception) {
                    result.error("DOWNLOAD_ERROR", "Failed to start background download: ${e.message}", e.toString())
                }
            } else {
                result.notImplemented()
            }
        }
    }

    private fun startBackgroundDownload(apkUrl: String, versionName: String) {
        val downloadManager = getSystemService(Context.DOWNLOAD_SERVICE) as DownloadManager
        val uri = Uri.parse(apkUrl)

        if (downloadReceiver != null) {
            try {
                unregisterReceiver(downloadReceiver)
            } catch (e: Exception) {}
            downloadReceiver = null
        }

        val request = DownloadManager.Request(uri).apply {
            setTitle("Zanny Collection Update")
            setDescription("Downloading v$versionName...")
            setNotificationVisibility(DownloadManager.Request.VISIBILITY_VISIBLE_NOTIFY_COMPLETED)
            setDestinationInExternalFilesDir(this@MainActivity, Environment.DIRECTORY_DOWNLOADS, "zanny_collection_$versionName.apk")
        }

        downloadId = downloadManager.enqueue(request)

        downloadReceiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context?, intent: Intent?) {
                val id = intent?.getLongExtra(DownloadManager.EXTRA_DOWNLOAD_ID, -1) ?: -1
                if (id == downloadId) {
                    val query = DownloadManager.Query().setFilterById(downloadId)
                    val cursor = downloadManager.query(query)
                    if (cursor.moveToFirst()) {
                        val statusIndex = cursor.getColumnIndex(DownloadManager.COLUMN_STATUS)
                        val status = cursor.getInt(statusIndex)
                        if (status == DownloadManager.STATUS_SUCCESSFUL) {
                            val extDir = getExternalFilesDir(Environment.DIRECTORY_DOWNLOADS)
                            val finalFile = File(extDir, "zanny_collection_$versionName.apk")
                            if (finalFile.exists()) {
                                installApkFromFile(finalFile)
                            }
                        }
                    }
                    cursor.close()
                    if (downloadReceiver != null) {
                        try {
                            unregisterReceiver(this)
                        } catch (e: Exception) {}
                        downloadReceiver = null
                    }
                }
            }
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(downloadReceiver, IntentFilter(DownloadManager.ACTION_DOWNLOAD_COMPLETE), Context.RECEIVER_EXPORTED)
        } else {
            registerReceiver(downloadReceiver, IntentFilter(DownloadManager.ACTION_DOWNLOAD_COMPLETE))
        }
    }

    private fun installApkFromFile(file: File) {
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

        val resInfoList = packageManager.queryIntentActivities(intent, PackageManager.MATCH_DEFAULT_ONLY)
        for (resolveInfo in resInfoList) {
            val pkgName = resolveInfo.activityInfo.packageName
            grantUriPermission(pkgName, apkUri, Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }

        startActivity(intent)
    }
}
