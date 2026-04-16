package com.benjaminudoh10.balanced

import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugins.GeneratedPluginRegistrant

class MainActivity: FlutterFragmentActivity() {
    // We intentionally do not set FLAG_SECURE: that flag forces the task snapshot in Recents
    // to a blank/black surface. Privacy is handled in Flutter (overlay + lock). Without
    // FLAG_SECURE, the system can capture the real window (e.g. the branded privacy overlay).

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        GeneratedPluginRegistrant.registerWith(flutterEngine)
    }
}
