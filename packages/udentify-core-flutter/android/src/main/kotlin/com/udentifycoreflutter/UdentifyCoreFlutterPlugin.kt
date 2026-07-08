package com.udentifycoreflutter

import android.content.Context
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.udentify.android.commons.model.UdentifySettingsProvider
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/**
 * UdentifyCoreFlutterPlugin
 * Flutter plugin for SSL certificate pinning using UdentifySettingsProvider
 */
class UdentifyCoreFlutterPlugin: FlutterPlugin, MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var context: Context
    private var sslPinningManager: SSLPinningManager? = null
    private var localizationManager: LocalizationManager? = null
    
    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "udentify_core_flutter")
        channel.setMethodCallHandler(this)
        context = flutterPluginBinding.applicationContext
        sslPinningManager = SSLPinningManager(context)
        localizationManager = LocalizationManager(context)
    }
    
    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "loadCertificateFromAssets" -> {
                val manager = sslPinningManager
                if (manager == null) {
                    result.error("NOT_INITIALIZED", "SSL Pinning Manager not initialized", null)
                    return
                }
                
                val certificateName = call.argument<String>("certificateName")
                val extension = call.argument<String>("extension")
                
                if (certificateName == null || extension == null) {
                    result.error("INVALID_ARGUMENTS", "Certificate name and extension are required", null)
                    return
                }
                
                manager.loadCertificateFromAssets(
                    certificateName = certificateName,
                    extension = extension,
                    onSuccess = { result.success(true) },
                    onError = { error -> result.error("LOAD_CERT_ERROR", error, null) }
                )
            }
            "setSSLCertificateBase64" -> {
                val manager = sslPinningManager
                if (manager == null) {
                    result.error("NOT_INITIALIZED", "SSL Pinning Manager not initialized", null)
                    return
                }
                
                val certificateBase64 = call.argument<String>("certificateBase64")
                
                if (certificateBase64 == null) {
                    result.error("INVALID_ARGUMENTS", "Certificate base64 data is required", null)
                    return
                }
                
                manager.setSSLCertificateBase64(
                    certificateBase64 = certificateBase64,
                    onSuccess = { result.success(true) },
                    onError = { error -> result.error("SET_CERT_ERROR", error, null) }
                )
            }
            "removeSSLCertificate" -> {
                val manager = sslPinningManager
                if (manager == null) {
                    result.error("NOT_INITIALIZED", "SSL Pinning Manager not initialized", null)
                    return
                }
                
                manager.removeSSLCertificate(
                    onSuccess = { result.success(true) },
                    onError = { error -> result.error("REMOVE_CERT_ERROR", error, null) }
                )
            }
            "getSSLCertificateBase64" -> {
                val manager = sslPinningManager
                if (manager == null) {
                    result.error("NOT_INITIALIZED", "SSL Pinning Manager not initialized", null)
                    return
                }
                
                manager.getSSLCertificateBase64(
                    onSuccess = { certificate -> result.success(certificate) },
                    onError = { error -> result.error("GET_CERT_ERROR", error, null) }
                )
            }
            "isSSLPinningEnabled" -> {
                val manager = sslPinningManager
                if (manager == null) {
                    result.error("NOT_INITIALIZED", "SSL Pinning Manager not initialized", null)
                    return
                }
                
                manager.isSSLPinningEnabled(
                    onSuccess = { isEnabled -> result.success(isEnabled) },
                    onError = { error -> result.error("CHECK_STATUS_ERROR", error, null) }
                )
            }
            "instantiateServerBasedLocalization" -> {
                val manager = localizationManager
                if (manager == null) {
                    result.error("NOT_INITIALIZED", "Localization Manager not initialized", null)
                    return
                }
                
                val language = call.argument<String>("language")
                val serverUrl = call.argument<String>("serverUrl")
                val transactionId = call.argument<String>("transactionId")
                val requestTimeout = call.argument<Double>("requestTimeout")
                
                if (language == null || serverUrl == null || transactionId == null || requestTimeout == null) {
                    result.error("INVALID_ARGUMENTS", "Language, serverUrl, transactionId, and requestTimeout are required", null)
                    return
                }
                
                manager.instantiateServerBasedLocalization(
                    language = language,
                    serverUrl = serverUrl,
                    transactionId = transactionId,
                    requestTimeout = requestTimeout,
                    onSuccess = { result.success(null) },
                    onError = { error -> result.error("LOCALIZATION_ERROR", error, null) }
                )
            }
            "getLocalizationMap" -> {
                val manager = localizationManager
                if (manager == null) {
                    result.error("NOT_INITIALIZED", "Localization Manager not initialized", null)
                    return
                }
                
                manager.getLocalizationMap(
                    onSuccess = { localizationMap -> result.success(localizationMap) },
                    onError = { error -> result.error("GET_MAP_ERROR", error, null) }
                )
            }
            "clearLocalizationCache" -> {
                val manager = localizationManager
                if (manager == null) {
                    result.error("NOT_INITIALIZED", "Localization Manager not initialized", null)
                    return
                }
                
                val language = call.argument<String>("language")
                
                if (language == null) {
                    result.error("INVALID_ARGUMENTS", "Language is required", null)
                    return
                }
                
                manager.clearLocalizationCache(
                    language = language,
                    onSuccess = { result.success(null) },
                    onError = { error -> result.error("CLEAR_CACHE_ERROR", error, null) }
                )
            }
            "mapSystemLanguageToEnum" -> {
                val manager = localizationManager
                if (manager == null) {
                    result.error("NOT_INITIALIZED", "Localization Manager not initialized", null)
                    return
                }
                
                manager.mapSystemLanguageToEnum(
                    onSuccess = { language -> result.success(language) },
                    onError = { error -> result.error("MAP_LANGUAGE_ERROR", error, null) }
                )
            }
            "fetchTransactionProperties" -> {
                val serverURL = call.argument<String>("serverURL")
                val transactionID = call.argument<String>("transactionID")
                if (serverURL == null || transactionID == null) {
                    result.error("INVALID_ARGUMENTS", "serverURL and transactionID are required", null)
                    return
                }
                // SDK call performs a network request; keep it off the main thread
                Thread {
                    try {
                        val properties = UdentifySettingsProvider.getTransactionProperties(serverURL, transactionID)
                        val names = properties?.map { it.name }
                        Handler(Looper.getMainLooper()).post { result.success(names) }
                    } catch (e: Exception) {
                        Handler(Looper.getMainLooper()).post {
                            result.error("FETCH_TRANSACTION_PROPERTIES_ERROR", e.message, null)
                        }
                    }
                }.start()
            }
            "resetTransactionProperties" -> {
                try {
                    UdentifySettingsProvider.setTransactionProperties(null)
                    result.success(null)
                } catch (e: Exception) {
                    result.error("RESET_TRANSACTION_PROPERTIES_ERROR", e.message, null)
                }
            }
            else -> {
                result.notImplemented()
            }
        }
    }
    
    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        sslPinningManager = null
        localizationManager = null
    }
}

