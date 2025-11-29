package com.example.ble_x

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.media.AudioManager
import android.os.Build
import android.util.Log
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
    private val TAG = "MediaStreamHandler"
    private var eventSink: EventChannel.EventSink? = null
    
    private val receiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            Log.d(TAG, "Broadcast received!")
            
            val type = intent.getStringExtra("type")
            Log.d(TAG, "Received type: $type")
            
            val data = HashMap<String, Any?>()
            
            data["type"] = type
            if (type == "metadata") {
                val title = intent.getStringExtra("title")
                val artist = intent.getStringExtra("artist")
                val duration = intent.getLongExtra("duration", 0L)
                val artwork = intent.getByteArrayExtra("artwork")
                
                data["title"] = title
                data["artist"] = artist
                data["duration"] = duration
                data["artwork"] = artwork
                
                Log.d(TAG, "Metadata - Title: $title, Artist: $artist, Duration: $duration, Has artwork: ${artwork != null}")
            } else if (type == "state") {
                val isPlaying = intent.getBooleanExtra("isPlaying", false)
                val position = intent.getLongExtra("position", 0L)
                val speed = intent.getFloatExtra("speed", 1.0f)
                
                data["isPlaying"] = isPlaying
                data["position"] = position
                data["speed"] = speed
                
                Log.d(TAG, "State - Playing: $isPlaying, Position: $position, Speed: $speed")
            }
            
            eventSink?.success(data)
            Log.d(TAG, "Data sent to Flutter via eventSink")
        }
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        Log.d(TAG, "onListen: Setting up event channel stream")
        eventSink = events
        
        // Register receiver with appropriate flags for modern Android
        val filter = IntentFilter("com.example.ble_x.MEDIA_INFO")
        
        // Android 13+ (Tiramisu, API 33) requires explicit receiver export flags
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            context.registerReceiver(receiver, filter, Context.RECEIVER_NOT_EXPORTED)
            Log.d(TAG, "Receiver registered with RECEIVER_NOT_EXPORTED flag")
        } else {
            context.registerReceiver(receiver, filter)
            Log.d(TAG, "Receiver registered (legacy mode)")
        }
    }

    override fun onCancel(arguments: Any?) {
        Log.d(TAG, "onCancel: Cleaning up event channel stream")
        
        try {
            context.unregisterReceiver(receiver)
            Log.d(TAG, "Receiver unregistered successfully")
        } catch (e: Exception) {
            Log.e(TAG, "Error unregistering receiver", e)
        }
        eventSink = null
    }
}