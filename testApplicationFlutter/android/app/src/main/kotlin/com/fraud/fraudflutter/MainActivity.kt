package com.fraud.fraudflutter

import android.content.res.ColorStateList
import android.graphics.Color
import android.graphics.drawable.GradientDrawable
import android.os.Build
import android.view.Gravity
import android.view.View
import android.view.ViewGroup
import android.view.WindowInsets
import android.widget.FrameLayout
import android.widget.ImageButton
import android.widget.ImageView
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Hosts the app, and owns the end-call button drawn over the Udentify call screen.
 *
 * The SDKs have no end-call button, only methods to end a call, and a Dart widget cannot draw over the
 * native call screen, so the app adds its own native button and drives it from Dart through the
 * `fraud_test/call_overlay` channel (`show`, `hide`; the tap comes back as `onPressed`).
 *
 * The button is a child of the window's decor view, not of the content view the call fragment is added to.
 * Siblings are drawn by elevation, and the SDK's call layout sets its own (100dp on its root), so a sibling
 * inside the content view would have to guess a bigger number. A child of the decor view is compared with the
 * whole content subtree as one, so nothing inside the call screen can draw over it. It takes its margins from
 * the window's system bar and cut-out insets, so it clears the status bar whether or not the window is
 * edge-to-edge.
 */
class MainActivity : FlutterFragmentActivity() {

    private var channel: MethodChannel? = null
    private var endCallButton: ImageButton? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "fraud_test/call_overlay")
        methodChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "show" -> { showEndCallButton(); result.success(null) }
                "hide" -> { hideEndCallButton(); result.success(null) }
                else -> result.notImplemented()
            }
        }
        channel = methodChannel
    }

    override fun onDestroy() {
        hideEndCallButton()
        super.onDestroy()
    }

    private fun showEndCallButton() {
        if (endCallButton != null) return
        val decor = window.decorView as? ViewGroup ?: return
        val density = resources.displayMetrics.density
        val size = (SIZE_DP * density).toInt()
        val margin = (MARGIN_DP * density).toInt()

        val button = ImageButton(this).apply {
            setImageResource(R.drawable.ic_end_call)
            imageTintList = ColorStateList.valueOf(Color.WHITE)
            scaleType = ImageView.ScaleType.FIT_CENTER
            val padding = size / 4 // the glyph is half the button, like the SDK's own controls
            setPadding(padding, padding, padding, padding)
            background = GradientDrawable().apply {
                shape = GradientDrawable.OVAL
                setColor(Color.parseColor("#CC0000"))
            }
            contentDescription = "End call"
            elevation = ELEVATION_DP * density
            setOnClickListener { channel?.invokeMethod("onPressed", null) }
            // The window's insets are known only once the button is attached, and change with rotation or
            // the navigation mode; place it from them each time it is laid out.
            addOnLayoutChangeListener { view, _, _, _, _, _, _, _, _ -> placeInsideSafeArea(view, margin) }
        }
        decor.addView(button, FrameLayout.LayoutParams(size, size, Gravity.TOP or Gravity.END).apply {
            topMargin = margin
            marginEnd = margin
        })
        endCallButton = button
    }

    private fun hideEndCallButton() {
        endCallButton?.let { (it.parent as? ViewGroup)?.removeView(it) }
        endCallButton = null
    }

    /** Top and end margins of [margin] measured from the safe area (system bars and cut-out) of the window. */
    private fun placeInsideSafeArea(view: View, margin: Int) {
        // The raw window insets, not what the view hierarchy delivered: the content view consumes them when
        // the window is not edge-to-edge, and the button sits outside it.
        val insets = view.rootWindowInsets ?: return
        val top: Int
        val end: Int
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            val bars = insets.getInsets(WindowInsets.Type.systemBars() or WindowInsets.Type.displayCutout())
            top = bars.top
            end = bars.right
        } else {
            @Suppress("DEPRECATION")
            run {
                top = insets.systemWindowInsetTop
                end = insets.systemWindowInsetRight
            }
        }
        val params = view.layoutParams as? FrameLayout.LayoutParams ?: return
        val newTop = margin + top
        val newEnd = margin + end
        if (params.topMargin != newTop || params.marginEnd != newEnd) {
            params.topMargin = newTop
            params.marginEnd = newEnd
            view.layoutParams = params
        }
    }

    private companion object {
        const val SIZE_DP = 50f
        const val MARGIN_DP = 16f
        const val ELEVATION_DP = 8f
    }
}
