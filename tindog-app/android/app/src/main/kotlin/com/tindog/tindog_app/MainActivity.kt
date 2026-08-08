package com.tindog.tindog_app

import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(
                NotificationChannel(
                    "tindog_matches",
                    "Matches tinDog",
                    NotificationManager.IMPORTANCE_HIGH,
                ),
            )
            manager.createNotificationChannel(
                NotificationChannel(
                    "tindog_chat",
                    "Chats tinDog",
                    NotificationManager.IMPORTANCE_HIGH,
                ),
            )
        }
    }
}
