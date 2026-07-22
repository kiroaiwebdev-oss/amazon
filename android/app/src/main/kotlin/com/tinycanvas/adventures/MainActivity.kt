package com.tinycanvas.adventures

import android.content.ContentValues
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.os.StatFs
import android.provider.MediaStore
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.OutputStream

/**
 * TinyCanvas Adventures - Fire OS host activity.
 *
 * Exposes two small platform channels:
 *  - tinycanvas/media_export : scoped MediaStore PNG export (no broad storage
 *    permission on Fire OS 7+ / Android 10+).
 *  - tinycanvas/amazon_iap   : boundary for the Amazon Appstore SDK. The
 *    real SDK calls are wired in AmazonIapBridge once the owner adds the
 *    Amazon Appstore SDK artifact (docs/AMAZON_IAP_SETUP.md). Until then the
 *    channel reports "sdk_unavailable" so the Dart side can fall back to the
 *    documented product-unavailable state. No secrets are stored here.
 */
class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "tinycanvas/media_export")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "exportPng" -> {
                        val bytes = call.argument<ByteArray>("bytes")
                        val fileName = sanitizeFileName(call.argument<String>("fileName") ?: "tinycanvas.png")
                        if (bytes == null) {
                            result.error("bad_args", "Missing PNG bytes", null)
                        } else {
                            try {
                                val uri = savePngToPictures(bytes, fileName)
                                if (uri != null) result.success(uri.toString())
                                else result.error("write_failed", "MediaStore insert failed", null)
                            } catch (e: Exception) {
                                // Never log artwork bytes or child data.
                                result.error("write_failed", e.javaClass.simpleName, null)
                            }
                        }
                    }
                    "availableBytes" -> {
                        val stat = StatFs(filesDir.absolutePath)
                        result.success(stat.availableBytes)
                    }
                    "openAppSettings" -> {
                        val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS)
                        intent.data = Uri.fromParts("package", packageName, null)
                        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        startActivity(intent)
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "tinycanvas/amazon_iap")
            .setMethodCallHandler { call, result ->
                // Boundary only: the Amazon Appstore SDK artifact is added by
                // the owner. Reflection keeps this class loadable without it.
                when (call.method) {
                    "isSdkAvailable" -> result.success(isAmazonSdkOnClasspath())
                    "getProductData", "purchase", "getPurchaseUpdates", "getUserData" ->
                        result.error("sdk_unavailable",
                            "Amazon Appstore SDK not bundled in this build. See docs/AMAZON_IAP_SETUP.md.",
                            null)
                    else -> result.notImplemented()
                }
            }
    }

    private fun isAmazonSdkOnClasspath(): Boolean = try {
        Class.forName("com.amazon.device.iap.PurchasingService")
        true
    } catch (e: ClassNotFoundException) {
        false
    }

    /** Strip path separators and control characters; enforce .png suffix. */
    private fun sanitizeFileName(raw: String): String {
        val cleaned = raw.replace(Regex("[\\\\/:*?\"<>|\\x00-\\x1f]"), "_").trim()
        val base = cleaned.removeSuffix(".png").take(60).ifEmpty { "tinycanvas" }
        return "$base.png"
    }

    private fun savePngToPictures(bytes: ByteArray, fileName: String): Uri? {
        val resolver = contentResolver
        val values = ContentValues().apply {
            put(MediaStore.Images.Media.DISPLAY_NAME, fileName)
            put(MediaStore.Images.Media.MIME_TYPE, "image/png")
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                put(MediaStore.Images.Media.RELATIVE_PATH,
                    Environment.DIRECTORY_PICTURES + "/TinyCanvas")
                put(MediaStore.Images.Media.IS_PENDING, 1)
            }
        }
        val collection = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q)
            MediaStore.Images.Media.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
        else MediaStore.Images.Media.EXTERNAL_CONTENT_URI
        val uri = resolver.insert(collection, values) ?: return null
        var stream: OutputStream? = null
        try {
            stream = resolver.openOutputStream(uri) ?: return null
            stream.write(bytes)
            stream.flush()
        } finally {
            stream?.close()
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            values.clear()
            values.put(MediaStore.Images.Media.IS_PENDING, 0)
            resolver.update(uri, values, null, null)
        }
        return uri
    }
}
