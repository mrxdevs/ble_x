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
import java.io.ByteArrayOutputStream

class MediaListenerService : NotificationListenerService() {

    override fun onListenerConnected() {
        super.onListenerConnected()
        val manager = getSystemService(Context.MEDIA_SESSION_SERVICE) as MediaSessionManager
        val componentName = ComponentName(this, MediaListenerService::class.java)
        
        try {
            manager.addOnActiveSessionsChangedListener({ controllers ->
                processControllers(controllers)
            }, componentName)
            
            // Trigger immediately for existing sessions
            processControllers(manager.getActiveSessions(componentName))
        } catch (e: SecurityException) {
            // Permission not granted yet
        }
    }

    private fun processControllers(controllers: List<MediaController>?) {
        controllers?.forEach { controller ->
            controller.registerCallback(object : MediaController.Callback() {
                override fun onMetadataChanged(metadata: MediaMetadata?) {
                    metadata?.let {
                        val title = it.getString(MediaMetadata.METADATA_KEY_TITLE) ?: "Unknown"
                        val artist = it.getString(MediaMetadata.METADATA_KEY_ARTIST) ?: "Unknown"
                        val duration = it.getLong(MediaMetadata.METADATA_KEY_DURATION)
                        val bitmap = it.getBitmap(MediaMetadata.METADATA_KEY_ALBUM_ART)

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
                            } catch (e: Exception) {
                                e.printStackTrace()
                            }
                        }
                        sendBroadcast(intent)
                    }
                }

                override fun onPlaybackStateChanged(state: PlaybackState?) {
                    state?.let {
                        val isPlaying = it.state == PlaybackState.STATE_PLAYING
                        val intent = Intent("com.example.ble_x.MEDIA_INFO")
                        intent.putExtra("type", "state")
                        intent.putExtra("isPlaying", isPlaying)
                        intent.putExtra("position", it.position)
                        intent.putExtra("speed", it.playbackSpeed)
                        sendBroadcast(intent)
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