package atmega.thinai

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Plain-text sharing from chat. One intent, so no plugin: the system
        // chooser does the rest and no permission is involved.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "in.atmega.thinai/share")
            .setMethodCallHandler { call, result ->
                if (call.method != "shareText") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                val text = call.argument<String>("text")
                if (text.isNullOrEmpty()) {
                    result.error("empty", "Nothing to share", null)
                    return@setMethodCallHandler
                }
                val send = Intent(Intent.ACTION_SEND).apply {
                    type = "text/plain"
                    putExtra(Intent.EXTRA_TEXT, text)
                    call.argument<String>("subject")?.let { putExtra(Intent.EXTRA_SUBJECT, it) }
                }
                startActivity(Intent.createChooser(send, null))
                result.success(null)
            }
    }
}
