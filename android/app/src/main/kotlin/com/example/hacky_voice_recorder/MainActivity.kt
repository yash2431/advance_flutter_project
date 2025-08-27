//package com.example.hacky_voice_recorder
//
//import io.flutter.embedding.android.FlutterActivity
//
//class MainActivity : FlutterActivity()

//package com.example.hacky_voice_recorder // Make sure this package name matches your project
//
//import android.content.Context
//import io.flutter.embedding.android.FlutterActivity
//import io.flutter.embedding.engine.FlutterEngine
//import com.ryanheise.audioservice.AudioServicePlugin // Import AudioServicePlugin
//
//class MainActivity: FlutterActivity() {
//    // Override this method to provide the FlutterEngine to audio_service
//    override fun provideFlutterEngine(context: Context): FlutterEngine {
//        return AudioServicePlugin.getFlutterEngine(context)
//    }
//}

package com.example.hacky_voice_recorder
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import com.ryanheise.audioservice.AudioServicePlugin

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.hacky_voice_recorder/notification"

    override fun provideFlutterEngine(context: Context): FlutterEngine {
        return AudioServicePlugin.getFlutterEngine(context)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "createNotificationChannel") {
                val id = call.argument<String>("id")
                val name = call.argument<String>("name")
                val description = call.argument<String>("description")
                val importance = call.argument<Int>("importance") ?: 3

                createNotificationChannel(id, name, description, importance)
                result.success(null)
            } else {
                result.notImplemented()
            }
        }
    }

    private fun createNotificationChannel(id: String?, name: String?, description: String?, importance: Int) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(id, name, importance).apply {
                this.description = description
            }
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
            android.util.Log.d("MainActivity", "Notification channel created: $id")
        }
    }
}