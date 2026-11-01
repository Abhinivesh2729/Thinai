package atmega.thinai

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // The public tunnel runs the bundled cloudflared from here.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "thinai/native")
            .setMethodCallHandler { call, result ->
                if (call.method == "nativeLibraryDir") {
                    result.success(applicationInfo.nativeLibraryDir)
                } else {
                    result.notImplemented()
                }
            }
    }
}
