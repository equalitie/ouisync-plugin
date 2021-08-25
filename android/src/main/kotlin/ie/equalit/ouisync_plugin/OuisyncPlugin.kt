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

    print("onAttachedToEngine")
    context = flutterPluginBinding.getApplicationContext()
  }

  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: MethodChannel.Result) {
    when (call.method) {
      "shareFile" -> {
        val arguments = call.arguments as HashMap<String, Any>
        val action = Intent.ACTION_SEND
        val title = "Share file from OuiSync"
        startFileAction(arguments, action, title)

        result.success("Share file intent started")

      }
      "previewFile" -> {
        val arguments = call.arguments as HashMap<String, Any>
        val action = Intent.ACTION_VIEW
        val title = "Preview file from OuiSync"
        startFileAction(arguments, action, title)

        result.success("View file intent started")
      }
      else -> {
        result.notImplemented()
      }
    }
  }

  private fun startFileAction(arguments: HashMap<String, Any>, intentAction: String, title: String) {
    val path = arguments["path"]
    val size = arguments["size"]
    
    val uri = Uri.parse("${PipeProvider.CONTENT_URI}$size$path")

    Log.d(javaClass.simpleName,
      "Uri: ${uri.toString()}")

    Log.d(javaClass.simpleName,
      "Uri segments: ${uri.pathSegments.toString()}")

    Log.d(javaClass.simpleName,
      "Guessed content type: ${URLConnection.guessContentTypeFromName(uri.toString())} (If null, */* is used)")

    val intent = getIntentForAction(uri, intentAction)
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
