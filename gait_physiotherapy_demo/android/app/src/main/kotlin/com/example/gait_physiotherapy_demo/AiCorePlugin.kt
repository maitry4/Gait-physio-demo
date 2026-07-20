package com.example.gait_physiotherapy_demo

import android.content.Context
import android.os.Build
import com.google.mlkit.genai.common.FeatureStatus
import com.google.mlkit.genai.prompt.Generation
import com.google.mlkit.genai.prompt.TextPart
import com.google.mlkit.genai.prompt.generateContentRequest
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

class AiCorePlugin : FlutterPlugin, MethodChannel.MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var context: Context
    private val scope = CoroutineScope(Dispatchers.Main)

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        context = flutterPluginBinding.applicationContext
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "com.example.gait_physiotherapy_demo/gemini_nano")
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "checkAvailability" -> {
                scope.launch {
                    try {
                        val availability = checkAvailabilityInternal()
                        result.success(availability)
                    } catch (e: Exception) {
                        result.error("AVAILABILITY_ERROR", e.localizedMessage, null)
                    }
                }
            }
            "generate" -> {
                val prompt = call.argument<String>("prompt")
                if (prompt == null) {
                    result.error("INVALID_ARGUMENT", "Prompt is null", null)
                    return
                }
                scope.launch {
                    try {
                        val output = generateInternal(prompt)
                        result.success(output)
                    } catch (e: Exception) {
                        result.error("GENERATION_ERROR", e.localizedMessage, null)
                    }
                }
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    private fun getStatusString(status: Int): String {
        return when (status) {
            FeatureStatus.AVAILABLE -> "AVAILABLE"
            FeatureStatus.DOWNLOADABLE -> "DOWNLOADABLE"
            FeatureStatus.DOWNLOADING -> "DOWNLOADING"
            FeatureStatus.UNAVAILABLE -> "UNAVAILABLE"
            else -> "UNKNOWN"
        }
    }

    private suspend fun checkAvailabilityInternal(): Map<String, Any?> = withContext(Dispatchers.IO) {
        val result = mutableMapOf<String, Any?>()
        
        // 1. Device Info
        result["deviceModel"] = Build.MODEL
        result["androidVersion"] = Build.VERSION.RELEASE

        try {
            // Check if ML Kit GenAI Client is accessible
            val generativeModel = Generation.getClient()
            val status = generativeModel.checkStatus()
            
            result["aiCoreInstalled"] = true
            result["geminiNanoAvailable"] = (status == FeatureStatus.AVAILABLE)
            result["status"] = getStatusString(status)
            result["modelName"] = "Gemini Nano"
            result["modelVersion"] = "gemini-nano-aicore"
            result["apiVersion"] = "ML Kit GenAI Prompt v1"
        } catch (e: Exception) {
            result["aiCoreInstalled"] = false
            result["geminiNanoAvailable"] = false
            result["status"] = "UNAVAILABLE"
            result["modelName"] = "Gemini Nano"
            result["modelVersion"] = null
            result["apiVersion"] = null
            result["error"] = e.localizedMessage
        }

        result
    }

    private suspend fun generateInternal(prompt: String): String = withContext(Dispatchers.IO) {
        val generativeModel = Generation.getClient()
        val status = generativeModel.checkStatus()

        if (status != FeatureStatus.AVAILABLE) {
            throw Exception("Gemini Nano is not available on this device. Status: ${getStatusString(status)}. Please ensure your device supports AI Core (e.g., Pixel 8+, Galaxy S24+) and the model has finished downloading in system settings.")
        }

        val request = generateContentRequest(TextPart(prompt)) {
            temperature = 0.3f
            maxOutputTokens = 500
        }

        val response = generativeModel.generateContent(request)
        val textResult = response.candidates.firstOrNull()?.text
        textResult ?: throw Exception("Received empty response from Gemini Nano")
    }
}
