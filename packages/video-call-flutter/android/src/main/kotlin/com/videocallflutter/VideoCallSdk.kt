package com.videocallflutter

import io.udentify.android.vc.fragment.UdentifyVideoCallFragment
import io.udentify.android.vc.listener.CancelVideoCallListener

/**
 * Direct calls into the vendor SDK's static API. Kept in its own object so that
 * [VideoCallOperatorImpl] still loads when the AAR is missing: nothing here is
 * touched until [VideoCallOperatorImpl.isUdentifySDKAvailable] has passed.
 */
internal object VideoCallSdk {

    /** Cancels the transaction on the server. [callback] may run off the main thread. */
    fun cancelVideoCall(serverURL: String, transactionID: String, callback: (Boolean, String?) -> Unit) {
        UdentifyVideoCallFragment.cancelVideoCall(
            serverURL,
            transactionID,
            object : CancelVideoCallListener() {
                override fun onCancelSuccess(success: Boolean) = callback(success, null)
                override fun onCancelError(error: String) = callback(false, error)
            }
        )
    }

    /** `true` means the request was accepted, not applied; `false` means there was no connected call. */
    fun setMicrophoneEnabled(enabled: Boolean): Boolean =
        UdentifyVideoCallFragment.setMicrophoneEnabled(enabled)

    fun isMicrophoneEnabled(): Boolean = UdentifyVideoCallFragment.isMicrophoneEnabled()
}
