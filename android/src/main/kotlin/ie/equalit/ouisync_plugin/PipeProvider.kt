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
        val TAG = javaClass.simpleName
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
        } catch (e: IOException) {
            Log.e(TAG, "Exception opening pipe", e)
            throw FileNotFoundException("Could not open pipe for: " + uri.toString())
        }

        // pipe_id is only for debugging
        var pipe_id = kotlin.random.Random.nextInt(Int.MAX_VALUE);

        Transfer(
            pipe_id,
            context!!,
            getPathFromUri(uri),
            ParcelFileDescriptor.AutoCloseOutputStream(pipe[1])
        ).start()

        return pipe[0]
    }

    private fun getPathFromUri(uri: Uri): String {
        val segments = uri.pathSegments
        var index = 0
        var path = ""

        for (segment in segments) {
            if (index > 0) {
                path += "/$segment"
            }
            index++
        }

        return path
    }

    internal class Transfer(
        private val pipe_id: Int,
        private val context: Context,
        private val path: String,
        private var out: OutputStream
    ) {
        fun start() {
            readChunkInUiThread(0)
        }

        private fun readChunk(offset: Int) {
            val arguments = HashMap<String, Any>()

            arguments["path"] = path
            arguments["chunkSize"] = CHUNK_SIZE
            arguments["offset"] = offset

            OuisyncPlugin.channel.invokeMethod("readOuiSyncFile", arguments, object : MethodChannel.Result {
                override fun success(a: Any?) {
                    val chunk = a as ByteArray

                    // We're currently not in our custom thread, and the
                    // writeChunk function is blocking, so we need to spawn a
                    // new thread so as to not block the whole app. This is a
                    // temporary quick fix and should be dealt with better.
                    Thread {
                        writeChunk(chunk, offset)
                    }.start()
                }

                override fun error(s0: String?, s1: String?, a: Any?) {
                    Log.e(TAG, "$pipe_id: error reading file (s0:$s0 s1:$s1 a:$a)")
                    out.close();
                }

                override fun notImplemented() {}
            })
        }

        private fun writeChunk(chunk: ByteArray, offset: Int) {
            if (chunk.isNotEmpty()) {
                Log.d(TAG, "$pipe_id: Chunk received. size: ${chunk.size} offset: $offset")

                try {
                    out.write(chunk, 0, chunk.size)
                } catch (e: IOException) {
                    Log.e(TAG, "$pipe_id: Exception writing to pipe", e)
                    // TODO: Not 100% sure about this one. Without it I saw
                    // messages about resources not being closed, but I haven't
                    // really seen any examples do such explicit closing.
                    out.close()
                    return;
                }

                readChunkInUiThread(offset + chunk.size)
            }

            if (chunk.isEmpty()) {
                Log.d(TAG, "$pipe_id: Chunk empty, closing OutputStream")

                out.flush()
                out.close()
            }
        }

        private fun readChunkInUiThread(offset: Int) {
            if (Looper.myLooper() == Looper.getMainLooper()) {
                readChunk(offset)
            } else {
                Handler(context.mainLooper).post {
                    readChunk(offset)
                }
            }
        }
    }
}
