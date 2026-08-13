package com.ghosten.api

import android.app.Service
import android.content.Intent
import android.os.Binder
import android.os.Environment
import android.os.IBinder
import java.io.File
import java.net.ServerSocket

/**
 * Source-built adapter for the precompiled upstream API runtime.
 *
 * The native runtime identifies the official API contract with the public
 * SHA-256 digest of the upstream release certificate. Keeping that identity
 * stable lets Enhanced use its own package name and signing key without
 * changing the native database and network protocol.
 */
class ApiService : Service() {
    private var apiThread: ProxyThread? = null
    private val binder = LocalBinder()
    private var loaded = false

    private external fun apiStart(
        apiIdentity: String,
        port: Int,
        appDir: String,
        downloadPath: String,
        cachePath: String,
    )

    private external fun apiStop()

    private external fun apiInitialized(): Int

    private external fun call(method: String, data: ByteArray, params: ByteArray): ByteArray

    private external fun callWithCallback(
        method: String,
        data: ByteArray,
        params: ByteArray,
        callback: ApiMethodHandler,
    ): ByteArray

    val databasePath: File
        get() = applicationContext.getDatabasePath(DB_NAME)

    override fun onCreate() {
        try {
            System.loadLibrary(LIB_NAME)
        } catch (_: UnsatisfiedLinkError) {
            return
        } catch (_: Exception) {
            return
        }

        databasePath.parentFile?.mkdirs()
        loaded = true
        apiThread = ProxyThread().also(Thread::start)
        super.onCreate()
    }

    override fun onDestroy() {
        super.onDestroy()
        apiThread?.cancel()
    }

    override fun onBind(intent: Intent): IBinder = binder

    fun apiInitializedPort(): Int? = apiInitialized().takeIf { it != 0 }

    fun apiCall(method: String, data: ByteArray, params: ByteArray): ByteArray {
        return ApiData(call(method, data, params)).value()
    }

    fun apiCallWithCallback(
        method: String,
        data: ByteArray,
        params: ByteArray,
        callback: ApiMethodHandler,
    ): ByteArray {
        return ApiData(callWithCallback(method, data, params, callback)).value()
    }

    inner class LocalBinder : Binder() {
        fun getService(): ApiService? = this@ApiService.takeIf { loaded }
    }

    private inner class ProxyThread : Thread() {
        override fun run() {
            val cacheFolder = Environment.getExternalStoragePublicDirectory(
                "${Environment.DIRECTORY_DOWNLOADS}/$APP_NAME",
            )
            if (!cacheFolder.exists()) cacheFolder.mkdir()

            val port = ServerSocket(0).use { it.localPort }
            apiStart(
                UPSTREAM_API_IDENTITY,
                port,
                requireNotNull(databasePath.parent),
                Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_MOVIES).path,
                cacheFolder.path,
            )
        }

        fun cancel() = apiStop()
    }

    private class ApiData(data: ByteArray) {
        private val code = parseU8(data[0]) shl 8 or parseU8(data[1])
        private val payload = data.copyOfRange(2, data.size)

        fun value(): ByteArray {
            if (code / 10000 == 2) return payload
            throw ApiException(code, payload.toString(Charsets.UTF_8))
        }

        private companion object {
            fun parseU8(value: Byte): Int = if (value < 0) value + 256 else value.toInt()
        }
    }

    companion object {
        const val DB_NAME = "data"
        const val APP_NAME = "Ghosten Player"
        const val LIB_NAME = "api"

        // Base64(SHA-256(upstream v2.4.6 release certificate)).
        private const val UPSTREAM_API_IDENTITY = "k2s9fV7sfUY0VKJA8YyQkc2WsMPjcTTvfmGU6F4jOGw="
    }
}

class ApiException(val code: Int, message: String?) : Exception(message)

interface ApiMethodHandler {
    fun onApiMethodUpdate(data: ByteArray)
}
