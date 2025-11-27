package com.example.ble_x

import io.flutter.embedding.android.FlutterActivity

import android.content.Context
import android.media.AudioManager
import android.os.Bundle
import android.view.KeyEvent

import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example.app/media_control"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
            
            when (call.method) {
                "playPause" -> {
                    // Simulate a headset hook press (toggles play/pause)
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
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun dispatchMediaKey(audioManager: AudioManager, keyCode: Int) {
        // We must send both ACTION_DOWN and ACTION_UP to register a full "press"
        val eventDown = KeyEvent(KeyEvent.ACTION_DOWN, keyCode)
        val eventUp = KeyEvent(KeyEvent.ACTION_UP, keyCode)
        
        audioManager.dispatchMediaKeyEvent(eventDown)
        audioManager.dispatchMediaKeyEvent(eventUp)
    }
}
