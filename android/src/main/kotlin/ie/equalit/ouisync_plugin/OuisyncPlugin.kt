package ie.equalit.ouisync_plugin

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.util.Log
import androidx.annotation.NonNull

import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.net.URLConnection

/** OuisyncPlugin */
class OuisyncPlugin: FlutterPlugin, MethodCallHandler, ActivityAware {
  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  var activity : Activity? = null
  private lateinit var context : Context

  companion object {
    lateinit var channel : MethodChannel
  }

  override fun onAttachedToActivity(@NonNull activityPluginBinding: ActivityPluginBinding) {
    print("onAttachedToActivity")
    activity = activityPluginBinding.activity
  }

  override fun onDetachedFromActivityForConfigChanges() {
    activity = null
  }

  override fun onReattachedToActivityForConfigChanges(@NonNull activityPluginBinding: ActivityPluginBinding) {
    activity = activityPluginBinding.activity
  }

  override fun onDetachedFromActivity() {
    activity = null
  }

  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "ouisync_plugin")
    channel.setMethodCallHandler(this)

    context = flutterPluginBinding.getApplicationContext()
  }

  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: MethodChannel.Result) {

    when (call.method) {
      "shareFile" -> {
        val arguments = call.arguments as HashMap<String, Any>
        startFileShareAction(arguments)
        result.success("Share file intent started")

      }
      "previewFile" -> {
        val arguments = call.arguments as HashMap<String, Any>
        startFilePreviewAction(arguments)
        result.success("View file intent started")
      }
      else -> {
        result.notImplemented()
      }
    }
  }

  private fun startFilePreviewAction(arguments: HashMap<String, Any>) {
    val path = arguments["path"]
    val size = arguments["size"]
    val useDefaultApp = arguments["useDefaultApp"]

    val uri = Uri.parse("${PipeProvider.CONTENT_URI}$size$path")

    Log.d(javaClass.simpleName, "Uri: ${uri.toString()}")

    val intent = getIntentForAction(uri, Intent.ACTION_VIEW)

    if (useDefaultApp != null) {
        // Note that not using Intent.createChooser let's the user choose a
        // default app and then use that the next time the same file type is
        // opened.
        activity?.startActivity(intent)
    } else {
        val title = "Preview file from OuiSync"
        activity?.startActivity(Intent.createChooser(intent, title))
    }
  }

  private fun startFileShareAction(arguments: HashMap<String, Any>) {
    val path = arguments["path"]
    val size = arguments["size"]
    val title = "Share file from OuiSync"

    val uri = Uri.parse("${PipeProvider.CONTENT_URI}$size$path")

    Log.d(javaClass.simpleName, "Uri: ${uri.toString()}")

    val intent = getIntentForAction(uri, Intent.ACTION_SEND)

    activity?.startActivity(Intent.createChooser(intent, title))
  }

  private fun getIntentForAction(
          intentData: Uri,
          intentAction: String
  ) = Intent().apply {
        data = intentData
        action = intentAction

        putExtra(Intent.EXTRA_STREAM, intentData)
        addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
      }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }
}
