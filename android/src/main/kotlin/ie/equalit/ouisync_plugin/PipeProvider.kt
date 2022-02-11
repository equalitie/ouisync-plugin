package ie.equalit.ouisync_plugin

import android.content.Context
import android.content.res.AssetFileDescriptor
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.os.ParcelFileDescriptor
import android.os.storage.StorageManager;
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

    // TODO: Handle `mode`
    @Throws(FileNotFoundException::class)
    override fun openFile(uri: Uri, mode: String): ParcelFileDescriptor? {
        val path = getPathFromUri(uri);

        if (android.os.Build.VERSION.SDK_INT >= 26) {
            var size = super.getDataLength(uri);

            if (size == AssetFileDescriptor.UNKNOWN_LENGTH) {
                Log.d(TAG, "Using pipe because size is unknown");
                return openPipe(path);
            }

            Log.d(TAG, "Using proxy file");
            return openProxyFile(path, size);
        } else {
            Log.d(TAG, "Using pipe because SDK_INT < 26");
            return openPipe(path);
        }
    }

    @Throws(FileNotFoundException::class)
    private fun openProxyFile(path: String, size: Long): ParcelFileDescriptor? {
        var storage = context!!.getSystemService(Context.STORAGE_SERVICE) as StorageManager;

        // https://developer.android.google.cn/reference/android/os/storage/StorageManager
        return storage.openProxyFileDescriptor(
            ParcelFileDescriptor.MODE_READ_ONLY,
            ProxyCallbacks(context!!, path, size),
            Handler(context!!.mainLooper)
        )
    }

    @Throws(FileNotFoundException::class)
    private fun openPipe(path: String): ParcelFileDescriptor? {
        var pipe: Array<ParcelFileDescriptor?>?

        try {
            pipe = ParcelFileDescriptor.createPipe()
        } catch (e: IOException) {
            Log.e(TAG, "Exception opening pipe", e)
            throw FileNotFoundException("Could not open pipe for: " + path)
        }

        // pipe_id is only for debugging
        var pipe_id = kotlin.random.Random.nextInt(Int.MAX_VALUE);

        PipeTransfer(
            pipe_id,
            context!!,
            path,
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

    internal class ProxyCallbacks(
        private val context: Context,
        private val path: String,
        private val size: Long
    ) : android.os.ProxyFileDescriptorCallback() {
        override fun onGetSize() = size

        override fun onRead(offset: Long, size: Int, ret_data: ByteArray): Int {
            val semaphore = java.util.concurrent.Semaphore(1)
            semaphore.acquire(1)

            var ret_size: Int = 0

            // TODO: The handler here is never executed. I'm guessing it's because this
            // onRead function is executed from inside the UiThread and because we also
            // need to use the UiThread, we get a deadlock.
            context.readChunkInUiThread(path, size, offset, object: MethodChannel.Result {
                override fun success(a: Any?) {
                    val chunk = a as ByteArray
                    ret_size = size;
                    System.arraycopy(chunk, 0, ret_data, 0, size);
                    semaphore.release(1);
                }

                override fun error(s0: String?, s1: String?, a: Any?) {
                    Log.e(TAG, "error reading file (s0:$s0 s1:$s1 a:$a)")
                    semaphore.release(1);
                }

                override fun notImplemented() {}
            })

            Log.d(TAG, "Blocking on semaphore");
            semaphore.acquire(1);
            Log.d(TAG, "Semaphore released");

            return ret_size
        }

        override fun onRelease() {}
    }

    internal class PipeTransfer(
        private val pipe_id: Int,
        private val context: Context,
        private val path: String,
        private var out: OutputStream
    ) {
        fun start() {
            readChunk(0)
        }

        private fun readChunk(offset: Long) {
            context.readChunkInUiThread(path, PipeProvider.CHUNK_SIZE, offset, object : MethodChannel.Result {
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

        private fun writeChunk(chunk: ByteArray, offset: Long) {
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

                readChunk(offset + chunk.size)
            }

            if (chunk.isEmpty()) {
                Log.d(TAG, "$pipe_id: Chunk empty, closing OutputStream")

                out.flush()
                out.close()
            }
        }
    }
}

private fun Context.readChunkInUiThread(path: String, size: Int, offset: Long, callbacks: MethodChannel.Result) {
    var func = {
        val arguments = HashMap<String, Any>()

        arguments["path"] = path
        arguments["chunkSize"] = size
        arguments["offset"] = offset

        OuisyncPlugin.channel.invokeMethod("readOuiSyncFile", arguments, callbacks)
    }

    if (Looper.myLooper() == Looper.getMainLooper()) {
        func.invoke()
    } else {
        Handler(this.mainLooper).post {
            func.invoke()
        }
    }
}
