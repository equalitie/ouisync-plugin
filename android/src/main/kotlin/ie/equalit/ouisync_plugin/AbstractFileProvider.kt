package ie.equalit.ouisync_plugin

import android.content.ContentProvider
import android.content.ContentValues
import android.content.res.AssetFileDescriptor
import android.database.Cursor
import android.database.MatrixCursor
import android.net.Uri
import android.provider.OpenableColumns
import java.io.File
import java.io.FileOutputStream
import java.io.IOException
import java.io.InputStream
import java.net.URLConnection

abstract class AbstractFileProvider: ContentProvider() {
    companion object {
        private val OPENABLE_PROJECTION = arrayOf(
                OpenableColumns.DISPLAY_NAME, OpenableColumns.SIZE)
    }

    override fun query(
            uri: Uri,
            projection: Array<out String>?,
            selection: String?,
            selectionArgs: Array<out String>?,
            sortOrder: String?
    ): Cursor? {
        var projection = projection
        if (projection == null) {
            projection = OPENABLE_PROJECTION
        }
        val cursor = MatrixCursor(projection, 1)
        val b = cursor.newRow()
        for (col in projection!!) {
            when {
                OpenableColumns.DISPLAY_NAME == col -> {
                    b.add(getFileName(uri))
                }
                OpenableColumns.SIZE == col -> {
                    b.add(getDataLength(uri))
                }
                else -> { // unknown, so just add null
                    b.add(null)
                }
            }
        }

        return cursor
    }

    override fun getType(uri: Uri): String? {
        return URLConnection.guessContentTypeFromName(uri.toString())
    }

    protected open fun getFileName(uri: Uri): String? {
        return uri.lastPathSegment
    }

    protected open fun getDataLength(uri: Uri?): Long {
        return AssetFileDescriptor.UNKNOWN_LENGTH
    }

    @Throws(IOException::class)
    open fun copy(`in`: InputStream, dst: File?) {
        val out = FileOutputStream(dst)
        val buf = ByteArray(1024)
        var len: Int
        while (`in`.read(buf).also { len = it } >= 0) {
            out.write(buf, 0, len)
        }
        `in`.close()
        out.close()
    }


    override fun insert(uri: Uri, values: ContentValues?): Uri? {
        TODO("Not yet implemented")
    }

    override fun delete(uri: Uri, selection: String?, selectionArgs: Array<out String>?): Int {
        TODO("Not yet implemented")
    }

    override fun update(uri: Uri, values: ContentValues?, selection: String?, selectionArgs: Array<out String>?): Int {
        TODO("Not yet implemented")
    }
}