package com.livenessflutter

data class FaceRecognizerCredentials(
    val serverURL: String,
    val transactionID: String,
    val userID: String,
    val autoTake: Boolean = true,
    val errorDelay: Float = 0.10f,
    val successDelay: Float = 0.75f,
    val runInBackground: Boolean = false,
    val blinkDetectionEnabled: Boolean = false,
    val requestTimeout: Int = 10,
    val eyesOpenThreshold: Float = 0.75f,
    val maskConfidence: Double = 0.95,
    val invertedAnimation: Boolean = false,
    val activeLivenessAutoNextEnabled: Boolean = true,
    val listName: String? = null,
    // null keeps the plugin's existing default (0.95f); a value is passed through to the SDK.
    val activeLivenessOpacity: Float? = null
)
