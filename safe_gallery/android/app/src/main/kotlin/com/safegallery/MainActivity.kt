package com.safegallery

import android.app.Activity
import android.app.KeyguardManager
import android.app.admin.DevicePolicyManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Build
import android.view.View
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.safegallery/lock"
    private lateinit var devicePolicyManager: DevicePolicyManager
    private lateinit var componentName: ComponentName

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        devicePolicyManager = getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager
        componentName = ComponentName(this, DeviceAdminReceiver::class.java)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "enterPresentationMode" -> {
                    enterPresentationMode()
                    result.success(null)
                }
                "exitPresentationMode" -> {
                    exitPresentationMode()
                    result.success(null)
                }
                "lockDevice" -> {
                    val locked = lockDevice()
                    result.success(locked)
                }
                "isDeviceAdminEnabled" -> {
                    val isEnabled = devicePolicyManager.isAdminActive(componentName)
                    result.success(isEnabled)
                }
                "requestDeviceAdmin" -> {
                    requestDeviceAdmin()
                    result.success(null)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun enterPresentationMode() {
        activity?.runOnUiThread {
            // Enable immersive mode
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                window.setDecorFitsSystemWindows(false)
                window.insetsController?.let { controller ->
                    controller.hide(android.view.WindowInsets.Type.statusBars() or android.view.WindowInsets.Type.navigationBars())
                    controller.systemBarsBehavior = android.view.WindowInsetsController.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE
                }
            } else {
                @Suppress("DEPRECATION")
                window.decorView.systemUiVisibility = (
                    View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY
                    or View.SYSTEM_UI_FLAG_LAYOUT_STABLE
                    or View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
                    or View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN
                    or View.SYSTEM_UI_FLAG_HIDE_NAVIGATION
                    or View.SYSTEM_UI_FLAG_FULLSCREEN
                )
            }

            // Keep screen on during presentation
            window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        }
    }

    private fun exitPresentationMode() {
        activity?.runOnUiThread {
            // Exit immersive mode
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                window.setDecorFitsSystemWindows(true)
                window.insetsController?.show(android.view.WindowInsets.Type.statusBars() or android.view.WindowInsets.Type.navigationBars())
            } else {
                @Suppress("DEPRECATION")
                window.decorView.systemUiVisibility = View.SYSTEM_UI_FLAG_VISIBLE
            }

            // Allow screen to turn off
            window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        }
    }

    private fun lockDevice(): Boolean {
        return if (devicePolicyManager.isAdminActive(componentName)) {
            devicePolicyManager.lockNow()
            true
        } else {
            // Fallback: Try to lock using KeyguardManager (works on some devices)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
                val keyguardManager = getSystemService(Context.KEYGUARD_SERVICE) as KeyguardManager
                keyguardManager.requestDismissKeyguard(this, null)
            }
            false
        }
    }

    private fun requestDeviceAdmin() {
        val intent = Intent(DevicePolicyManager.ACTION_ADD_DEVICE_ADMIN)
        intent.putExtra(DevicePolicyManager.EXTRA_DEVICE_ADMIN, componentName)
        intent.putExtra(
            DevicePolicyManager.EXTRA_ADD_EXPLANATION,
            "Safe Gallery needs device admin permission to lock your device when exiting presentation mode."
        )
        startActivityForResult(intent, 1)
    }

    override fun onPause() {
        super.onPause()
        // Lock device when app goes to background during presentation mode
        // This is handled by Flutter's lifecycle observer
    }
}
