package com.tindog.tindog_app

import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.tindog.tindog_app/app",
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "moveToBackground" -> {
                    // Como una app normal: va a segundo plano sin matar el Activity,
                    // así al volver el "atrás" sigue pidiendo confirmación.
                    moveTaskToBack(true)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

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
