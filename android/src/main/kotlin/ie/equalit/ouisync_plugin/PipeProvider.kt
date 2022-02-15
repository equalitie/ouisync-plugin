package ie.equalit.ouisync_plugin

import android.content.Context
import android.content.res.AssetFileDescriptor
import android.net.Uri
import android.os.Handler
import android.os.HandlerThread
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
import java.util.concurrent.Semaphore

class PipeProvider: AbstractFileProvider() {
    companion object {
        val CONTENT_URI: Uri = Uri.parse("content://ie.equalit.ouisync_plugin.pipe/")
        private const val CHUNK_SIZE = 64000
        private val TAG = PipeProvider::class.java.simpleName
    }


    private lateinit var workerThread: HandlerThread
    private lateinit var workerHandler: Handler

    override fun onCreate(): Boolean {
        workerThread = HandlerThread("${javaClass.simpleName} worker thread")
        workerThread.start()

        workerHandler = Handler(workerThread.getLooper())

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
            ProxyCallbacks(path, size),
            workerHandler
        )
    }

    @Throws(FileNotFoundException::class)
    private fun openPipe(path: String): ParcelFileDescriptor? {
        TODO("Not yet implemented")


        // var pipe: Array<ParcelFileDescriptor?>?

        // try {
        //     pipe = ParcelFileDescriptor.createPipe()
        // } catch (e: IOException) {
        //     Log.e(TAG, "Exception opening pipe", e)
        //     throw FileNotFoundException("Could not open pipe for: " + path)
        // }

        // // pipe_id is only for debugging
        // var pipe_id = kotlin.random.Random.nextInt(Int.MAX_VALUE);

        // PipeTransfer(
        //     pipe_id,
        //     context!!,
        //     path,
        //     ParcelFileDescriptor.AutoCloseOutputStream(pipe[1])
        // ).start()

        // return pipe[0]
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
        private val path: String,
        private val size: Long
    ) : android.os.ProxyFileDescriptorCallback() {
        private val semaphore = Semaphore(1)

        override fun onGetSize() = size

        override fun onRead(offset: Long, chunkSize: Int, outData: ByteArray): Int {
            semaphore.acquire(1)

            var outSize: Int = 0

            readChunkInUiThread(path, chunkSize, offset, object: MethodChannel.Result {
                override fun success(a: Any?) {
                    val chunk = a as ByteArray

                    outSize = chunk.size
                    chunk.copyInto(outData)
                    semaphore.release(1)
                }

                override fun error(errorCode: String?, errorMessage: String?, errorDetails: Any?) {
                    Log.e(TAG, "error reading file at $path - code: $errorCode, message: $errorMessage details: $errorDetails")
                    semaphore.release(1)
                }

                override fun notImplemented() {}
            })

            semaphore.acquire(1)
            semaphore.release(1)

            return outSize
        }

        override fun onRelease() {}
    }

    // internal class PipeTransfer(
    //     private val pipe_id: Int,
    //     private val context: Context,
    //     private val path: String,
    //     private var out: OutputStream
    // ) {
    //     fun start() {
    //         readChunk(0)
    //     }

    //     private fun readChunk(offset: Long) {
    //         readChunkInUiThread(path, PipeProvider.CHUNK_SIZE, offset, object : MethodChannel.Result {
    //             override fun success(a: Any?) {
    //                 val chunk = a as ByteArray

    //                 // We're currently not in our custom thread, and the
    //                 // writeChunk function is blocking, so we need to spawn a
    //                 // new thread so as to not block the whole app. This is a
    //                 // temporary quick fix and should be dealt with better.
    //                 Thread {
    //                     writeChunk(chunk, offset)
    //                 }.start()
    //             }

    //             override fun error(s0: String?, s1: String?, a: Any?) {
    //                 Log.e(TAG, "$pipe_id: error reading file (s0:$s0 s1:$s1 a:$a)")
    //                 out.close();
    //             }

    //             override fun notImplemented() {}
    //         })
    //     }

    //     private fun writeChunk(chunk: ByteArray, offset: Long) {
    //         if (chunk.isNotEmpty()) {
    //             Log.d(TAG, "$pipe_id: Chunk received. size: ${chunk.size} offset: $offset")

    //             try {
    //                 out.write(chunk, 0, chunk.size)
    //             } catch (e: IOException) {
    //                 Log.e(TAG, "$pipe_id: Exception writing to pipe", e)
    //                 // TODO: Not 100% sure about this one. Without it I saw
    //                 // messages about resources not being closed, but I haven't
    //                 // really seen any examples do such explicit closing.
    //                 out.close()
    //                 return;
    //             }

    //             readChunk(offset + chunk.size)
    //         }

    //         if (chunk.isEmpty()) {
    //             Log.d(TAG, "$pipe_id: Chunk empty, closing OutputStream")

    //             out.flush()
    //             out.close()
    //         }
    //     }
    // }
}

private fun readChunkInUiThread(path: String, chunkSize: Int, offset: Long, callbacks: MethodChannel.Result) {
    Handler(Looper.getMainLooper()).post {
        readChunk(path, chunkSize, offset, callbacks)
    }
}

private fun readChunk(path: String, chunkSize: Int, offset: Long, callbacks: MethodChannel.Result) {
    val arguments = hashMapOf<String, Any>("path"      to path,
                                           "chunkSize" to chunkSize,
                                           "offset"    to offset)

    OuisyncPlugin.channel.invokeMethod("readOuiSyncFile", arguments, callbacks)
}

