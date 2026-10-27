package com.videocallflutter

import android.os.Parcel
import android.os.Parcelable
import androidx.fragment.app.FragmentActivity
import io.flutter.plugin.common.MethodChannel

// Note: Udentify SDK imports will be dynamically checked
// import io.udentify.vc.VideoCallOperator
// import io.udentify.vc.VideoCallCredentials
// import io.udentify.vc.VideoCallFragment
// import io.udentify.vc.VCFragment

/**
 * Implementation of VideoCallOperator interface.
 * This class manages video call functionality using Udentify's SDK.
 */
class VideoCallOperatorImpl(
    private val serverURL: String,
    private val wssURL: String,
    private val userID: String,
    private val transactionID: String,
    private val clientName: String,
    private val idleTimeout: String,
    private val channel: MethodChannel?,
    // Frames per second, or null to leave the SDK's own default in place.
    private val cameraFeedFrameRate: Float? = null,
    // ObservationMode enum name (CAMERA_FEED / SCREEN_SHARE / PROGRESS_ONLY), or null to leave
    // the SDK's own default in place.
    private val observationMode: String? = null
) : Parcelable {
    
    // When Udentify SDK is available, implement VideoCallOperator interface:
    // class VideoCallOperatorImpl(...) : VideoCallOperator, Parcelable {
    
    private var currentStatus = "idle"
    private val mainHandler = android.os.Handler(android.os.Looper.getMainLooper())
    private var cancelInFlight = false
    // Set by didFailWithError so the onCallEnded that follows reports the call as failed.
    private var hasFailed = false

    /** The last error reported to Dart, so a failed start can return it in its result. */
    var lastError: Pair<String, String>? = null
        private set
    private var videoCallFragment: Any? = null // VideoCallFragment when SDK is available
    
    // The app's VideoCallConfig as Dart sent it (only what was set), applied to the SDK's view tree
    // by the styler. Null means the app styled nothing and the SDK keeps its own look.
    private var styleConfig: Map<String, Any?>? = null
    private val styleApplier = VideoCallStyleApplier { currentMicrophoneState() }
    private var fragmentCallbacks: androidx.fragment.app.FragmentManager.FragmentLifecycleCallbacks? = null
    private var fragmentCallbacksManager: androidx.fragment.app.FragmentManager? = null

    constructor(parcel: Parcel) : this(
        parcel.readString() ?: "",
        parcel.readString() ?: "",
        parcel.readString() ?: "",
        parcel.readString() ?: "",
        parcel.readString() ?: "",
        parcel.readString() ?: "30",
        // Note: MethodChannel cannot be parceled, so we pass null
        // In real implementation, you'd need to handle this differently
        null
    )

    // When Udentify SDK is available, implement this method from VideoCallOperator:
    /*
    override fun getCredentials(): VideoCallCredentials {
        return VideoCallCredentials.Builder()
            .serverURL(serverURL)
            .wssURL(wssURL)
            .userID(userID)
            .transactionID(transactionID)
            .clientName(clientName)
            .idleTimeout(idleTimeout)
            .build()
    }
    */

    fun startVideoCall(activity: FragmentActivity): Boolean {
        return try {
            currentStatus = "connecting"
            notifyStatusChanged("connecting")

            // Verify Udentify SDK is available
            if (!isUdentifySDKAvailable()) {
                currentStatus = "failed"
                notifyError("ERR_SDK_NOT_AVAILABLE", "Udentify SDK is not available. Please ensure AAR files are properly integrated.")
                return false
            }

            // Create a dynamic proxy that implements VideoCallOperator interface
            val operatorInterface = Class.forName("io.udentify.android.vc.listener.VideoCallOperator")
            val proxy = java.lang.reflect.Proxy.newProxyInstance(
                operatorInterface.classLoader,
                arrayOf(operatorInterface)
            ) { proxy, method, args ->
                when (method.name) {
                    "onCallStarted" -> {
                        onCallStarted()
                        Unit
                    }
                    "onCallEnded" -> {
                        onCallEnded()
                        Unit
                    }
                    "didChangeUserState" -> {
                        val userState = args?.get(0)
                        if (userState != null) {
                            didChangeUserState(userState)
                        }
                        Unit
                    }
                    "didChangeParticipantState" -> {
                        val participantState = args?.get(0)
                        if (participantState != null) {
                            didChangeParticipantState(participantState)
                        }
                        Unit
                    }
                    "didFailWithError" -> {
                        didFailWithError(args?.get(0) as String)
                        Unit
                    }
                    // Interface default methods are never run by a java.lang.reflect.Proxy, so
                    // every callback the SDK may invoke has to be named here or it is dropped.
                    "onPhoneLocked" -> {
                        emit("onScreenLocked", null)
                        Unit
                    }
                    "onPhoneUnlocked" -> {
                        emit("onScreenUnlocked", null)
                        Unit
                    }
                    "onPhoneCallStateChanged" -> {
                        args?.get(0)?.let { emit("onPhoneCallStateChanged", mapOf("state" to it.toString())) }
                        Unit
                    }
                    "onMicrophoneStateChanged" -> {
                        emit("onMicrophoneStateChanged", mapOf("enabled" to (args?.get(0) as? Boolean ?: false)))
                        // The SDK repaints the mute button itself on every change; put the app's tint back.
                        mainHandler.post { applyStyles() }
                        Unit
                    }
                    // In-call LiveKYC repeat. A role with no registered provider is refused (null),
                    // which is the default and a supported state: repeats stay off until the app
                    // opts the matching plugin in with setRepeatConfig.
                    "getRepeatParams" -> {
                        val role = (args?.get(0) as? Enum<*>)?.name
                        val params = role?.let { com.udentifycoreflutter.LiveKycRepeatRegistry.paramsFor(it) }
                        if (role != null && params != null) emit("onRepeatStarted", mapOf("role" to role))
                        params
                    }
                    "onRepeatResult" -> {
                        // Reports only that a repeat produced a result, and for which role.
                        (args?.get(0) as? Enum<*>)?.name?.let { emit("onRepeatResult", mapOf("role" to it)) }
                        Unit
                    }
                    "onRepeatEnded" -> {
                        emit(
                            "onRepeatEnded",
                            mapOf(
                                "role" to ((args?.get(0) as? Enum<*>)?.name ?: ""),
                                "outcome" to (args?.get(1) as? Enum<*>)?.name,
                                "reason" to (args?.get(2) as? String)
                            )
                        )
                        Unit
                    }
                    "getCredentials" -> getCredentials()
                    // Object methods also reach the handler; returning null for these would
                    // unbox to a NullPointerException.
                    "hashCode" -> System.identityHashCode(proxy)
                    "equals" -> proxy === args?.get(0)
                    "toString" -> "VideoCallOperatorProxy"
                    "writeToParcel" -> {
                        writeToParcel(args?.get(0) as android.os.Parcel, args?.get(1) as Int)
                        Unit
                    }
                    "describeContents" -> describeContents()
                    else -> null
                }
            }
            
            // Use reflection to create VideoCallFragment
            val vcFragmentClass = Class.forName("io.udentify.android.vc.fragment.VCFragment")
            // The SDK documents passing the SAME name to newInstance(operator, name) and to addToBackStack(name):
            // that name is how it pops its own back-stack entry when it dismisses the call. Without it a dismissed
            // call leaves a stale entry behind. An SDK without the two-argument overload gets neither.
            val namedBackStack = try {
                vcFragmentClass.getMethod("newInstance", operatorInterface, String::class.java)
            } catch (e: NoSuchMethodException) {
                null
            }
            val fragment = (
                if (namedBackStack != null) namedBackStack.invoke(null, proxy, BACK_STACK_VIDEO_CALL)
                else vcFragmentClass.getMethod("newInstance", operatorInterface).invoke(null, proxy)
            ) as androidx.fragment.app.Fragment
            
            // Style the fragment's view the moment the SDK has inflated it. Registered before the
            // transaction so the very first frame is styled.
            registerStyleCallbacks(activity.supportFragmentManager)

            // Add fragment to activity
            val transaction = activity.supportFragmentManager.beginTransaction()
                .replace(android.R.id.content, fragment)
            if (namedBackStack != null) transaction.addToBackStack(BACK_STACK_VIDEO_CALL)
            transaction.commit()
            
            videoCallFragment = fragment
            true
        } catch (e: Exception) {
            currentStatus = "failed"
            notifyError("ERR_UNKNOWN", "Failed to start video call: ${e.message}")
            false
        }
    }
    
    private fun isUdentifySDKAvailable(): Boolean {
        return try {
            Class.forName("io.udentify.android.vc.fragment.VCFragment")
            Class.forName("io.udentify.android.vc.model.VideoCallCredentials")
            true
        } catch (e: ClassNotFoundException) {
            false
        }
    }
    
    // Method to create VideoCallCredentials using reflection
    // This method is required by the VideoCallOperator interface
    fun getCredentials(): Any? {
        return try {
            if (!isUdentifySDKAvailable()) {
                throw IllegalStateException("Udentify SDK is not available")
            }
            
            val credentialsClass = Class.forName("io.udentify.android.vc.model.VideoCallCredentials")
            val builderClass = Class.forName("io.udentify.android.vc.model.VideoCallCredentials\$Builder")
            
            val builderConstructor = builderClass.getDeclaredConstructor()
            val builder = builderConstructor.newInstance()
            
            // Set properties using reflection
            builderClass.getMethod("serverURL", String::class.java).invoke(builder, serverURL)
            builderClass.getMethod("wssURL", String::class.java).invoke(builder, wssURL)
            builderClass.getMethod("userID", String::class.java).invoke(builder, userID)
            builderClass.getMethod("transactionID", String::class.java).invoke(builder, transactionID)
            builderClass.getMethod("clientName", String::class.java).invoke(builder, clientName)
            builderClass.getMethod("idleTimeout", Int::class.java).invoke(builder, idleTimeout.toIntOrNull() ?: 30)

            // What the remote operator sees during a repeat step. Omitting it leaves the SDK's own
            // default, CAMERA_FEED, which needs no MediaProjection.
            observationMode?.takeIf { it.isNotBlank() }?.let { requested ->
                val enumClass = Class.forName("io.udentify.android.vc.enums.ObservationMode")
                val value = enumClass.enumConstants?.firstOrNull { (it as Enum<*>).name == requested }
                if (value != null) {
                    builderClass.getMethod("observationMode", enumClass).invoke(builder, value)
                } else {
                    android.util.Log.w("VideoCallOperator", "observationMode='$requested' ignored: expected one of " +
                        (enumClass.enumConstants?.joinToString { (it as Enum<*>).name } ?: ""))
                }
            }

            // Nothing is passed unless the app asked, so the SDK's own default stands. The SDK
            // clamps a rate the sensor cannot deliver; only meaningless input is refused here.
            cameraFeedFrameRate?.let { rate ->
                if (rate.isFinite() && rate > 0f) {
                    builderClass.getMethod("cameraFeedFrameRate", Float::class.javaPrimitiveType).invoke(builder, rate)
                } else {
                    android.util.Log.w("VideoCallOperator", "cameraFeedFrameRate=$rate ignored: expected a positive number of frames per second")
                }
            }
            
            // Build and return credentials
            builderClass.getMethod("build").invoke(builder)
        } catch (e: Exception) {
            android.util.Log.e("VideoCallOperator", "Failed to create credentials: ${e.message}")
            throw e
        }
    }

    fun endVideoCall(): Boolean {
        return try {
            currentStatus = "disconnected"
            notifyStatusChanged("disconnected")

            removeFragment()

            videoCallFragment = null
            true
        } catch (e: Exception) {
            notifyError("ERR_UNKNOWN", "Failed to end video call: ${e.message}")
            false
        }
    }

    private fun removeFragment() {
        unregisterStyleCallbacks()
        styleApplier.stop()
        (videoCallFragment as? androidx.fragment.app.Fragment)?.let { fragment ->
            // The SDK removes its own screen when the call ends (agent, server cancel), so it may be gone already.
            if (!fragment.isAdded) return@let
            try {
                fragment.parentFragmentManager.beginTransaction()
                    .remove(fragment)
                    .commit()
            } catch (e: Exception) {
                android.util.Log.w("VideoCallOperator", "Failed to remove fragment: ${e.message}")
            }
        }
    }

    /**
     * Cancels the transaction on the server. The cancel is what ends the agent's session; merely
     * leaving the media room looks like a network blip from their side. [callback] always runs on
     * the main thread, and a second cancel arriving while one is on the wire is refused, since
     * the server does not treat a duplicate cancel as idempotent.
     */
    fun cancelVideoCall(callback: (Boolean, String?) -> Unit) {
        if (!isUdentifySDKAvailable()) {
            callback(false, "Udentify SDK is not available.")
            return
        }
        if (cancelInFlight) {
            callback(false, CANCEL_IN_PROGRESS)
            return
        }
        cancelInFlight = true
        try {
            VideoCallSdk.cancelVideoCall(serverURL, transactionID) { success, error ->
                // The SDK's network callback runs on an OkHttp thread.
                mainHandler.post {
                    cancelInFlight = false
                    // The SDK closes the call screen whether or not the server confirmed the cancel (its cancel
                    // listener dismisses on success and on error alike), so the call is over locally either way;
                    // a failed cancel only means the agent's session may still be open on the server. When the SDK
                    // already reported the end of the call (the server's terminate signal arrives first), that
                    // status stands: a finished call is not turned into "disconnected" afterwards.
                    if (currentStatus != "completed" && currentStatus != "failed") {
                        currentStatus = "disconnected"
                        notifyStatusChanged("disconnected")
                    }
                    removeFragment()
                    videoCallFragment = null
                    callback(success, error)
                }
            }
        } catch (e: Throwable) {
            cancelInFlight = false
            android.util.Log.e("VideoCallOperator", "Failed to cancel video call: ${e.message}")
            callback(false, e.message)
        }
    }

    /** `false` means the request was not taken up (no connected call). `true` means accepted, not applied. */
    fun setMicrophoneEnabled(enabled: Boolean): Boolean {
        if (!isUdentifySDKAvailable()) return false
        return try {
            VideoCallSdk.setMicrophoneEnabled(enabled)
        } catch (e: Throwable) {
            android.util.Log.e("VideoCallOperator", "Failed to set microphone state: ${e.message}")
            false
        }
    }

    fun isMicrophoneEnabled(): Boolean {
        if (!isUdentifySDKAvailable()) return false
        return try {
            VideoCallSdk.isMicrophoneEnabled()
        } catch (e: Throwable) {
            android.util.Log.e("VideoCallOperator", "Failed to read microphone state: ${e.message}")
            false
        }
    }

    fun getStatus(): String {
        return currentStatus
    }
    
    // VideoCallOperator interface methods required by Udentify SDK
    fun onCallStarted() {
        currentStatus = "connected"
        notifyStatusChanged("connected")
        android.util.Log.d("VideoCallOperator", "onCallStarted called")
        // The microphone state is known from here on, so the mute button can be drawn from it.
        mainHandler.post { applyStyles() }
    }
    
    fun onCallEnded() {
        // The SDK reports the end of a call after a failure too, so success is derived from whether
        // didFailWithError fired rather than assumed; a failed call keeps its "failed" status.
        val succeeded = !hasFailed
        if (succeeded) {
            currentStatus = "completed"
            notifyStatusChanged("completed")
        }
        // The SDK has dismissed (or is dismissing) its screen, whoever ended the call: stop styling it and let go of
        // the fragment callbacks, which otherwise stay registered after an agent-ended call.
        unregisterStyleCallbacks()
        styleApplier.stop()
        emit("onVideoCallEnded", mapOf("success" to succeeded))
        android.util.Log.d("VideoCallOperator", "onCallEnded called (success=$succeeded)")
    }
    
    fun didChangeUserState(userState: Any) {
        val stateString = userState.toString()
        android.util.Log.d("VideoCallOperator", "didChangeUserState: $stateString")
        notifyUserStateChanged(stateString)
    }

    fun didChangeParticipantState(participantState: Any) {
        val stateString = participantState.toString()
        val participantType = remoteParticipantType()
        android.util.Log.d("VideoCallOperator", "didChangeParticipantState: $stateString ($participantType)")
        notifyParticipantStateChanged(stateString, participantType)
    }

    // The SDK's participant-state callback carries only a state, never which participant it is about,
    // so the type ("agent" / "supervisor") is recovered from the LiveKit room the fragment holds. The
    // field names are obfuscated and change between drops, so the room is found by its type. Every
    // step is guarded: when anything is missing the type is simply null, as it was before.
    private var roomField: java.lang.reflect.Field? = null

    private fun remoteParticipantType(): String? {
        val fragment = videoCallFragment ?: return null
        return try {
            val field = roomField ?: run {
                var current: Class<*>? = fragment.javaClass
                var found: java.lang.reflect.Field? = null
                while (current != null && current != Any::class.java && found == null) {
                    found = current.declaredFields.firstOrNull { it.type.name == "io.livekit.android.room.Room" }
                    current = current.superclass
                }
                found?.also { it.isAccessible = true; roomField = it }
            } ?: return null
            val room = field.get(fragment) ?: return null
            val participants = (room.javaClass.getMethod("getRemoteParticipants").invoke(room) as? Map<*, *>)
                ?.values?.filterNotNull() ?: return null
            // Same derivation the SDK uses: a case-sensitive substring test on the participant's metadata.
            val types = participants.map { participant ->
                val metadata = participant.javaClass.getMethod("getMetadata").invoke(participant) as? String
                    ?: return null
                when {
                    metadata.contains("agent") -> "agent"
                    metadata.contains("supervisor") -> "supervisor"
                    else -> return null
                }
            }
            types.distinct().singleOrNull()
        } catch (t: Throwable) {
            android.util.Log.w("VideoCallOperator", "Could not determine the participant type: ${t.message}")
            null
        }
    }
    
    fun didFailWithError(error: String) {
        currentStatus = "failed"
        hasFailed = true
        notifyStatusChanged("failed")
        notifyError(errorTypeFor(error), error)
        android.util.Log.e("VideoCallOperator", "didFailWithError: $error")
    }

    /** The app's `VideoCallConfig`; safe to call before or during a call. */
    fun setConfig(config: Map<String, Any?>?) {
        styleConfig = config
        mainHandler.post { applyStyles() }
    }

    // No-op until the SDK has inflated its view; the lifecycle callback registered at start calls
    // this again the moment it does.
    private fun applyStyles() {
        val view = (videoCallFragment as? androidx.fragment.app.Fragment)?.view ?: return
        styleApplier.apply(view, styleConfig)
    }

    /** `null` until the call is connected: before that the SDK has no microphone state to report. */
    private fun currentMicrophoneState(): Boolean? {
        if (currentStatus != "connected") return null
        return try {
            VideoCallSdk.isMicrophoneEnabled()
        } catch (t: Throwable) {
            null
        }
    }

    private fun registerStyleCallbacks(fm: androidx.fragment.app.FragmentManager) {
        unregisterStyleCallbacks()
        val callbacks = object : androidx.fragment.app.FragmentManager.FragmentLifecycleCallbacks() {
            override fun onFragmentViewCreated(
                fm: androidx.fragment.app.FragmentManager,
                f: androidx.fragment.app.Fragment,
                v: android.view.View,
                savedInstanceState: android.os.Bundle?
            ) {
                if (f !== videoCallFragment) return
                applyStyles()
                // The SDK sizes some of its views after this callback, so once more when laid out.
                v.post { applyStyles() }
            }
        }
        fm.registerFragmentLifecycleCallbacks(callbacks, false)
        fragmentCallbacks = callbacks
        fragmentCallbacksManager = fm
    }

    private fun unregisterStyleCallbacks() {
        val callbacks = fragmentCallbacks ?: return
        try {
            fragmentCallbacksManager?.unregisterFragmentLifecycleCallbacks(callbacks)
        } catch (t: Throwable) {
            android.util.Log.w("VideoCallOperator", "Failed to unregister style callbacks: ${t.message}")
        }
        fragmentCallbacks = null
        fragmentCallbacksManager = null
    }

    fun dismissVideoCall() {
        // When Udentify SDK is available, dismiss the video call UI
        endVideoCall()
    }



    // The SDK reports a missing runtime permission as free text ("Missing permission(s): ..."),
    // so this is the only place the type can be recovered. Anything else stays ERR_SDK.
    private fun errorTypeFor(error: String): String = when {
        !error.contains("Missing permission", ignoreCase = true) -> "ERR_SDK"
        error.contains(android.Manifest.permission.CAMERA) -> "ERR_CAMERA_PERMISSION_DENIED"
        error.contains(android.Manifest.permission.RECORD_AUDIO) -> "ERR_MICROPHONE_PERMISSION_DENIED"
        else -> "ERR_SDK"
    }

    // MethodChannel calls must be made on the main thread; SDK callbacks are not
    // guaranteed to arrive there.
    private fun emit(method: String, arguments: Any?) {
        val post = {
            try {
                channel?.invokeMethod(method, arguments)
            } catch (e: Exception) {
                android.util.Log.w("VideoCallOperator", "Failed to emit $method: ${e.message}")
            }
        }
        if (android.os.Looper.myLooper() == android.os.Looper.getMainLooper()) post() else mainHandler.post { post() }
    }

    private fun notifyStatusChanged(status: String) {
        try {
            emit("onStatusChanged", status)
        } catch (e: Exception) {
            // Handle error silently
        }
    }

    private fun notifyError(type: String, message: String) {
        lastError = type to message
        try {
            val errorMap = mapOf(
                "type" to type,
                "message" to message
            )
            emit("onError", errorMap)
        } catch (e: Exception) {
            // Handle error silently
        }
    }

    private fun notifyUserStateChanged(state: String) {
        try {
            emit("onUserStateChanged", mapOf("state" to state))
        } catch (e: Exception) {
            // Handle error silently
        }
    }

    private fun notifyParticipantStateChanged(state: String, participantType: String? = null) {
        try {
            emit("onParticipantStateChanged", mapOf("participantType" to participantType, "state" to state))
        } catch (e: Exception) {
            // Handle error silently
        }
    }

    override fun writeToParcel(parcel: Parcel, flags: Int) {
        parcel.writeString(serverURL)
        parcel.writeString(wssURL)
        parcel.writeString(userID)
        parcel.writeString(transactionID)
        parcel.writeString(clientName)
        parcel.writeString(idleTimeout)
    }

    override fun describeContents(): Int {
        return 0
    }

    companion object CREATOR : Parcelable.Creator<VideoCallOperatorImpl> {
        // The back-stack name shared by VCFragment.newInstance(operator, name) and addToBackStack(name).
        private const val BACK_STACK_VIDEO_CALL = "video_call"

        /** The error text of a cancel refused because another one is running; the plugin reports it as ALREADY_IN_PROGRESS. */
        const val CANCEL_IN_PROGRESS = "A cancel request is already in progress."

        override fun createFromParcel(parcel: Parcel): VideoCallOperatorImpl {
            return VideoCallOperatorImpl(parcel)
        }

        override fun newArray(size: Int): Array<VideoCallOperatorImpl?> {
            return arrayOfNulls(size)
        }
    }
}
