package com.mhmgad.awqat.android

import android.content.Context
import com.huawei.wearengine.HiWear
import com.huawei.wearengine.auth.AuthCallback
import com.huawei.wearengine.auth.Permission
import com.huawei.wearengine.device.Device
import com.huawei.wearengine.p2p.Message
import com.huawei.wearengine.p2p.Receiver
import com.huawei.wearengine.p2p.SendCallback
import java.nio.charset.StandardCharsets

class WearEngineSync(context: Context) {
    private val appContext = context.applicationContext
    private val p2p = HiWear.getP2pClient(appContext)
    private val devices = HiWear.getDeviceClient(appContext)
    private var watchReceiver: Receiver? = null

    init {
        p2p.setPeerPkgName(SyncConfig.WATCH_BUNDLE_NAME)
        p2p.setPeerFingerPrint(SyncConfig.WATCH_FINGERPRINT)
    }

    fun requestPermission(onDone: (Boolean) -> Unit) {
        HiWear.getAuthClient(appContext).requestPermission(object : AuthCallback {
            override fun onOk(permissions: Array<out Permission>?) {
                onDone(true)
            }

            override fun onCancel() {
                onDone(false)
            }
        }, Permission.DEVICE_MANAGER)
    }

    fun listenForWatch(onHello: () -> Unit) {
        val receiver = Receiver { message ->
            if (message == null || message.type != Message.MESSAGE_TYPE_DATA) {
                return@Receiver
            }
            val text = String(message.data, StandardCharsets.UTF_8)
            if (text.contains("hello")) {
                onHello()
            }
        }
        watchReceiver = receiver
        withConnectedDevice(
            onDevice = { device ->
                p2p.registerReceiver(device, receiver)
            },
            onError = { }
        )
    }

    fun sendTimes(json: String, onResult: (String) -> Unit) {
        withConnectedDevice(
            onDevice = { device -> pingThenSend(device, json, onResult) },
            onError = onResult
        )
    }

    private fun withConnectedDevice(onDevice: (Device) -> Unit, onError: (String) -> Unit) {
        devices.bondedDevices
            .addOnSuccessListener { list ->
                val device = list?.firstOrNull { it.isConnected }
                if (device == null) {
                    onError("No connected Huawei watch. Pair the FIT 3 in Huawei Health.")
                    return@addOnSuccessListener
                }
                onDevice(device)
            }
            .addOnFailureListener { error ->
                onError(wearEngineError(error))
            }
    }

    private fun pingThenSend(device: Device, json: String, onResult: (String) -> Unit) {
        p2p.ping(device) {
            val payload = Message.Builder()
                .setPayload(json.toByteArray(StandardCharsets.UTF_8))
                .build()
            p2p.send(device, payload, object : SendCallback {
                override fun onSendResult(resultCode: Int) {
                    onResult(
                        if (resultCode == 207) {
                            "Watch updated"
                        } else {
                            "Watch send failed ($resultCode). Open Awqat on the FIT 3 and retry."
                        }
                    )
                }

                override fun onSendProgress(progress: Long) = Unit
            }).addOnFailureListener { error ->
                onResult(wearEngineError(error))
            }
        }.addOnFailureListener { error ->
            onResult(wearEngineError(error))
        }
    }

    private fun wearEngineError(error: Exception): String {
        val detail = error.message ?: error.javaClass.simpleName
        return "Wear Engine unavailable ($detail). Install HMS Core + Huawei Health, enable the Wear Engine service in AppGallery Connect, and set the watch fingerprint in SyncConfig."
    }
}
