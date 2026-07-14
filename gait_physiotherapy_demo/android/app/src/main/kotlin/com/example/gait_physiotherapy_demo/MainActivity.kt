package com.example.gait_physiotherapy_demo

import android.os.Debug
import android.os.Process
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.RandomAccessFile

class MainActivity : FlutterActivity() {

    private val CHANNEL = "com.example.gait_physiotherapy_demo/system_stats"
    private val SLM_CHANNEL = "com.example.gait_physiotherapy_demo/slm_inference"

    companion object {
        init {
            System.loadLibrary("llama_jni")
        }
    }

    private external fun nativeLoadModel(modelPath: String): Boolean
    private external fun nativeGenerate(prompt: String): String
    private external fun nativeUnloadModel()

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getMemoryUsageMB" -> result.success(getMemoryUsageMB())
                    "getCpuUsagePercent" -> result.success(getCpuUsagePercent())
                    else -> result.notImplemented()
                }
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SLM_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "loadModel" -> {
                        val path = call.argument<String>("path")
                        if (path != null) {
                            Thread {
                                val success = nativeLoadModel(path)
                                runOnUiThread {
                                    if (success) {
                                        result.success(true)
                                    } else {
                                        result.error("LOAD_FAILED", "Failed to load model", null)
                                    }
                                }
                            }.start()
                        } else {
                            result.error("INVALID_ARGUMENT", "Path is null", null)
                        }
                    }
                    "generate" -> {
                        val prompt = call.argument<String>("prompt")
                        if (prompt != null) {
                            Thread {
                                val output = nativeGenerate(prompt)
                                runOnUiThread {
                                    result.success(output)
                                }
                            }.start()
                        } else {
                            result.error("INVALID_ARGUMENT", "Prompt is null", null)
                        }
                    }
                    "unloadModel" -> {
                        Thread {
                            nativeUnloadModel()
                            runOnUiThread {
                                result.success(true)
                            }
                        }.start()
                    }
                    "keepScreenOn" -> {
                        val keep = call.argument<Boolean>("keep") ?: false
                        runOnUiThread {
                            if (keep) {
                                window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
                            } else {
                                window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
                            }
                            result.success(true)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    /** Resident memory (PSS) used by this process, in MB. Approximate. */
    private fun getMemoryUsageMB(): Double {
        return try {
            val memInfo = Debug.MemoryInfo()
            Debug.getMemoryInfo(memInfo)
            memInfo.totalPss / 1024.0 // KB -> MB
        } catch (e: Exception) {
            0.0
        }
    }

    /**
     * Approximate CPU usage of this process, sampled over a short
     * window by diffing /proc/[pid]/stat and /proc/stat. Good enough
     * for relative comparisons across devices/models.
     */
    private fun getCpuUsagePercent(): Double {
        return try {
            val pid = Process.myPid()

            val procTime1 = readProcessCpuTime(pid)
            val totalTime1 = readTotalCpuTime()

            Thread.sleep(200)

            val procTime2 = readProcessCpuTime(pid)
            val totalTime2 = readTotalCpuTime()

            val procDelta = (procTime2 - procTime1).toDouble()
            val totalDelta = (totalTime2 - totalTime1).toDouble()

            if (totalDelta <= 0) return 0.0

            val cores = Runtime.getRuntime().availableProcessors()
            ((procDelta / totalDelta) * cores * 100.0).coerceIn(0.0, 100.0 * cores)
        } catch (e: Exception) {
            0.0
        }
    }

    private fun readProcessCpuTime(pid: Int): Long {
        val reader = RandomAccessFile("/proc/$pid/stat", "r")
        val line = reader.readLine()
        reader.close()
        // Fields after the closing ")" of the process name are space-separated.
        val afterName = line.substring(line.lastIndexOf(")") + 2).trim()
        val fields = afterName.split(" ")
        val utime = fields[11].toLong() // utime is field 14 overall (index 11 here)
        val stime = fields[12].toLong() // stime is field 15 overall (index 12 here)
        return utime + stime
    }

    private fun readTotalCpuTime(): Long {
        val reader = RandomAccessFile("/proc/stat", "r")
        val line = reader.readLine()
        reader.close()
        val tokens = line.split(" ").filter { it.isNotEmpty() && it != "cpu" }
        return tokens.sumOf { it.toLong() }
    }
}