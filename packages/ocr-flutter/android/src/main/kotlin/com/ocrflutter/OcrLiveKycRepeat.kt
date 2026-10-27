package com.ocrflutter

import android.os.Bundle
import android.util.Log
import com.udentifycoreflutter.LiveKycRepeatRegistry
import io.udentify.android.ocr.CardRecognizerCredentials
import io.udentify.android.ocr.activities.DocumentType
import io.udentify.android.ocr.activities.Process
import io.udentify.android.ocr.livekyc.OCRLiveKYCRegistrar
import io.udentify.android.ocr.livekyc.OCRRepeatHandler
import java.io.Serializable

/**
 * Supplies the credentials for an in-call OCR re-capture when the video call asks for one.
 * Two registrations are needed: [OCRLiveKYCRegistrar] tells the vendor SDKs an OCR handler exists,
 * and [LiveKycRepeatRegistry] lets the video call plugin fetch the parameters without depending
 * on this plugin. Off until the app calls setRepeatConfig.
 */
internal object OcrLiveKycRepeat {

    private const val TAG = "OcrLiveKycRepeat"

    private data class Config(
        val serverURL: String,
        val userID: String,
        val transactionID: String,
        val country: String,
        val documentType: String,
        val documentSide: String?,
        val cardOrientation: Boolean?
    )

    @Volatile
    private var config: Config? = null

    /** Stores the configuration a repeat will use and opts in. `null` clears it and opts back out. */
    fun setConfig(map: Map<*, *>?) {
        if (map == null) {
            config = null
            LiveKycRepeatRegistry.unregister(LiveKycRepeatRegistry.ROLE_OCR)
            OCRLiveKYCRegistrar.unregister()
            Log.d(TAG, "OCR repeat disabled")
            return
        }

        config = Config(
            serverURL = map.requireString("serverURL"),
            userID = map.requireString("userID"),
            transactionID = map.requireString("transactionID"),
            country = map["country"] as? String ?: "TUR",
            documentType = map["documentType"] as? String ?: "ID_CARD",
            documentSide = map["documentSide"] as? String,
            cardOrientation = map["cardOrientation"] as? Boolean
        )

        OCRLiveKYCRegistrar.register()
        LiveKycRepeatRegistry.register(LiveKycRepeatRegistry.ROLE_OCR) { buildParams() }
        Log.d(TAG, "OCR repeat enabled for transaction ${config?.transactionID}")
    }

    private fun Map<*, *>.requireString(key: String): String {
        val value = this[key] as? String
        require(!value.isNullOrEmpty()) { "setRepeatConfig: \"$key\" is required" }
        return value
    }

    private fun buildParams(): Bundle? {
        val current = config ?: return null

        // Same mapping the normal (non-repeat) OCR entry point uses, so a repeat reads the same
        // document the original scan did.
        val docType = when (current.documentType.uppercase()) {
            "ID_CARD" -> DocumentType.OCR_ID_UPLOAD
            "PASSPORT" -> DocumentType.OCR_PASSPORT_UPLOAD
            "DRIVER_LICENSE", "DRIVE_LICENCE" -> DocumentType.OCR_DRIVER_LICENCE_UPLOAD
            else -> DocumentType.OCR_ID_UPLOAD
        }

        val credentials = CardRecognizerCredentials.Builder()
            .serverURL(current.serverURL)
            .userID(current.userID)
            .transactionID(current.transactionID)
            .countryCode(CountryCodeMapper.toCountryCode(current.country))
            .docType(docType)
            .build()

        val params = Bundle()
        params.putSerializable(OCRRepeatHandler.PARAM_CREDENTIALS, credentials as Serializable)

        // Both optional. Left out, the handler defaults to the front side and no card
        // orientation, so an app that never sets documentSide always re-scans the front, even
        // when the operator asked for the back.
        when (current.documentSide?.uppercase()) {
            "BACK", "BACKSIDE", "BACK_SIDE" -> params.putSerializable(OCRRepeatHandler.PARAM_DOC_SIDE, Process.backSide)
            "FRONT", "FRONTSIDE", "FRONT_SIDE" -> params.putSerializable(OCRRepeatHandler.PARAM_DOC_SIDE, Process.frontSide)
            null -> Unit
            else -> Log.w(TAG, "Unrecognized documentSide \"${current.documentSide}\"; using the SDK default")
        }
        current.cardOrientation?.let { params.putBoolean(OCRRepeatHandler.PARAM_CARD_ORIENTATION, it) }

        return params
    }
}
