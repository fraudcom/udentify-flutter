package com.livenessflutter

import android.app.Activity
import android.os.Handler
import android.os.Looper
import android.util.Log
import androidx.fragment.app.FragmentActivity
import io.flutter.plugin.common.MethodChannel

/**
 * The face SDK reports a failure as a string. Some failures arrive as the SDK's own error name (its
 * `ERR_*` string resources, whose English value is the name itself: `ERR_FACEKEY_NOT_ALIVE`,
 * `ERR_FACE_PHOTO_MISSING`, ...). When one does, that name is the code, so the error reads as the SDK
 * documents it. Anything else keeps the wrapper code it always had.
 */
internal fun sdkErrorCode(message: String?, fallback: String): String =
    if (message != null && SDK_ERROR_NAME.matches(message)) message else fallback

private val SDK_ERROR_NAME = Regex("^ERR_[A-Z0-9_]+$")

/**
 * Wrapper to integrate with Udentify Face SDK when available.
 * Falls back to simulation if SDK classes are missing.
 */
class FaceRecognizerImpl(
    private val credentials: FaceRecognizerCredentials,
    private val channel: MethodChannel
) {
    private var inProgress: Boolean = false
    private var currentActivity: androidx.fragment.app.FragmentActivity? = null
    private var currentCredentials: FaceRecognizerCredentials? = null

    fun isInProgress(): Boolean = inProgress

    fun cancelFaceRecognition() {
        inProgress = false
    }

    fun startFaceRecognitionWithCamera(activity: FragmentActivity, method: FaceRecognitionMethod): Boolean {
        // Store activity reference for dismissal on failures
        currentActivity = activity
        return try {
            val methodEnum = Class.forName("io.udentify.android.face.activities.Method")
            val methodConst = when (method) {
                FaceRecognitionMethod.REGISTER -> methodEnum.getField("Register").get(null)
                FaceRecognitionMethod.AUTHENTICATION -> methodEnum.getField("Authentication").get(null)
                FaceRecognitionMethod.ACTIVE_LIVENESS -> methodEnum.getField("ActiveLiveness").get(null)
                FaceRecognitionMethod.HYBRID_LIVENESS -> methodEnum.getField("HybridLiveness").get(null)
                FaceRecognitionMethod.IDENTIFICATION -> methodEnum.getField("Identification").get(null)
            }

            val faceRecognizerInterface = Class.forName("io.udentify.android.face.activities.FaceRecognizer")
            val credsObj = buildFaceCredentials()
            val recognizer = java.lang.reflect.Proxy.newProxyInstance(
                        faceRecognizerInterface.classLoader,
                        arrayOf(faceRecognizerInterface)
            ) { _, m, args ->
                when (m.name) {
                    "onFaceDirectiveChanged" -> {
                        Handler(Looper.getMainLooper()).post {
                            channel.invokeMethod("onFaceDirectiveChanged", mapOf("directive" to args?.getOrNull(0)?.toString()))
                        }
                    }
                            "onResult" -> {
                        Log.i(TAG, "🎉 Face recognition completed successfully!")

                        // Extract actual HTTP response from SDK args
                        val serverResponse = args?.getOrNull(0)
                        Log.i(TAG, "📡 HTTP Response received from server:")

                        val detailedResponse = extractDetailedResponse(serverResponse)

                        val resultMap = convertServerResponseToMap(detailedResponse)
                        
                        Handler(Looper.getMainLooper()).post { channel.invokeMethod("onResult", resultMap) }
                        inProgress = false
                            }
                            "onFailure" -> {
                        val errorMessage = args?.getOrNull(0)?.toString() ?: "Unknown error"
                        Log.e(TAG, "❌ Face recognition failed: $errorMessage")
                        Log.i(TAG, "🚪 Dismissing liveness screen due to failure...")
                        
                        // CRITICAL: Properly dismiss just the face recognition fragment, not the entire app
                        Handler(Looper.getMainLooper()).post {
                            try {
                                if (currentActivity != null) {
                                    Log.i(TAG, "🔍 Looking for face recognition fragment to dismiss...")
                                    
                                    // Find the face recognition fragment by its tag
                                    val fragmentManager = currentActivity?.supportFragmentManager
                                    val faceFragment = fragmentManager?.findFragmentByTag("face_camera_fragment")
                                    
                                    if (faceFragment != null) {
                                        Log.i(TAG, "✅ Found face recognition fragment, removing it...")
                                        
                                        // Remove the fragment and pop from back stack
                                        fragmentManager?.beginTransaction()
                                            ?.remove(faceFragment)
                                            ?.commitAllowingStateLoss()
                                        
                                        // Also pop from back stack if it exists
                                        if (fragmentManager?.backStackEntryCount ?: 0 > 0) {
                                            fragmentManager?.popBackStack()
                                        }
                                        
                                        Log.i(TAG, "✅ Successfully dismissed face recognition fragment")
                                    } else {
                                        Log.w(TAG, "⚠️ Face recognition fragment not found")
                                    }
                                } else {
                                    Log.w(TAG, "⚠️ No activity reference available")
                                }
                                
                            } catch (e: Exception) {
                                Log.e(TAG, "❌ Error dismissing face recognition fragment: ${e.message}")
                            }
                        }
                        
                        val errorMap = hashMapOf<String, Any?>(
                            "code" to sdkErrorCode(errorMessage, "ERR_SDK"),
                            "message" to errorMessage
                        )
                        Handler(Looper.getMainLooper()).post { 
                            channel.invokeMethod("onFailure", errorMap)
                        }
                        inProgress = false
                    }
                    "onPhotoTaken" -> {
                        Handler(Looper.getMainLooper()).post { 
                            Log.i(TAG, "🤖 Android: Auto-closing liveness camera immediately after photo taken")
                            // Dismiss the face recognition fragment immediately when photo is taken
                            try {
                                if (currentActivity != null) {
                                    val fragmentManager = currentActivity?.supportFragmentManager
                                    val faceFragment = fragmentManager?.findFragmentByTag("face_camera_fragment")
                                    
                                    if (faceFragment != null) {
                                        Log.i(TAG, "✅ Found liveness camera fragment, dismissing it...")
                                        fragmentManager?.beginTransaction()
                                            ?.remove(faceFragment)
                                            ?.commitAllowingStateLoss()
                                        
                                        if (fragmentManager?.backStackEntryCount ?: 0 > 0) {
                                            fragmentManager?.popBackStack()
                                        }
                                    }
                                }
                            } catch (e: Exception) {
                                Log.e(TAG, "❌ Error dismissing liveness camera after photo taken: ${e.message}")
                            }
                            
                            channel.invokeMethod("onPhotoTaken", null) 
                        }
                    }
                    "onSelfieTaken" -> Handler(Looper.getMainLooper()).post {
                        val base64 = (args?.getOrNull(0)?.toString())
                        channel.invokeMethod("onSelfieTaken", mapOf("base64Image" to base64))
                    }
                    "getCredentials" -> {
                        if (credsObj != null) {
                            Log.d(TAG, "✅ Returning face credentials object")
                        } else {
                            Log.e(TAG, "❌ Face credentials object is null - SDK may crash!")
                        }
                        return@newProxyInstance credsObj
                    }
                }
                null
            }

            val fragmentClass = Class.forName("io.udentify.android.face.activities.FaceCameraFragment")
            val newInstance = fragmentClass.getMethod("newInstance", methodEnum, faceRecognizerInterface)
            val fragment = newInstance.invoke(null, methodConst, recognizer) as androidx.fragment.app.Fragment

            activity.supportFragmentManager.beginTransaction()
                .replace(android.R.id.content, fragment, "face_camera_fragment")
                .addToBackStack("face_camera_fragment")
                .commitAllowingStateLoss()
            inProgress = true
            true
        } catch (e: Throwable) {
            Log.w(TAG, "startFaceRecognitionWithCamera error", e)
            false
        }
    }

    fun startActiveLiveness(activity: FragmentActivity, isAuthentication: Boolean = false): Boolean {
        currentActivity = activity
        Log.i(TAG, "🎭 Starting Active Liveness using ActiveLivenessFragment")
        Log.i(TAG, "🔧 Active Liveness isAuthentication: $isAuthentication")

        return try {
            val methodEnum = Class.forName("io.udentify.android.face.activities.Method")
            val methodConst = methodEnum.getField("ActiveLiveness").get(null)
            val faceRecognizerInterface = Class.forName("io.udentify.android.face.activities.FaceRecognizer")
            val activeLivenessOperatorInterface = Class.forName("io.udentify.android.face.activities.ActiveLivenessOperator")

            val credsObj = buildFaceCredentials()

            // Create FaceRecognizer proxy
            val recognizer = java.lang.reflect.Proxy.newProxyInstance(
                faceRecognizerInterface.classLoader,
                arrayOf(faceRecognizerInterface)
            ) { _, m, args ->
                when (m.name) {
                    "onFaceDirectiveChanged" -> {
                        Handler(Looper.getMainLooper()).post {
                            channel.invokeMethod("onFaceDirectiveChanged", mapOf("directive" to args?.getOrNull(0)?.toString()))
                        }
                    }
                    "getCredentials" -> {
                        Log.d(TAG, "✅ Returning face credentials object")
                        return@newProxyInstance credsObj
                    }
                    else -> {
                        Log.d(TAG, "🔧 FaceRecognizer method called: ${m.name}")
                        null
                    }
                }
            }

            // Create ActiveLivenessOperator proxy
            val activeLivenessOperator = java.lang.reflect.Proxy.newProxyInstance(
                activeLivenessOperatorInterface.classLoader,
                arrayOf(activeLivenessOperatorInterface)
            ) { _, m, args ->
                when (m.name) {
                    "onActiveLivenessDirectiveChanged" -> {
                        Handler(Looper.getMainLooper()).post {
                            channel.invokeMethod("onActiveLivenessDirectiveChanged", mapOf("directive" to args?.getOrNull(0)?.toString()))
                        }
                    }
                    "onVideoTaken" -> forwardVideoTaken()
                    "activeLivenessResult" -> {
                        Log.i(TAG, "🎉 Active Liveness completed successfully!")
                        val serverResponse = args?.getOrNull(0)

                        val detailedResponse = extractDetailedResponse(serverResponse)

                        val resultMap = convertServerResponseToMap(detailedResponse)

                        // Use specific ActiveLivenessOperator callback for active liveness
                        Handler(Looper.getMainLooper()).post {
                            channel.invokeMethod("onActiveLivenessResult", resultMap)
                            inProgress = false
                        }
                        
                        // Dismiss the fragment
                        try {
                            currentActivity?.let { activity ->
                                val fragmentManager = activity.supportFragmentManager
                                val fragment = fragmentManager.findFragmentByTag("active_liveness_fragment")
                                
                                fragment?.let {
                                    fragmentManager.beginTransaction()
                                        .remove(it)
                                        .commitAllowingStateLoss()
                                    
                                    if (fragmentManager.backStackEntryCount > 0) {
                                        fragmentManager.popBackStack()
                                    }
                                }
                            }
                        } catch (e: Exception) {
                            Log.e(TAG, "❌ Error dismissing fragment: ${e.message}")
                        }
                        Unit
                    }
                    "activeLivenessFailure" -> {
                        val errorMessage = args?.getOrNull(0)?.toString() ?: "Active Liveness failed"
                        Log.e(TAG, "❌ Active Liveness failed: $errorMessage")
                        
                        val errorMap = hashMapOf<String, Any?>(
                            "code" to sdkErrorCode(errorMessage, "ERR_ACTIVE_LIVENESS"),
                            "message" to errorMessage
                        )
                        
                        // Use specific ActiveLivenessOperator callback for active liveness
                        Handler(Looper.getMainLooper()).post {
                            channel.invokeMethod("onActiveLivenessFailure", errorMap)
                            inProgress = false
                        }
                        
                        // Dismiss the fragment
                        try {
                            currentActivity?.let { activity ->
                                val fragmentManager = activity.supportFragmentManager
                                val fragment = fragmentManager.findFragmentByTag("active_liveness_fragment")
                                
                                fragment?.let {
                                    fragmentManager.beginTransaction()
                                        .remove(it)
                                        .commitAllowingStateLoss()
                                    
                                    if (fragmentManager.backStackEntryCount > 0) {
                                        fragmentManager.popBackStack()
                                    }
                                }
                            }
                        } catch (e: Exception) {
                            Log.e(TAG, "❌ Error dismissing fragment: ${e.message}")
                        }
                        Unit
                    }
                    else -> {
                        Log.d(TAG, "🔧 ActiveLivenessOperator method called: ${m.name}")
                        null
                    }
                }
            }

            // Create ActiveLivenessFragment exactly as documented
            val fragmentClass = Class.forName("io.udentify.android.face.activities.ActiveLivenessFragment")
            val newInstanceMethod = fragmentClass.getMethod(
                "newInstance",
                methodEnum,
                Boolean::class.javaObjectType,
                faceRecognizerInterface,
                activeLivenessOperatorInterface
            )
            
            val fragment = newInstanceMethod.invoke(
                null, // Static method, so null for instance
                methodConst,
                isAuthentication, // registrationType: false for registration, true for authentication
                recognizer,
                activeLivenessOperator
            ) as androidx.fragment.app.Fragment

            activity.supportFragmentManager.beginTransaction()
                .replace(android.R.id.content, fragment, "active_liveness_fragment")
                .addToBackStack("active_liveness_fragment")
                .commitAllowingStateLoss()
            inProgress = true
            true
        } catch (e: Throwable) {
            Log.e(TAG, "❌ startActiveLiveness error: ${e.message}", e)
            false
        }
    }

    fun registerUserWithPhoto(activity: Activity, base64Image: String): Boolean {
        return try {
            val faceRecognizerInterface = Class.forName("io.udentify.android.face.activities.FaceRecognizer")
            val credsObj = buildFaceCredentials()
            val recognizer = java.lang.reflect.Proxy.newProxyInstance(
                faceRecognizerInterface.classLoader,
                arrayOf(faceRecognizerInterface)
            ) { _, m, args ->
                when (m.name) {
                    "onFaceDirectiveChanged" -> {
                        Handler(Looper.getMainLooper()).post {
                            channel.invokeMethod("onFaceDirectiveChanged", mapOf("directive" to args?.getOrNull(0)?.toString()))
                        }
                    }
                    "onResult" -> {
                        val serverResponse = args?.getOrNull(0)
                        Log.i(TAG, "🎉 Photo-based registration completed")
                        val detailedResponse = extractDetailedResponse(serverResponse)
                        val resultMap = convertServerResponseToMap(detailedResponse)
                        Handler(Looper.getMainLooper()).post { channel.invokeMethod("onResult", resultMap) }
                        inProgress = false
                    }
                    "onFailure" -> {
                        val errorMap = hashMapOf<String, Any?>("code" to sdkErrorCode(args?.getOrNull(0)?.toString(), "ERR_SDK"), "message" to (args?.getOrNull(0)?.toString() ?: "Unknown error"))
                        Handler(Looper.getMainLooper()).post { channel.invokeMethod("onFailure", errorMap) }
                        inProgress = false
                    }
                    "onSelfieTaken" -> Handler(Looper.getMainLooper()).post { channel.invokeMethod("onSelfieTaken", hashMapOf<String, Any?>("base64Image" to base64Image)) }
                    "getCredentials" -> {
                        if (credsObj != null) {
                            Log.d(TAG, "✅ Returning face credentials object")
                        } else {
                            Log.e(TAG, "❌ Face credentials object is null - SDK may crash!")
                        }
                        return@newProxyInstance credsObj
                    }
                }
                null
            }

            val clazz = Class.forName("io.udentify.android.face.activities.FaceRecognizerObject")
            val ctor = clazz.getConstructor(faceRecognizerInterface, Activity::class.java, String::class.java)
            val instance = ctor.newInstance(recognizer, activity, base64Image)
            val registerMethod = clazz.getMethod("registerUser")
            registerMethod.invoke(instance)
            inProgress = true
            true
        } catch (e: Throwable) {
            Log.w(TAG, "registerUserWithPhoto error", e)
            false
        }
    }

    fun authenticateUserWithPhoto(activity: Activity, base64Image: String): Boolean {
        return try {
            val faceRecognizerInterface = Class.forName("io.udentify.android.face.activities.FaceRecognizer")
            val credsObj = buildFaceCredentials()
            val recognizer = java.lang.reflect.Proxy.newProxyInstance(
            faceRecognizerInterface.classLoader,
            arrayOf(faceRecognizerInterface)
            ) { _, m, args ->
                when (m.name) {
                    "onFaceDirectiveChanged" -> {
                        Handler(Looper.getMainLooper()).post {
                            channel.invokeMethod("onFaceDirectiveChanged", mapOf("directive" to args?.getOrNull(0)?.toString()))
                        }
                    }
                "onResult" -> {
                        val serverResponse = args?.getOrNull(0)
                        Log.i(TAG, "🎉 Photo-based authentication completed")
                        val detailedResponse = extractDetailedResponse(serverResponse)
                        val resultMap = convertServerResponseToMap(detailedResponse)
                        Handler(Looper.getMainLooper()).post { channel.invokeMethod("onResult", resultMap) }
                        inProgress = false
                }
                "onFailure" -> {
                        val errorMap = hashMapOf<String, Any?>("code" to sdkErrorCode(args?.getOrNull(0)?.toString(), "ERR_SDK"), "message" to (args?.getOrNull(0)?.toString() ?: "Unknown error"))
                        Handler(Looper.getMainLooper()).post { channel.invokeMethod("onFailure", errorMap) }
                        inProgress = false
                    }
                    "onSelfieTaken" -> Handler(Looper.getMainLooper()).post { channel.invokeMethod("onSelfieTaken", hashMapOf<String, Any?>("base64Image" to base64Image)) }
                    "getCredentials" -> {
                        if (credsObj != null) {
                            Log.d(TAG, "✅ Returning face credentials object")
                        } else {
                            Log.e(TAG, "❌ Face credentials object is null - SDK may crash!")
                        }
                        return@newProxyInstance credsObj
                    }
                }
                null
            }

            val clazz = Class.forName("io.udentify.android.face.activities.FaceRecognizerObject")
            val ctor = clazz.getConstructor(faceRecognizerInterface, Activity::class.java, String::class.java)
            val instance = ctor.newInstance(recognizer, activity, base64Image)
            val authMethod = clazz.getMethod("authenticateUser")
            authMethod.invoke(instance)
            inProgress = true
            true
        } catch (e: Throwable) {
            Log.w(TAG, "authenticateUserWithPhoto error", e)
            false
        }
    }

    fun startHybridLiveness(activity: FragmentActivity, isAuthentication: Boolean): Boolean {
        // Store activity reference for dismissal on failures
        currentActivity = activity
        Log.i(TAG, "🎭 Starting Hybrid Liveness using ActiveLivenessFragment (isAuthentication: $isAuthentication)")
        return try {
            val methodEnum = Class.forName("io.udentify.android.face.activities.Method")
            val methodConst = methodEnum.getField("HybridLiveness").get(null)

            val faceRecognizerInterface = Class.forName("io.udentify.android.face.activities.FaceRecognizer")
            val activeOpInterface = Class.forName("io.udentify.android.face.activities.ActiveLivenessOperator")
            val credsObj = buildFaceCredentials()

            // The fragment reads its credentials and directive updates from this recognizer; the outcome
            // arrives on the operator below (the fragment never calls the recognizer's result callbacks).
            val recognizer = java.lang.reflect.Proxy.newProxyInstance(
                faceRecognizerInterface.classLoader,
                arrayOf(faceRecognizerInterface)
            ) { _, m, args ->
                when (m.name) {
                    "onFaceDirectiveChanged" -> {
                        Handler(Looper.getMainLooper()).post {
                            channel.invokeMethod("onFaceDirectiveChanged", mapOf("directive" to args?.getOrNull(0)?.toString()))
                        }
                    }
                    "getCredentials" -> {
                        if (credsObj == null) Log.e(TAG, "❌ Face credentials object is null - SDK may crash!")
                        return@newProxyInstance credsObj
                    }
                }
                null
            }

            val activeOperator = java.lang.reflect.Proxy.newProxyInstance(
                activeOpInterface.classLoader,
                arrayOf(activeOpInterface)
            ) { _, m, args ->
                when (m.name) {
                    "onActiveLivenessDirectiveChanged" -> {
                        Handler(Looper.getMainLooper()).post {
                            channel.invokeMethod("onActiveLivenessDirectiveChanged", mapOf("directive" to args?.getOrNull(0)?.toString()))
                        }
                    }
                    "onVideoTaken" -> forwardVideoTaken()
                    "activeLivenessResult" -> {
                        Log.i(TAG, "🎉 Hybrid Liveness completed successfully!")

                        val serverResponse = args?.getOrNull(0)
                        val detailedResponse = extractDetailedResponse(serverResponse)
                        val resultMap = convertServerResponseToMap(detailedResponse)

                        // Use specific ActiveLivenessOperator callback for hybrid liveness
                        Handler(Looper.getMainLooper()).post {
                            channel.invokeMethod("onActiveLivenessResult", resultMap)
                            inProgress = false
                        }

                        dismissCurrentFragment("hybrid_liveness_fragment")
                    }
                    "activeLivenessFailure" -> {
                        val errorMessage = args?.getOrNull(0)?.toString() ?: "Hybrid liveness failed"
                        Log.e(TAG, "❌ Hybrid Liveness failed: $errorMessage")

                        val errorMap = hashMapOf<String, Any?>(
                            "code" to sdkErrorCode(errorMessage, "ERR_HYBRID_LIVENESS"),
                            "message" to errorMessage
                        )

                        // Use specific ActiveLivenessOperator callback for hybrid liveness
                        Handler(Looper.getMainLooper()).post {
                            channel.invokeMethod("onActiveLivenessFailure", errorMap)
                            inProgress = false
                        }

                        dismissCurrentFragment("hybrid_liveness_fragment")
                    }
                }
                null
            }

            val fragmentClass = Class.forName("io.udentify.android.face.activities.ActiveLivenessFragment")
            val newInstance = fragmentClass.getMethod(
                "newInstance",
                methodEnum,
                Boolean::class.javaObjectType,
                faceRecognizerInterface,
                activeOpInterface
            )
            val fragment = newInstance.invoke(
                null, // Static method, so null for instance
                methodConst,
                isAuthentication,
                recognizer,
                activeOperator
            ) as androidx.fragment.app.Fragment

            activity.supportFragmentManager.beginTransaction()
                .replace(android.R.id.content, fragment, "hybrid_liveness_fragment")
                .addToBackStack("hybrid_liveness_fragment")
                .commitAllowingStateLoss()
            inProgress = true
            true
        } catch (e: Throwable) {
            Log.w(TAG, "startHybridLiveness error", e)
            false
        }
    }

    // The SDK reports the end of the active/hybrid recording through the operator's onVideoTaken (the
    // recognizer's onPhotoTaken is never called for these flows). Dart gets both events, as on iOS.
    private fun forwardVideoTaken() {
        Handler(Looper.getMainLooper()).post {
            channel.invokeMethod("onPhotoTaken", null)
            channel.invokeMethod("onVideoTaken", null)
        }
    }

    private fun buildFaceCredentials(): Any? {
        return try {
            Log.i(TAG, "🔧 Building FaceRecognizerCredentials using proper SDK Builder pattern")
            
            // Use the actual SDK Builder as documented
            val builderClass = Class.forName("io.udentify.android.face.FaceRecognizerCredentials\$Builder")
            var builder = builderClass.getDeclaredConstructor().newInstance()
            
            Log.d(TAG, "📝 Setting credential values following SDK documentation pattern...")
            
            // Build credentials exactly as shown in documentation
            // FaceRecognizerCredentials credentials = new FaceRecognizerCredentials.Builder()
            //     .serverURL("https://...")
            //     .transactionID("TRX...")
            //     .userID(userId)
            //     .maskConfidence(0.95)
            //     // ... other methods
            //     .build();
            
            builder = builderClass.getMethod("serverURL", String::class.java).invoke(builder, credentials.serverURL)
            builder = builderClass.getMethod("transactionID", String::class.java).invoke(builder, credentials.transactionID)
            builder = builderClass.getMethod("userID", String::class.java).invoke(builder, credentials.userID)
            
            // Optional parameters with proper types as documented
            builder = builderClass.getMethod("autoTake", Boolean::class.javaPrimitiveType).invoke(builder, credentials.autoTake)
            builder = builderClass.getMethod("errorDelay", Float::class.javaPrimitiveType).invoke(builder, credentials.errorDelay)
            builder = builderClass.getMethod("successDelay", Float::class.javaPrimitiveType).invoke(builder, credentials.successDelay)
            builder = builderClass.getMethod("runInBackground", Boolean::class.javaPrimitiveType).invoke(builder, credentials.runInBackground)
            builder = builderClass.getMethod("blinkDetectionEnabled", Boolean::class.javaPrimitiveType).invoke(builder, credentials.blinkDetectionEnabled)
            builder = builderClass.getMethod("requestTimeout", Int::class.javaPrimitiveType).invoke(builder, credentials.requestTimeout)
            builder = builderClass.getMethod("eyesOpenThreshold", Float::class.javaPrimitiveType).invoke(builder, credentials.eyesOpenThreshold)
            // The SDK's setter takes a boxed java.lang.Double; a primitive-double lookup throws NoSuchMethodException.
            builder = builderClass.getMethod("maskConfidence", Double::class.javaObjectType).invoke(builder, credentials.maskConfidence)
            builder = builderClass.getMethod("invertedAnimation", Boolean::class.javaPrimitiveType).invoke(builder, credentials.invertedAnimation)
            builder = builderClass.getMethod("activeLivenessAutoNextEnabled", Boolean::class.javaPrimitiveType).invoke(builder, credentials.activeLivenessAutoNextEnabled)
            
            // Set active liveness opacity for better user face visibility (0.95f = 95% opacity, 5% transparency)
            builder = builderClass.getMethod("activeLivenessOpacity", Float::class.javaPrimitiveType).invoke(builder, credentials.activeLivenessOpacity ?: 0.95f)

            // Set listName for identification flows (which list to search/match against)
            if (credentials.listName != null) {
                try {
                    builder = builderClass.getMethod("listName", String::class.java).invoke(builder, credentials.listName)
                    Log.d(TAG, "✅ Set listName to ${credentials.listName}")
                } catch (e: Exception) {
                    Log.w(TAG, "⚠️ Could not set listName: ${e.message}")
                }
            }

            // Build the final credentials object
            val credentialsObj = builderClass.getMethod("build").invoke(builder)
            
            if (credentialsObj != null) {
                Log.i(TAG, "✅ FaceRecognizerCredentials built successfully using SDK Builder")
                
                // Test that maskConfidence is properly set (this was the source of the crash)
                try {
                    val maskConfidenceMethod = credentialsObj.javaClass.getMethod("getMaskConfidence")
                    val maskConfidenceValue = maskConfidenceMethod.invoke(credentialsObj)
                    Log.d(TAG, "🎯 MaskConfidence value: $maskConfidenceValue (should not be null)")
                } catch (e: Exception) {
                    Log.w(TAG, "⚠️ Could not verify maskConfidence value: ${e.message}")
                }
                
            } else {
                Log.e(TAG, "❌ Built credentials object is null!")
            }
            
            credentialsObj
        } catch (e: Throwable) {
            Log.e(TAG, "❌ Failed to build FaceRecognizerCredentials with SDK Builder", e)
            Log.i(TAG, "🔄 Attempting to create minimal working credentials object...")
            createMinimalCredentials()
        }
    }
    
    private fun createMinimalCredentials(): Any? {
        return try {
            Log.w(TAG, "🔄 Creating minimal credentials object with essential fields only")
            
            // Try to create minimal working credentials using the Builder pattern
            val builderClass = Class.forName("io.udentify.android.face.FaceRecognizerCredentials\$Builder")
            var builder = builderClass.getDeclaredConstructor().newInstance()
            
            Log.d(TAG, "📝 Setting only essential credential values...")
            
            // Set only the most essential fields to avoid any method signature issues
            try {
                builder = builderClass.getMethod("serverURL", String::class.java).invoke(builder, credentials.serverURL ?: "")
                builder = builderClass.getMethod("transactionID", String::class.java).invoke(builder, credentials.transactionID ?: "")
                builder = builderClass.getMethod("userID", String::class.java).invoke(builder, credentials.userID ?: "")
                
                // The SDK's setter takes a boxed java.lang.Double.
                try {
                    builder = builderClass.getMethod("maskConfidence", Double::class.javaObjectType).invoke(builder, credentials.maskConfidence)
                    Log.d(TAG, "✅ Set maskConfidence to ${credentials.maskConfidence}")
                } catch (e: Exception) {
                    Log.w(TAG, "⚠️ Could not set maskConfidence: ${e.message}")
                }
                
                // Try to set active liveness opacity for better user face visibility
                try {
                    val opacity = credentials.activeLivenessOpacity ?: 0.95f
                    builder = builderClass.getMethod("activeLivenessOpacity", Float::class.javaPrimitiveType).invoke(builder, opacity)
                    Log.d(TAG, "✅ Set activeLivenessOpacity to $opacity")
                } catch (e: Exception) {
                    Log.w(TAG, "⚠️ Could not set activeLivenessOpacity: ${e.message}")
                }

                // Try to set listName for identification flows
                if (credentials.listName != null) {
                    try {
                        builder = builderClass.getMethod("listName", String::class.java).invoke(builder, credentials.listName)
                        Log.d(TAG, "✅ Set listName to ${credentials.listName}")
                    } catch (e: Exception) {
                        Log.w(TAG, "⚠️ Could not set listName: ${e.message}")
                    }
                }

                // Build minimal credentials
                val credentialsObj = builderClass.getMethod("build").invoke(builder)
                
                if (credentialsObj != null) {
                    Log.i(TAG, "✅ Minimal credentials created successfully")
                    
                    // Verify maskConfidence is set to prevent the original crash
                    try {
                        val maskConfidenceMethod = credentialsObj.javaClass.getMethod("getMaskConfidence")
                        val value = maskConfidenceMethod.invoke(credentialsObj)
                        Log.d(TAG, "🎯 Minimal credentials maskConfidence: $value")
                    } catch (e: Exception) {
                        Log.w(TAG, "⚠️ Could not verify minimal maskConfidence: ${e.message}")
                    }
                    
                } else {
                    Log.e(TAG, "❌ Minimal credentials object is null")
                }
                
                credentialsObj
                
            } catch (e: Exception) {
                Log.e(TAG, "❌ Failed to set essential fields in minimal credentials", e)
                null
            }
            
        } catch (e: Exception) {
            Log.e(TAG, "❌ Failed to create minimal credentials", e)
            null
        }
    }

    
    fun startSelfieCapture(activity: FragmentActivity): Boolean {
        // Store activity reference for dismissal on failures
        currentActivity = activity
        Log.i(TAG, "📸 Starting selfie capture using FaceCameraFragment with .selfie method")
        return try {
            val methodEnum = Class.forName("io.udentify.android.face.activities.Method")
            val methodConst = methodEnum.getField("Selfie").get(null)

            val faceRecognizerInterface = Class.forName("io.udentify.android.face.activities.FaceRecognizer")
            val credsObj = buildFaceCredentials()
            
            // Create proxy for FaceRecognizer callbacks
            val recognizer = java.lang.reflect.Proxy.newProxyInstance(
                faceRecognizerInterface.classLoader,
                arrayOf(faceRecognizerInterface)
            ) { _, m, args ->
                when (m.name) {
                    "onFaceDirectiveChanged" -> {
                        Handler(Looper.getMainLooper()).post {
                            channel.invokeMethod("onFaceDirectiveChanged", mapOf("directive" to args?.getOrNull(0)?.toString()))
                        }
                    }
                    "onSelfieTaken" -> {
                        val base64 = args?.getOrNull(0)?.toString()
                        Log.i(TAG, "📸 Selfie captured! Base64 length: ${base64?.length ?: 0}")
                        
                        Handler(Looper.getMainLooper()).post {
                            sendSelfieTakenEvent(base64 ?: "")
                        }
                        inProgress = false
                        
                        // Dismiss the fragment after selfie is taken
                        dismissCurrentFragment("selfie_camera_fragment")
                        null
                    }
                    "onFailure" -> {
                        val errorMessage = args?.getOrNull(0)?.toString() ?: "Selfie capture failed"
                        Log.e(TAG, "❌ Selfie capture failed: $errorMessage")
                        
                        // Dismiss the fragment
                        dismissCurrentFragment("selfie_camera_fragment")
                        
                        val errorMap = hashMapOf<String, Any?>(
                            "code" to sdkErrorCode(errorMessage, "SELFIE_CAPTURE_ERROR"),
                            "message" to errorMessage
                        )
                        Handler(Looper.getMainLooper()).post { 
                            channel.invokeMethod("onFailure", errorMap)
                        }
                        inProgress = false
                        null
                    }
                    "getCredentials" -> {
                        return@newProxyInstance credsObj
                    }
                    else -> null
                }
            }

            val fragmentClass = Class.forName("io.udentify.android.face.activities.FaceCameraFragment")
            val newInstance = fragmentClass.getMethod("newInstance", methodEnum, faceRecognizerInterface)
            val fragment = newInstance.invoke(null, methodConst, recognizer) as androidx.fragment.app.Fragment

            activity.supportFragmentManager.beginTransaction()
                .replace(android.R.id.content, fragment, "selfie_camera_fragment")
                .addToBackStack("selfie_camera_fragment")
                .commit()
            
            inProgress = true
            true
        } catch (e: Throwable) {
            Log.w(TAG, "startSelfieCapture error", e)
            false
        }
    }

    fun performFaceRecognitionWithSelfie(activity: Activity, base64Image: String, isAuthentication: Boolean): Boolean {
        currentActivity = activity as? FragmentActivity
        currentCredentials = credentials // Store credentials for result mapping
        Log.i(TAG, "🔄 Performing face recognition with selfie (isAuth: $isAuthentication)")
        Log.i(TAG, "📱 Activity: ${activity.javaClass.simpleName}")
        return try {
            val faceRecognizerInterface = Class.forName("io.udentify.android.face.activities.FaceRecognizer")
            val credsObj = buildFaceCredentials()
            val recognizer = java.lang.reflect.Proxy.newProxyInstance(
                faceRecognizerInterface.classLoader,
                arrayOf(faceRecognizerInterface)
            ) { _, m, args ->
                when (m.name) {
                    "onFaceDirectiveChanged" -> {
                        Handler(Looper.getMainLooper()).post {
                            channel.invokeMethod("onFaceDirectiveChanged", mapOf("directive" to args?.getOrNull(0)?.toString()))
                        }
                    }
                    "onResult" -> {
                        try {
                            Log.i(TAG, "\n🎉 ========== FACE RECOGNITION WITH SELFIE SUCCESS ==========")
                            Log.i(TAG, "📱 Platform: Android (Flutter)")
                            Log.i(TAG, "🔧 Operation: ${if (isAuthentication) "authentication" else "registration"}")
                            Log.i(TAG, "⏰ Timestamp: ${System.currentTimeMillis()}")
                            
                            // Extract server response data
                            val serverResponse = args?.getOrNull(0)
                            
                            val detailedResponse = extractResponseData(serverResponse)
                            
                            // Create FaceIDMessage for result mapping. Only an explicit `isFailed: false` from the SDK is a
                            // success: a response that could not be read (an empty map) or that carries no verdict is not.
                            val method = if (isAuthentication) "authentication" else "registration"
                            val succeeded = detailedResponse["isFailed"] == false
                            val resultMap = createSelfieRecognitionResultMap(
                                success = succeeded,
                                message = if (succeeded) "Face $method with selfie completed successfully"
                                          else "Face $method with selfie did not succeed",
                                data = detailedResponse,
                                isAuthentication = isAuthentication
                            )
                            
                            Log.i(TAG, "===============================================\n")
                            
                            Handler(Looper.getMainLooper()).post { 
                                channel.invokeMethod("onResult", resultMap) 
                            }
                        } catch (e: Exception) {
                            Log.e(TAG, "❌ Exception in onResult callback: ${e.message}", e)
                            // The result could not be read, so there is no verdict to report: say so as an error. A success
                            // the SDK did not give is never made up here.
                            val errorMap = hashMapOf<String, Any?>(
                                "code" to sdkErrorCode(null, "FACE_RECOGNITION_SELFIE_ERROR"),
                                "message" to "The face recognition result could not be read: ${e.message}"
                            )
                            Handler(Looper.getMainLooper()).post {
                                channel.invokeMethod("onFailure", errorMap)
                            }
                        } finally {
                            inProgress = false
                        }
                        null
                    }
                    "onFailure" -> {
                        val errorMessage = args?.getOrNull(0)?.toString() ?: "Face recognition with selfie failed"
                        Log.e(TAG, "❌ Face recognition with selfie failed: $errorMessage")
                        
                        val errorMap = hashMapOf<String, Any?>(
                            "code" to sdkErrorCode(errorMessage, "FACE_RECOGNITION_SELFIE_ERROR"),
                            "message" to errorMessage
                        )
                        Handler(Looper.getMainLooper()).post { 
                            channel.invokeMethod("onFailure", errorMap)
                        }
                        inProgress = false
                        null
                    }
                    "getCredentials" -> {
                        Log.d(TAG, "✅ Returning face credentials object for selfie processing")
                        return@newProxyInstance credsObj
                    }
                    else -> null
                }
            }

            // Use registerUser() or authenticateUser() based on operation type
            Log.i(TAG, "🔄 Using FaceRecognizerObject.${if (isAuthentication) "authenticateUser" else "registerUser"}()")
            
            // Create FaceRecognizerObject with image data
            val clazz = Class.forName("io.udentify.android.face.activities.FaceRecognizerObject")
            val ctor = clazz.getConstructor(faceRecognizerInterface, android.app.Activity::class.java, String::class.java)
            val faceRecognizerObject = ctor.newInstance(recognizer, activity, base64Image)
            
            // Call correct method based on operation type
            if (isAuthentication) {
                Log.i(TAG, "🔐 Calling authenticateUser() for authentication")
                val authMethod = clazz.getMethod("authenticateUser")
                authMethod.invoke(faceRecognizerObject)
            } else {
                Log.i(TAG, "📝 Calling registerUser() for registration")
                val registerMethod = clazz.getMethod("registerUser")
                registerMethod.invoke(faceRecognizerObject)
            }
            
            Log.i(TAG, "📤 Called ${if (isAuthentication) "authenticateUser" else "registerUser"}() method successfully")
            
            inProgress = true
            true
        } catch (e: Throwable) {
            Log.w(TAG, "performFaceRecognitionWithSelfie error", e)
            false
        }
    }

    private fun sendSelfieTakenEvent(base64Image: String) {
        Handler(Looper.getMainLooper()).post {
            val eventData = hashMapOf<String, Any?>(
                "base64Image" to base64Image
            )
            channel.invokeMethod("onSelfieTaken", eventData)
        }
    }
    
    private fun dismissCurrentFragment(tag: String) {
        try {
            currentActivity?.let { activity ->
                Handler(Looper.getMainLooper()).post {
                    val fragmentManager = activity.supportFragmentManager
                    val fragment = fragmentManager.findFragmentByTag(tag)
                    
                    fragment?.let {
                        fragmentManager.beginTransaction()
                            .remove(it)
                            .commitAllowingStateLoss()
                        
                        if (fragmentManager.backStackEntryCount > 0) {
                            fragmentManager.popBackStack()
                        }
                    }
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to dismiss fragment: ${e.message}")
        }
    }
    
    /**
     * Extract fields from an SDK response object (e.g. FaceIDMessage) via reflection.
     * Nested SDK model objects (its FaceIDResult, LivenessResult and ActiveLivenessResult) are
     * flattened one level, so real values like verified, matchScore, livenessScore and gestureResult
     * reach Dart as fields instead of a stringified object. Maps and lists stay maps and lists, an
     * enum (FaceIDMessage.method) is its name, and static or synthetic fields (an enum's constants and
     * `$VALUES`) are skipped. Every flow that reports an SDK result uses it, so all report the same
     * real SDK data.
     */
    private fun extractDetailedResponse(serverResponse: Any?): Map<String, Any?> {
        if (serverResponse == null) {
            Log.w(TAG, "⚠️ Server response object is null")
            return emptyMap()
        }
        val responseFields = mutableMapOf<String, Any?>()
        try {
            instanceFields(serverResponse).forEach { field ->
                try {
                    when (val value = field.get(serverResponse)) {
                        null, is String, is Number, is Boolean, is Map<*, *>, is List<*> ->
                            responseFields[field.name] = value
                        is Enum<*> -> responseFields[field.name] = value.name
                        else -> {
                            // Nested SDK model: flatten its own fields into the top level as well as nesting them.
                            val nestedFields = mutableMapOf<String, Any?>()
                            instanceFields(value).forEach { nestedField ->
                                try {
                                    nestedFields[nestedField.name] = when (val nestedValue = nestedField.get(value)) {
                                        null, is String, is Number, is Boolean, is Map<*, *>, is List<*> -> nestedValue
                                        is Enum<*> -> nestedValue.name
                                        else -> nestedValue.toString()
                                    }
                                } catch (e: Exception) {
                                    Log.d(TAG, "⚠️ Could not access nested field ${nestedField.name}: ${e.message}")
                                }
                            }
                            if (nestedFields.isNotEmpty()) {
                                responseFields.putAll(nestedFields)
                                responseFields[field.name] = nestedFields
                            } else {
                                responseFields[field.name] = value.toString()
                            }
                        }
                    }
                } catch (e: Exception) {
                    Log.d(TAG, "⚠️ Could not access field ${field.name}: ${e.message}")
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "❌ Error parsing server response: ${e.message}")
        }
        return responseFields
    }

    /** The instance fields of [target]: static and synthetic ones (an enum's constants, `$VALUES`) are not data. */
    private fun instanceFields(target: Any): List<java.lang.reflect.Field> =
        target.javaClass.declaredFields
            .filter { !java.lang.reflect.Modifier.isStatic(it.modifiers) && !it.isSynthetic }
            .onEach { it.isAccessible = true }

    /** The selfie flow's result data: the same extraction as every other flow. */
    private fun extractResponseData(serverResponse: Any?): Map<String, Any?> = extractDetailedResponse(serverResponse)

    private fun createSelfieRecognitionResultMap(success: Boolean, message: String, data: Map<String, Any?>, isAuthentication: Boolean): HashMap<String, Any?> {
        val resultMap = hashMapOf<String, Any?>()
        
        resultMap["status"] = if (success) "success" else "failure"
        
        data.forEach { (key, value) ->
            when (value) {
                is String -> {
                    if (value == "null") {
                        resultMap[key] = null
                    } else {
                        resultMap[key] = value
                    }
                }
                is Number -> resultMap[key] = value
                is Boolean -> resultMap[key] = value
                is Map<*, *> -> {
                    val nestedMap = hashMapOf<String, Any?>()
                    value.forEach { (nestedKey, nestedValue) ->
                        when (nestedValue) {
                            is String -> nestedMap[nestedKey.toString()] = nestedValue
                            is Number -> nestedMap[nestedKey.toString()] = nestedValue
                            is Boolean -> nestedMap[nestedKey.toString()] = nestedValue
                            else -> nestedMap[nestedKey.toString()] = nestedValue.toString()
                        }
                    }
                    resultMap[key] = nestedMap
                }
                null -> resultMap[key] = null
                else -> resultMap[key] = value.toString()
            }
        }
        
        resultMap["timestamp"] = System.currentTimeMillis()
        return resultMap
    }
    
    /**
     * Convert server response data to HashMap for method channel
     */
    private fun convertServerResponseToMap(data: Map<String, Any?>): HashMap<String, Any?> {
        val resultMap = hashMapOf<String, Any?>()
        data.forEach { (key, value) -> resultMap[key] = convertChannelValue(value, topLevel = true) }
        return resultMap
    }

    /**
     * A value the platform channel can carry: numbers as doubles, map keys as strings, maps and lists
     * converted recursively, anything else as its string. At the top level the string "null" is null.
     */
    private fun convertChannelValue(value: Any?, topLevel: Boolean = false): Any? = when (value) {
        null -> null
        is String -> if (topLevel && value == "null") null else value
        is Number -> value.toDouble()
        is Boolean -> value
        is Map<*, *> -> hashMapOf<String, Any?>().also { converted ->
            value.forEach { (nestedKey, nestedValue) -> converted[nestedKey.toString()] = convertChannelValue(nestedValue) }
        }
        is List<*> -> value.map { convertChannelValue(it) }
        else -> value.toString()
    }
    
    companion object {
        private const val TAG = "FaceRecognizerImpl"
    }
}
