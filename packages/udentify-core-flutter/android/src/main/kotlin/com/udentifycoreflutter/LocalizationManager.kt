package com.udentifycoreflutter

import android.content.Context
import android.util.Log
import io.udentify.android.commons.model.LocalizationLanguage
import io.udentify.android.commons.model.UdentifySettingsProvider
import io.udentify.android.commons.interfaces.LocalizationInstantiationListener
import java.util.Locale

class LocalizationManager(private val context: Context) {
    
    companion object {
        private const val TAG = "LocalizationManager"
    }
    
    fun instantiateServerBasedLocalization(
        language: String,
        serverUrl: String,
        transactionId: String,
        requestTimeout: Double,
        onSuccess: () -> Unit,
        onError: (String) -> Unit
    ) {
        try {
            Log.d(TAG, "instantiateServerBasedLocalization called for language: $language")
            
            val languageEnum = mapStringToLocalizationLanguage(language)
            if (languageEnum == null) {
                val errorMessage = "Invalid language code: $language"
                Log.e(TAG, "Error: $errorMessage")
                onError(errorMessage)
                return
            }
            
            Log.d(TAG, "Mapped language to enum: $languageEnum")
            
            UdentifySettingsProvider.instantiateServerBasedLocalization(
                context,
                languageEnum,
                serverUrl,
                transactionId,
                LocalizationInstantiationListener { error ->
                    if (error == null) {
                        Log.d(TAG, "Server-based localization instantiated successfully")
                        onSuccess()
                    } else {
                        Log.e(TAG, "Error instantiating localization: ${error.message}")
                        onError(error.message ?: "Unknown error")
                    }
                }
            )
            
        } catch (e: Exception) {
            Log.e(TAG, "Exception: ${e.message}", e)
            onError(e.message ?: "Unknown error")
        }
    }
    
    fun getLocalizationMap(
        onSuccess: (Map<String, String>?) -> Unit,
        onError: (String) -> Unit
    ) {
        try {
            Log.d(TAG, "getLocalizationMap called")
            
            val localizationMap = UdentifySettingsProvider.getLocalizationMap()
            
            if (localizationMap == null || localizationMap.isEmpty()) {
                Log.d(TAG, "No localization map available")
                onSuccess(null)
                return
            }
            
            Log.d(TAG, "Localization map retrieved with ${localizationMap.size} entries")
            onSuccess(localizationMap)
            
        } catch (e: Exception) {
            Log.e(TAG, "Exception: ${e.message}", e)
            onError(e.message ?: "Unknown error")
        }
    }
    
    fun clearLocalizationCache(
        language: String,
        onSuccess: () -> Unit,
        onError: (String) -> Unit
    ) {
        try {
            Log.d(TAG, "clearLocalizationCache called for language: $language")
            
            val languageEnum = mapStringToLocalizationLanguage(language)
            if (languageEnum == null) {
                val errorMessage = "Invalid language code: $language"
                Log.e(TAG, "Error: $errorMessage")
                onError(errorMessage)
                return
            }
            
            UdentifySettingsProvider.clearLocalizationCache(context, languageEnum)
            
            Log.d(TAG, "Localization cache cleared successfully")
            onSuccess()
            
        } catch (e: Exception) {
            Log.e(TAG, "Exception: ${e.message}", e)
            onError(e.message ?: "Unknown error")
        }
    }
    
    fun mapSystemLanguageToEnum(
        onSuccess: (String?) -> Unit,
        onError: (String) -> Unit
    ) {
        try {
            Log.d(TAG, "mapSystemLanguageToEnum called")
            
            val systemLanguage = Locale.getDefault().language.uppercase()
            Log.d(TAG, "System language code: $systemLanguage")
            
            val languageEnum = mapStringToLocalizationLanguage(systemLanguage)
            
            if (languageEnum == null) {
                Log.d(TAG, "System language not supported, defaulting to null")
                onSuccess(null)
                return
            }
            
            val languageString = mapLocalizationLanguageToString(languageEnum)
            Log.d(TAG, "System language mapped to: $languageString")
            onSuccess(languageString)
            
        } catch (e: Exception) {
            Log.e(TAG, "Exception: ${e.message}", e)
            onError(e.message ?: "Unknown error")
        }
    }
    
    private fun mapStringToLocalizationLanguage(language: String): LocalizationLanguage? {
        return when (language.uppercase()) {
            "EN" -> LocalizationLanguage.EN
            "ES" -> LocalizationLanguage.ES
            "FR" -> LocalizationLanguage.FR
            "DE" -> LocalizationLanguage.DE
            "IT" -> LocalizationLanguage.IT
            "PT" -> LocalizationLanguage.PT
            "RU" -> LocalizationLanguage.RU
            "ZH" -> LocalizationLanguage.ZH
            "JA" -> LocalizationLanguage.JA
            "KO" -> LocalizationLanguage.KO
            "AR" -> LocalizationLanguage.AR
            "HI" -> LocalizationLanguage.HI
            "BN" -> LocalizationLanguage.BN
            "PA" -> LocalizationLanguage.PA
            "UR" -> LocalizationLanguage.UR
            "ID" -> LocalizationLanguage.ID
            "MS" -> LocalizationLanguage.MS
            "SW" -> LocalizationLanguage.SW
            "TA" -> LocalizationLanguage.TA
            "TR" -> LocalizationLanguage.TR
            else -> null
        }
    }
    
    private fun mapLocalizationLanguageToString(language: LocalizationLanguage): String {
        return when (language) {
            LocalizationLanguage.EN -> "EN"
            LocalizationLanguage.ES -> "ES"
            LocalizationLanguage.FR -> "FR"
            LocalizationLanguage.DE -> "DE"
            LocalizationLanguage.IT -> "IT"
            LocalizationLanguage.PT -> "PT"
            LocalizationLanguage.RU -> "RU"
            LocalizationLanguage.ZH -> "ZH"
            LocalizationLanguage.JA -> "JA"
            LocalizationLanguage.KO -> "KO"
            LocalizationLanguage.AR -> "AR"
            LocalizationLanguage.HI -> "HI"
            LocalizationLanguage.BN -> "BN"
            LocalizationLanguage.PA -> "PA"
            LocalizationLanguage.UR -> "UR"
            LocalizationLanguage.ID -> "ID"
            LocalizationLanguage.MS -> "MS"
            LocalizationLanguage.SW -> "SW"
            LocalizationLanguage.TA -> "TA"
            LocalizationLanguage.TR -> "TR"
        }
    }
}

