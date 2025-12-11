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
    private val channel: MethodChannel?
) : Parcelable {
    
    // When Udentify SDK is available, implement VideoCallOperator interface:
    // class VideoCallOperatorImpl(...) : VideoCallOperator, Parcelable {
    
    private var currentStatus = "idle"
    private var videoCallFragment: Any? = null // VideoCallFragment when SDK is available
    
    // Configuration properties
    private var backgroundColor: String? = null
    private var textColor: String? = null
    private var pipViewBorderColor: String? = null
    private var notificationLabelDefault: String? = null
    private var notificationLabelCountdown: String? = null
    private var notificationLabelTokenFetch: String? = null

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
            ) { _, method, args ->
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
                    "getCredentials" -> getCredentials()
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
            val newInstanceMethod = vcFragmentClass.getMethod("newInstance", operatorInterface)
            val fragment = newInstanceMethod.invoke(null, proxy) as androidx.fragment.app.Fragment
            
            // Add fragment to activity
            activity.supportFragmentManager.beginTransaction()
                .replace(android.R.id.content, fragment)
                .addToBackStack("video_call")
                .commit()
            
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

            // Remove fragment if it exists
            (videoCallFragment as? androidx.fragment.app.Fragment)?.let { fragment ->
                try {
                    fragment.parentFragmentManager.beginTransaction()
                        .remove(fragment)
                        .commit()
                } catch (e: Exception) {
                    android.util.Log.w("VideoCallOperator", "Failed to remove fragment: ${e.message}")
                }
            }

            videoCallFragment = null
            true
        } catch (e: Exception) {
            notifyError("ERR_UNKNOWN", "Failed to end video call: ${e.message}")
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
    }
    
    fun onCallEnded() {
        currentStatus = "completed"
        notifyStatusChanged("completed")
        android.util.Log.d("VideoCallOperator", "onCallEnded called")
    }
    
    fun didChangeUserState(userState: Any) {
        android.util.Log.d("VideoCallOperator", "didChangeUserState: $userState")
    }
    
    fun didChangeParticipantState(participantState: Any) {
        android.util.Log.d("VideoCallOperator", "didChangeParticipantState: $participantState")
    }
    
    fun didFailWithError(error: String) {
        currentStatus = "failed"
        notifyError("ERR_SDK", error)
        android.util.Log.e("VideoCallOperator", "didFailWithError: $error")
    }

    fun setConfig(
        backgroundColor: String? = null,
        textColor: String? = null,
        pipViewBorderColor: String? = null,
        notificationLabelDefault: String? = null,
        notificationLabelCountdown: String? = null,
        notificationLabelTokenFetch: String? = null
    ) {
        this.backgroundColor = backgroundColor
        this.textColor = textColor
        this.pipViewBorderColor = pipViewBorderColor
        this.notificationLabelDefault = notificationLabelDefault
        this.notificationLabelCountdown = notificationLabelCountdown
        this.notificationLabelTokenFetch = notificationLabelTokenFetch

        // Apply configuration to the Udentify VideoCallFragment if available
        try {
            val fragment = videoCallFragment ?: return
            
            // Use reflection to apply configuration to the VideoCallFragment
            backgroundColor?.let { color ->
                val setBackgroundMethod = fragment.javaClass.getMethod("setBackgroundColor", String::class.java)
                setBackgroundMethod.invoke(fragment, color)
            }
            
            textColor?.let { color ->
                val setTextColorMethod = fragment.javaClass.getMethod("setTextColor", String::class.java)
                setTextColorMethod.invoke(fragment, color)
            }
            
            pipViewBorderColor?.let { color ->
                val setPipBorderColorMethod = fragment.javaClass.getMethod("setPipViewBorderColor", String::class.java)
                setPipBorderColorMethod.invoke(fragment, color)
            }
            
            // Apply notification labels
            notificationLabelDefault?.let { label ->
                val setDefaultLabelMethod = fragment.javaClass.getMethod("setNotificationLabelDefault", String::class.java)
                setDefaultLabelMethod.invoke(fragment, label)
            }
            
            notificationLabelCountdown?.let { label ->
                val setCountdownLabelMethod = fragment.javaClass.getMethod("setNotificationLabelCountdown", String::class.java)
                setCountdownLabelMethod.invoke(fragment, label)
            }
            
            notificationLabelTokenFetch?.let { label ->
                val setTokenFetchLabelMethod = fragment.javaClass.getMethod("setNotificationLabelTokenFetch", String::class.java)
                setTokenFetchLabelMethod.invoke(fragment, label)
            }
            
        } catch (e: Exception) {
            android.util.Log.w("VideoCallOperator", "Failed to apply configuration: ${e.message}")
        }
    }

    fun toggleCamera(): Boolean {
        return try {
            if (!isUdentifySDKAvailable()) {
                android.util.Log.e("VideoCallOperator", "SDK not available for camera toggle")
                return false
            }
            
            // Use reflection to call SDK camera toggle method
            val fragment = videoCallFragment ?: return false
            val toggleMethod = fragment.javaClass.getMethod("toggleCamera")
            toggleMethod.invoke(fragment) as? Boolean ?: false
        } catch (e: Exception) {
            android.util.Log.e("VideoCallOperator", "Failed to toggle camera: ${e.message}")
            false
        }
    }

    fun switchCamera(): Boolean {
        return try {
            if (!isUdentifySDKAvailable()) {
                android.util.Log.e("VideoCallOperator", "SDK not available for camera switch")
                return false
            }
            
            // Use reflection to call SDK camera switch method
            val fragment = videoCallFragment ?: return false
            val switchMethod = fragment.javaClass.getMethod("switchCamera")
            switchMethod.invoke(fragment) as? Boolean ?: false
        } catch (e: Exception) {
            android.util.Log.e("VideoCallOperator", "Failed to switch camera: ${e.message}")
            false
        }
    }

    fun toggleMicrophone(): Boolean {
        return try {
            if (!isUdentifySDKAvailable()) {
                android.util.Log.e("VideoCallOperator", "SDK not available for microphone toggle")
                return false
            }
            
            // Use reflection to call SDK microphone toggle method
            val fragment = videoCallFragment ?: return false
            val toggleMethod = fragment.javaClass.getMethod("toggleMicrophone")
            toggleMethod.invoke(fragment) as? Boolean ?: false
        } catch (e: Exception) {
            android.util.Log.e("VideoCallOperator", "Failed to toggle microphone: ${e.message}")
            false
        }
    }

    fun dismissVideoCall() {
        // When Udentify SDK is available, dismiss the video call UI
        endVideoCall()
    }



    private fun notifyStatusChanged(status: String) {
        try {
            channel?.invokeMethod("onStatusChanged", status)
        } catch (e: Exception) {
            // Handle error silently
        }
    }

    private fun notifyError(type: String, message: String) {
        try {
            val errorMap = mapOf(
                "type" to type,
                "message" to message
            )
            channel?.invokeMethod("onError", errorMap)
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
        override fun createFromParcel(parcel: Parcel): VideoCallOperatorImpl {
            return VideoCallOperatorImpl(parcel)
        }

        override fun newArray(size: Int): Array<VideoCallOperatorImpl?> {
            return arrayOfNulls(size)
        }
    }
}
