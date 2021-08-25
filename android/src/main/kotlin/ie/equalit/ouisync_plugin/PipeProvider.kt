package ie.equalit.ouisync_plugin

import android.content.Context
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.os.ParcelFileDescriptor
import android.util.Log
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.Result
import java.io.FileNotFoundException
import java.io.IOException
import java.io.InputStream
import java.io.OutputStream
import java.util.concurrent.Callable
import java.util.concurrent.FutureTask


class PipeProvider: AbstractFileProvider() {
    companion object {
        val CONTENT_URI: Uri = Uri.parse("content://ie.equalit.ouisync_plugin.pipe/")
        const val CHUNK_SIZE = 64000
    }

    override fun onCreate(): Boolean {
        return true
    }

    @Throws(FileNotFoundException::class)
    override fun openFile(uri: Uri, mode: String): ParcelFileDescriptor? {
        var pipe: Array<ParcelFileDescriptor?>?

        try {
            pipe = ParcelFileDescriptor.createPipe()
            val path = getPathFromUri(uri)
            
            TransferThread(
                    context!!,
                    path,
                    ParcelFileDescriptor.AutoCloseOutputStream(pipe[1])
            ).start()
        } catch (e: IOException) {
            Log.e(javaClass.simpleName, "Exception opening pipe", e)
            throw FileNotFoundException("Could not open pipe for: "
                    + uri.toString())
        }
        return pipe[0]
    }

    private fun getPathFromUri(uri: Uri): String {
        val segments = uri.pathSegments
        var index = 0;
        var path = ""

        for (segment in segments) {
            if (index > 0) {
                path += "/$segment"
            }
            index++
        }

        Log.d(javaClass.simpleName,
            "Path from Uri: $path")
        return path
    }

    internal class TransferThread(private val  context: Context, private var path: String, private var out: OutputStream) : Thread() {
        var pluginChunkListener: ((ByteArray)->Unit)? = null

        override fun run() {
            path.let { path ->
                var len = 0
                context.executeOnUIThreadSync(path, 0, ::getFileChunk)

                pluginChunkListener = { chunk ->
                    if (chunk.isNotEmpty()) {
                        len += chunk.size

                        Log.d("CHUNK RECEIVED", "Chunk size: ${chunk.size} || Offset: $len")

                        try {
                            out.write(chunk, 0, chunk.size)
                            context.executeOnUIThreadSync(path, len, ::getFileChunk)
                        } catch (e: IOException) {
                            Log.e(javaClass.simpleName,
                                    "Exception transferring file", e)
                        }
                    }

                    if (chunk.isEmpty()) {
                        Log.d("EOF", "Chunk empty, closing OutputStream")

                        out.flush()
                        out.close()
                    }
                }
            }
        }

        private fun getFileChunk(path: String, offset: Int) {
            val arguments = HashMap<String, Any>()
            arguments["path"] = path
            arguments["chunkSize"] = CHUNK_SIZE
            arguments["offset"] = offset

            OuisyncPlugin.channel.invokeMethod("readOuiSyncFile", arguments, object : MethodChannel.Result {
                override fun success(a: Any?) {
                    val chunk = a as ByteArray

                    Log.d("SUCCESS", "Chunk size: ${chunk.size}")
                    pluginChunkListener?.invoke(chunk)
                }

                override fun error(s0: String?, s1: String?, a: Any?) {
                    s0?.let {
                        Log.d("ERROR", "s0: $it")
                    }
                    s1?.let {
                        Log.d("ERROR", "s1: $it")
                    }
                    a?.let {
                        Log.d("ERROR", "a: $it")
                    }

                    throw Exception("readOuiSyncFile result error:\ns0: $s0\ns1: $s1\na: $a")
                }

                override fun notImplemented() {}
            })
        }
    }
}

fun Context.executeOnUIThreadSync(path: String, offset: Int, func: (String, Int) -> Unit) {
    if (Looper.myLooper() == Looper.getMainLooper()) {
        Log.d("EXECUTE_ON_UI", "On main loop")
        func.invoke(path, offset)
    } else {
        Handler(this.mainLooper).post {
            func.invoke(path, offset)
            Log.d("EXECUTE_ON_UI", "Posting to main loop")
        }
    }
}