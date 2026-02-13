package com.parthi.play

import android.content.Context
import android.content.pm.ActivityInfo
import android.media.AudioManager
import android.provider.Settings
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val SYSTEM_CHANNEL = "next_player/system_controls"
    private val CASTING_CHANNEL = "next_player/casting"
    private val ORIENTATION_CHANNEL = "parthi_play/orientation"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            ORIENTATION_CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "setSensorLandscape" -> {
                    requestedOrientation =
                        ActivityInfo.SCREEN_ORIENTATION_SENSOR_LANDSCAPE
                    result.success(true)
                }
                "setSensorPortrait" -> {
                    requestedOrientation =
                        ActivityInfo.SCREEN_ORIENTATION_SENSOR_PORTRAIT
                    result.success(true)
                }
                "setSensorAuto" -> {
                    requestedOrientation = ActivityInfo.SCREEN_ORIENTATION_SENSOR
                    result.success(true)
                }
                "setFullSensor" -> {
                    requestedOrientation =
                        ActivityInfo.SCREEN_ORIENTATION_FULL_SENSOR
                    result.success(true)
                }
                "clear" -> {
                    requestedOrientation =
                        ActivityInfo.SCREEN_ORIENTATION_UNSPECIFIED
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }

        // System Controls Channel
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            SYSTEM_CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "getBrightness" -> result.success(getBrightness())
                "setBrightness" -> {
                    val brightness = call.argument<Double>("brightness")
                    if (brightness != null) {
                        setBrightness(brightness.toFloat())
                        result.success(true)
                    } else {
                        result.error("INVALID_ARGUMENT", "Brightness is null", null)
                    }
                }
                "getVolume" -> result.success(getVolume())
                "setVolume" -> {
                    val volume = call.argument<Double>("volume")
                    if (volume != null) {
                        setVolume(volume.toFloat())
                        result.success(true)
                    } else {
                        result.error("INVALID_ARGUMENT", "Volume is null", null)
                    }
                }
                "isSupported" -> result.success(true)
                else -> result.notImplemented()
            }
        }

        // Casting Channel (Mock implementation for now)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CASTING_CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "initialize" -> result.success(true)
                "isSupported" -> result.success(true)
                "scanForDevices" -> {
                    val mockDevices = listOf(
                        mapOf(
                            "id" to "mock_tv_1",
                            "name" to "Living Room TV",
                            "type" to "Chromecast",
                            "host" to "192.168.1.100",
                            "port" to 8008,
                            "isConnected" to false
                        ),
                        mapOf(
                            "id" to "mock_tv_2",
                            "name" to "Bedroom TV",
                            "type" to "DLNA",
                            "host" to "192.168.1.101",
                            "port" to 1400,
                            "isConnected" to false
                        )
                    )
                    result.success(mockDevices)
                }
                "connectToDevice" -> result.success(true)
                "disconnectFromDevice" -> result.success(true)
                "loadMedia" -> result.success(true)
                "play" -> result.success(true)
                "pause" -> result.success(true)
                "stop" -> result.success(true)
                "seek" -> result.success(true)
                "setVolume" -> result.success(true)
                "setMuted" -> result.success(true)
                "getSessionStatus" -> result.success(null)
                "isDeviceConnected" -> result.success(false)
                else -> result.notImplemented()
            }
        }
    }

    private fun getBrightness(): Float {
        return try {
            val layoutParams = window.attributes
            if (layoutParams.screenBrightness < 0) {
                Settings.System.getInt(
                    contentResolver,
                    Settings.System.SCREEN_BRIGHTNESS
                ).toFloat() / 255f
            } else {
                layoutParams.screenBrightness
            }
        } catch (e: Exception) {
            0.5f
        }
    }

    private fun setBrightness(brightness: Float) {
        runOnUiThread {
            val layoutParams = window.attributes
            layoutParams.screenBrightness = brightness
            window.attributes = layoutParams
        }
    }

    private fun getVolume(): Float {
        val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
        val currentVolume = audioManager.getStreamVolume(AudioManager.STREAM_MUSIC)
        val maxVolume = audioManager.getStreamMaxVolume(AudioManager.STREAM_MUSIC)
        return currentVolume.toFloat() / maxVolume.toFloat()
    }

    private fun setVolume(volume: Float) {
        val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
        val maxVolume = audioManager.getStreamMaxVolume(AudioManager.STREAM_MUSIC)
        val targetVolume = (volume * maxVolume).toInt()
        audioManager.setStreamVolume(AudioManager.STREAM_MUSIC, targetVolume, 0)
    }
}
