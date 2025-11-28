package com.example.ble_x

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.media.AudioManager
import android.os.Build
import android.view.KeyEvent
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CONTROL_CHANNEL = "com.example.app/media_control"
    private val STREAM_CHANNEL = "com.example.app/media_stream"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // 1. Method Channel (Controls)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CONTROL_CHANNEL).setMethodCallHandler { call, result ->
            val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
            when (call.method) {
                "playPause" -> {
                    dispatchMediaKey(audioManager, KeyEvent.KEYCODE_MEDIA_PLAY_PAUSE)
                    result.success(null)
                }
                "next" -> {
                    dispatchMediaKey(audioManager, KeyEvent.KEYCODE_MEDIA_NEXT)
                    result.success(null)
                }
                "previous" -> {
                    dispatchMediaKey(audioManager, KeyEvent.KEYCODE_MEDIA_PREVIOUS)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }

        // 2. Event Channel (Listening to Data)
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, STREAM_CHANNEL)
            .setStreamHandler(MediaStreamHandler(this))
    }

    private fun dispatchMediaKey(audioManager: AudioManager, keyCode: Int) {
        audioManager.dispatchMediaKeyEvent(KeyEvent(KeyEvent.ACTION_DOWN, keyCode))
        audioManager.dispatchMediaKeyEvent(KeyEvent(KeyEvent.ACTION_UP, keyCode))
    }
}

class MediaStreamHandler(private val context: Context) : EventChannel.StreamHandler {
    private var eventSink: EventChannel.EventSink? = null
    
    private val receiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            val type = intent.getStringExtra("type")
            val data = HashMap<String, Any?>()
            
            data["type"] = type
            if (type == "metadata") {
                data["title"] = intent.getStringExtra("title")
                data["artist"] = intent.getStringExtra("artist")
                data["duration"] = intent.getLongExtra("duration", 0L)
                data["artwork"] = intent.getByteArrayExtra("artwork")
            } else if (type == "state") {
                data["isPlaying"] = intent.getBooleanExtra("isPlaying", false)
                data["position"] = intent.getLongExtra("position", 0L)
                data["speed"] = intent.getFloatExtra("speed", 1.0f)
            }
            eventSink?.success(data)
        }
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
        // Register receiver with appropriate flags for modern Android
        val filter = IntentFilter("com.example.ble_x.MEDIA_INFO")
        
        // Android 13+ (Tiramisu, API 33) requires explicit receiver export flags
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            context.registerReceiver(receiver, filter, Context.RECEIVER_NOT_EXPORTED)
        } else {
            context.registerReceiver(receiver, filter)
        }
    }

    override fun onCancel(arguments: Any?) {
        try {
            context.unregisterReceiver(receiver)
        } catch (e: Exception) {
            // Receiver might not be registered
        }
        eventSink = null
    }
}