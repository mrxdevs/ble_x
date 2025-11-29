package com.example.ble_x

import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.media.MediaMetadata
import android.media.session.MediaController
import android.media.session.MediaSessionManager
import android.media.session.PlaybackState
import android.service.notification.NotificationListenerService
import android.util.Log
import java.io.ByteArrayOutputStream

class MediaListenerService : NotificationListenerService() {
    private val TAG = "MediaListenerService"

    override fun onListenerConnected() {
        super.onListenerConnected()
        Log.d(TAG, "onListenerConnected: Service connected!")
        
        val manager = getSystemService(Context.MEDIA_SESSION_SERVICE) as MediaSessionManager
        val componentName = ComponentName(this, MediaListenerService::class.java)
        
        try {
            manager.addOnActiveSessionsChangedListener({ controllers ->
                Log.d(TAG, "Active sessions changed. Count: ${controllers?.size ?: 0}")
                processControllers(controllers)
            }, componentName)
            
            // Trigger immediately for existing sessions
            val sessions = manager.getActiveSessions(componentName)
            Log.d(TAG, "Initial active sessions: ${sessions?.size ?: 0}")
            processControllers(sessions)
        } catch (e: SecurityException) {
            Log.e(TAG, "SecurityException: Permission not granted yet", e)
        }
    }
    
    override fun onListenerDisconnected() {
        super.onListenerDisconnected()
        Log.d(TAG, "onListenerDisconnected: Service disconnected!")
    }

    private fun processControllers(controllers: List<MediaController>?) {
        Log.d(TAG, "processControllers: Processing ${controllers?.size ?: 0} controllers")
        
        controllers?.forEach { controller ->
            Log.d(TAG, "Registering callback for: ${controller.packageName}")
            
            controller.registerCallback(object : MediaController.Callback() {
                override fun onMetadataChanged(metadata: MediaMetadata?) {
                    Log.d(TAG, "onMetadataChanged called")
                    
                    metadata?.let {
                        val title = it.getString(MediaMetadata.METADATA_KEY_TITLE) ?: "Unknown"
                        val artist = it.getString(MediaMetadata.METADATA_KEY_ARTIST) ?: "Unknown"
                        val duration = it.getLong(MediaMetadata.METADATA_KEY_DURATION)
                        val bitmap = it.getBitmap(MediaMetadata.METADATA_KEY_ALBUM_ART)

                        Log.d(TAG, "Metadata - Title: $title, Artist: $artist, Duration: $duration")

                        val intent = Intent("com.example.ble_x.MEDIA_INFO")
                        intent.putExtra("type", "metadata")
                        intent.putExtra("title", title)
                        intent.putExtra("artist", artist)
                        intent.putExtra("duration", duration)

                        // Resize bitmap to prevent "TransactionTooLargeException"
                        if (bitmap != null) {
                            try {
                                val scaled = Bitmap.createScaledBitmap(bitmap, 150, 150, true)
                                intent.putExtra("artwork", bitmapToBytes(scaled))
                                Log.d(TAG, "Artwork added to broadcast")
                            } catch (e: Exception) {
                                Log.e(TAG, "Error processing artwork", e)
                            }
                        } else {
                            Log.d(TAG, "No artwork available")
                        }
                        
                        sendBroadcast(intent)
                        Log.d(TAG, "Metadata broadcast sent")
                    }
                }

                override fun onPlaybackStateChanged(state: PlaybackState?) {
                    Log.d(TAG, "onPlaybackStateChanged called")
                    
                    state?.let {
                        val isPlaying = it.state == PlaybackState.STATE_PLAYING
                        val position = it.position
                        val speed = it.playbackSpeed
                        
                        Log.d(TAG, "Playback state - Playing: $isPlaying, Position: $position, Speed: $speed")
                        
                        val intent = Intent("com.example.ble_x.MEDIA_INFO")
                        intent.putExtra("type", "state")
                        intent.putExtra("isPlaying", isPlaying)
                        intent.putExtra("position", position)
                        intent.putExtra("speed", speed)
                        
                        sendBroadcast(intent)
                        Log.d(TAG, "Playback state broadcast sent")
                    }
                }
            })
        }
    }

    private fun bitmapToBytes(bitmap: Bitmap): ByteArray {
        val stream = ByteArrayOutputStream()
        bitmap.compress(Bitmap.CompressFormat.PNG, 100, stream)
        return stream.toByteArray()
    }
}