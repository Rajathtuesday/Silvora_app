package cloud.silvora.app

import android.content.ContentValues
import android.os.Build
import android.os.Bundle
import android.os.Environment
import android.provider.MediaStore
import android.provider.Settings
import android.view.WindowManager
import androidx.core.view.WindowCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private val channelName = "silvora/mediastore"
    private val securityChannelName = "silvora/device_security"

    override fun onCreate(savedInstanceState: Bundle?) {
        // Explicit edge-to-edge opt-in for Android 15+ (targetSdk 36 here).
        // Without this, the window falls back to the deprecated non-edge-to-edge
        // fitting path that Play Console's pre-launch report flags. Every screen
        // already wraps its content in SafeArea, so this is safe to enable app-wide.
        WindowCompat.setDecorFitsSystemWindows(window, false)

        // FLAG_SECURE keeps decrypted vault content out of screenshots, screen
        // recordings, and the app-switcher / recents thumbnail. Essential for an
        // end-to-end-encrypted vault: nothing sensitive leaks via the OS.
        // Debug-only exception: gated to release builds so Play Store listing
        // screenshots can actually be taken (a debug build, e.g. via
        // `flutter run` or a debug APK install) -- real users only ever get a
        // release build, which always has this on.
        if (!BuildConfig.DEBUG) {
            window.setFlags(
                WindowManager.LayoutParams.FLAG_SECURE,
                WindowManager.LayoutParams.FLAG_SECURE,
            )
        }
        super.onCreate(savedInstanceState)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "saveToDownloads" -> {
                        val bytes = call.argument<ByteArray>("bytes")
                        val filename = call.argument<String>("filename")
                        val mime = call.argument<String>("mime") ?: "application/octet-stream"
                        if (bytes == null || filename.isNullOrBlank()) {
                            result.error("BAD_ARGS", "bytes and filename are required", null)
                            return@setMethodCallHandler
                        }
                        try {
                            result.success(saveToDownloads(bytes, filename, mime))
                        } catch (e: Exception) {
                            result.error("SAVE_FAILED", e.message, null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, securityChannelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "checkDeviceSecurity" -> result.success(
                        mapOf(
                            "isRooted" to isDeviceRooted(),
                            "developerModeEnabled" to isDeveloperModeEnabled(),
                        )
                    )
                    else -> result.notImplemented()
                }
            }
    }

    /**
     * Heuristic root detection -- not foolproof (a sufficiently determined
     * root can hide itself from all of these), but catches the overwhelming
     * majority of real rooted devices without needing a third-party library
     * or its own maintenance burden. Defense in depth: this is a warning
     * gate, not the only thing standing between an attacker and the vault --
     * the actual encryption never assumes the OS itself is trustworthy.
     */
    private fun isDeviceRooted(): Boolean {
        val buildTagsSuspicious = Build.TAGS?.contains("test-keys") == true

        val suspiciousPaths = arrayOf(
            "/system/app/Superuser.apk",
            "/sbin/su",
            "/system/bin/su",
            "/system/xbin/su",
            "/data/local/xbin/su",
            "/data/local/bin/su",
            "/system/sd/xbin/su",
            "/system/bin/failsafe/su",
            "/data/local/su",
            "/su/bin/su",
            "/system/xbin/busybox",
            "/sbin/.magisk",
        )
        val pathFound = suspiciousPaths.any { File(it).exists() }

        val suExecutable = try {
            val process = Runtime.getRuntime().exec(arrayOf("which", "su"))
            process.inputStream.bufferedReader().readLine() != null
        } catch (e: Exception) {
            false
        }

        return buildTagsSuspicious || pathFound || suExecutable
    }

    /** Settings.Global keys, not a runtime permission -- no user prompt needed. */
    private fun isDeveloperModeEnabled(): Boolean {
        val devSettingsOn = Settings.Global.getInt(
            applicationContext.contentResolver,
            Settings.Global.DEVELOPMENT_SETTINGS_ENABLED, 0,
        ) != 0
        val adbOn = Settings.Global.getInt(
            applicationContext.contentResolver,
            Settings.Global.ADB_ENABLED, 0,
        ) != 0
        return devSettingsOn || adbOn
    }

    /**
     * Save bytes into the public Downloads/Silvora folder so the file shows up in
     * the system Files app (and Gallery for media). Returns a human-readable
     * location string. Uses MediaStore on API 29+ (no runtime permission needed)
     * and a direct write on older devices.
     */
    private fun saveToDownloads(bytes: ByteArray, filename: String, mime: String): String {
        val subDir = "Silvora"

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val resolver = applicationContext.contentResolver
            val values = ContentValues().apply {
                put(MediaStore.Downloads.DISPLAY_NAME, filename)
                put(MediaStore.Downloads.MIME_TYPE, mime)
                put(MediaStore.Downloads.RELATIVE_PATH, Environment.DIRECTORY_DOWNLOADS + "/" + subDir)
                put(MediaStore.Downloads.IS_PENDING, 1)
            }
            val collection = MediaStore.Downloads.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
            val uri = resolver.insert(collection, values)
                ?: throw IllegalStateException("Could not create a Downloads entry")

            resolver.openOutputStream(uri)?.use { it.write(bytes) }
                ?: throw IllegalStateException("Could not open the Downloads file for writing")

            values.clear()
            values.put(MediaStore.Downloads.IS_PENDING, 0)
            resolver.update(uri, values, null, null)

            return "Downloads/$subDir/$filename"
        } else {
            @Suppress("DEPRECATION")
            val dir = File(
                Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS),
                subDir,
            )
            if (!dir.exists()) dir.mkdirs()
            val out = File(dir, filename)
            out.writeBytes(bytes)
            return out.absolutePath
        }
    }
}
