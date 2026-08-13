package app.questband.nfcpunktearmband

import android.content.Intent
import android.nfc.NfcAdapter
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "app.questband/nfc"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "nfcStatus" -> {
                        val adapter = NfcAdapter.getDefaultAdapter(this)
                        result.success(
                            when {
                                adapter == null -> "unavailable"
                                adapter.isEnabled -> "enabled"
                                else -> "disabled"
                            }
                        )
                    }
                    "openNfcSettings" -> {
                        startActivity(
                            Intent(Settings.ACTION_NFC_SETTINGS)
                                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        )
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
