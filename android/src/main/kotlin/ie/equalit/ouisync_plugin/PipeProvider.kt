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

            TransferThread(
                    context!!,
                    "/${uri.lastPathSegment}",
                    ParcelFileDescriptor.AutoCloseOutputStream(pipe[1])
            ).start()
        } catch (e: IOException) {
            Log.e(javaClass.simpleName, "Exception opening pipe", e)
            throw FileNotFoundException("Could not open pipe for: "
                    + uri.toString())
        }
        return pipe[0]

    }

    internal class TransferThread(var context: Context, var path: String, var out: OutputStream) : Thread() {
        var pluginChunkListener: ((ByteArray)->Unit)? = null

        override fun run() {
            path.let { path ->
                var len = 0
                getFileChunk(context, path, 0)

                pluginChunkListener = { chunk ->
                    if (chunk.isNotEmpty()) {
                        len += chunk.size

                        Log.d("CHUNK RECEIVED", "Chunk size: ${chunk.size} || Offset: $len")

                        try {
                            out.write(chunk, 0, chunk.size)
                            getFileChunk(context, path, len)
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

        private fun getFileChunk(context: Context?, path: String, offset: Int) {
            val arguments = HashMap<String, Any>()
            arguments["path"] = path
            arguments["chunkSize"] = CHUNK_SIZE
            arguments["offset"] = offset

            val callable: Callable<Unit> = Callable {
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

            val task: FutureTask<Unit> = FutureTask(callable)
            context?.executeOnUIThreadSync(task)
        }
    }
}

fun Context.executeOnUIThreadSync(task: FutureTask<*>) {
    if (Looper.myLooper() == Looper.getMainLooper()) {
        task.run()
    } else {
        Handler(this.mainLooper).post {
            task.run()
        }
    }
}