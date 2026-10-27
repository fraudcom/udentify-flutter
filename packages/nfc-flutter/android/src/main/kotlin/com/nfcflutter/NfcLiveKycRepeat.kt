package com.nfcflutter

import android.os.Bundle
import android.util.Log
import com.udentifycoreflutter.LiveKycRepeatRegistry
import io.udentify.android.commons.livekyc.LiveKYCCoordinator
import io.udentify.android.commons.livekyc.RepeatRole
import io.udentify.android.nfc.ApiCredentials
import io.udentify.android.nfc.livekyc.NFCLiveKYCRegistrar
import io.udentify.android.nfc.livekyc.NFCRepeatHandler
import java.io.Serializable
import java.text.ParseException
import java.text.SimpleDateFormat
import java.util.Locale

/**
 * Supplies the credentials for an in-call NFC re-read when the video call asks for one. The BAC key
 * material that unlocks the chip comes from the document scan, which in a call is the OCR repeat
 * that ran earlier: the vendor's [LiveKYCCoordinator] caches its result. Off until the app calls
 * setRepeatConfig.
 */
internal object NfcLiveKycRepeat {

    private const val TAG = "NfcLiveKycRepeat"

    private data class Config(
        val serverURL: String,
        val transactionID: String,
        val passiveAuthentication: Boolean?
    )

    @Volatile
    private var config: Config? = null

    fun setConfig(map: Map<*, *>?) {
        if (map == null) {
            config = null
            LiveKycRepeatRegistry.unregister(LiveKycRepeatRegistry.ROLE_NFC)
            NFCLiveKYCRegistrar.unregister()
            Log.d(TAG, "NFC repeat disabled")
            return
        }

        config = Config(
            serverURL = map.requireString("serverURL"),
            transactionID = map.requireString("transactionID"),
            passiveAuthentication = map["passiveAuthentication"] as? Boolean
        )

        NFCLiveKYCRegistrar.register()
        LiveKycRepeatRegistry.register(LiveKycRepeatRegistry.ROLE_NFC) { buildParams() }
        Log.d(TAG, "NFC repeat enabled for transaction ${config?.transactionID}")
    }

    private fun Map<*, *>.requireString(key: String): String {
        val value = this[key] as? String
        require(!value.isNullOrEmpty()) { "setRepeatConfig: \"$key\" is required" }
        return value
    }

    private fun buildParams(): Bundle? {
        val current = config ?: return null

        // Whatever OCR repeat ran earlier in this call. Absent on the first repeat of a call, when
        // the operator asks for NFC without asking for OCR first, or after cancelling the OCR repeat.
        val lastOcr = LiveKYCCoordinator.getInstance().getLastResult(RepeatRole.OCR)
        if (lastOcr == null) {
            Log.w(TAG, "Refusing NFC repeat: no OCR result cached in this call to derive BAC key material from")
            return null
        }

        // Read reflectively rather than casting to the OCR AAR's result type: NFC alone is a
        // supported setup, and naming that type would make the OCR AAR a compile dependency.
        val mrzDocNo = lastOcr.stringGetter("getDocumentId")
        val mrzBirthDate = toMrzDate(lastOcr.stringGetter("getBirthDate"))
        val mrzExpireDate = toMrzDate(lastOcr.stringGetter("getExpireDate"))

        // Refuse rather than open a reader that is certain to fail: without all three fields the
        // chip cannot be unlocked, and a refusal tells the operator something useful.
        if (mrzDocNo.isNullOrEmpty() || mrzBirthDate == null || mrzExpireDate == null) {
            Log.w(
                TAG,
                "Refusing NFC repeat: incomplete BAC key material from the OCR result " +
                    "(docNo=${if (mrzDocNo.isNullOrEmpty()) "missing" else "present"}, " +
                    "birthDate=${mrzBirthDate ?: "unparseable"}, expireDate=${mrzExpireDate ?: "unparseable"})"
            )
            return null
        }

        val builder = ApiCredentials.Builder()
            .serverUrl(current.serverURL)
            .transactionID(current.transactionID)
            .mrzDocNo(mrzDocNo)
            .mrzBirthDate(mrzBirthDate)
            .mrzExpireDate(mrzExpireDate)
        current.passiveAuthentication?.let { builder.isPassiveAuthenticationEnabled(it) }

        val params = Bundle()
        params.putSerializable(NFCRepeatHandler.PARAM_CREDENTIALS, builder.build() as Serializable)
        return params
    }

    private fun Any.stringGetter(name: String): String? = try {
        javaClass.getMethod(name).invoke(this) as? String
    } catch (t: Throwable) {
        Log.w(TAG, "Cached OCR result ${javaClass.name} has no readable $name()", t)
        null
    }

    /** The OCR result reports dates as `dd.MM.yyyy`; the BAC key needs `yyMMdd`. Null when unparseable. */
    private fun toMrzDate(ddMMyyyy: String?): String? {
        if (ddMMyyyy.isNullOrEmpty()) return null
        return try {
            val input = SimpleDateFormat("dd.MM.yyyy", Locale.US).apply { isLenient = false }
            val output = SimpleDateFormat("yyMMdd", Locale.US)
            output.format(input.parse(ddMMyyyy)!!)
        } catch (e: ParseException) {
            Log.w(TAG, "Could not parse \"$ddMMyyyy\" as dd.MM.yyyy", e)
            null
        }
    }
}
