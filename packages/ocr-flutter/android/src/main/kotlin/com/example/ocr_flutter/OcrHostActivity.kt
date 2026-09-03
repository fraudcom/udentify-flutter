package com.example.ocr_flutter

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.util.Log
import android.view.View
import androidx.core.view.ViewCompat
import androidx.core.view.WindowInsetsCompat
import androidx.fragment.app.Fragment
import androidx.fragment.app.FragmentActivity
import androidx.fragment.app.FragmentManager

/**
 * Dedicated host for the Udentify OCR SDK fragments.
 *
 * The SDK drives its own in-flow navigation ("Next", "Retake") by calling
 * Activity.onBackPressed() directly. When its fragments are attached to the host app's
 * FlutterActivity, that call hits Flutter's onBackPressed() override, which forwards to the
 * navigation channel and pops the application's Dart Navigator instead of the SDK screen.
 * Hosting the fragments in this plain FragmentActivity keeps onBackPressed() on the AndroidX
 * OnBackPressedDispatcher, so SDK actions only move the SDK's own back stack.
 */
class OcrHostActivity : FragmentActivity() {

    companion object {
        private const val TAG = "OcrHostActivity"

        // The fragment is built by the calling manager so the SDK listener wiring stays in the
        // plugin. It cannot travel through an Intent, so it is handed over in-process.
        @Volatile
        private var pendingFragment: Fragment? = null

        @Volatile
        private var instance: OcrHostActivity? = null

        // startActivity() is asynchronous, so a second start() before onCreate() would launch a
        // duplicate activity and strand the first one on the task stack.
        @Volatile
        private var startInFlight = false

        // An instance that is on its way out cannot show anything, so it does not count as running.
        private val liveInstance: OcrHostActivity?
            get() = instance?.takeIf { !it.isFinishing && !it.isDestroyed }

        /**
         * Show [fragment] in the host activity, launching it when it is not running yet.
         */
        fun start(context: Context, fragment: Fragment, tag: String? = null) {
            liveInstance?.let {
                it.show(fragment, tag)
                return
            }
            pendingFragment = fragment
            if (startInFlight) {
                // A launch is already on its way and will pick up the fragment set above.
                return
            }
            startInFlight = true
            val intent = Intent(context, OcrHostActivity::class.java)
            if (context !is Activity) {
                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            try {
                context.startActivity(intent)
            } catch (e: Exception) {
                startInFlight = false
                pendingFragment = null
                throw e
            }
        }

        /**
         * Replace the visible SDK screen. No-op when the host activity is not running.
         */
        fun showFragment(fragment: Fragment, tag: String? = null) {
            val running = liveInstance
            if (running == null) {
                Log.w(TAG, "OcrHostActivity - showFragment ignored, host activity is not running")
                return
            }
            running.show(fragment, tag)
        }

        /**
         * Close the host activity and return to the Flutter UI. No-op when not running.
         */
        fun dismiss() {
            val running = liveInstance ?: return
            running.finish()
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        instance = this
        startInFlight = false
        padContainerForSystemBars()

        if (savedInstanceState != null) {
            // Restored after the process was reclaimed: the SDK listeners the fragments hold are
            // gone, so returning to Flutter is the only safe outcome.
            Log.w(TAG, "OcrHostActivity - Recreated without live SDK state, finishing")
            finish()
            return
        }

        val fragment = pendingFragment
        pendingFragment = null
        if (fragment == null) {
            Log.w(TAG, "OcrHostActivity - No pending fragment to show, finishing")
            finish()
            return
        }
        show(fragment, null)
    }

    /**
     * Android 15+ forces edge-to-edge windows. The SDK layouts do not read window insets, so
     * their footer buttons and camera view would slide under the status and navigation bars.
     * Padding the fragment container keeps the whole SDK screen inside the safe area.
     */
    private fun padContainerForSystemBars() {
        val container: View = findViewById(android.R.id.content) ?: return
        ViewCompat.setOnApplyWindowInsetsListener(container) { view, insets ->
            val bars = insets.getInsets(
                WindowInsetsCompat.Type.systemBars() or WindowInsetsCompat.Type.displayCutout()
            )
            view.setPadding(bars.left, bars.top, bars.right, bars.bottom)
            WindowInsetsCompat.CONSUMED
        }
    }

    private fun show(fragment: Fragment, tag: String?) {
        if (isFinishing || isDestroyed) {
            Log.w(TAG, "OcrHostActivity - show ignored, host activity is going away")
            return
        }
        val fragmentManager = supportFragmentManager
        // Each plugin-driven step replaces the whole screen, so nothing is left to go back to.
        // Keeping these transactions off the back stack means the first system back press closes
        // the SDK instead of popping into an empty container. The SDK still pushes its own review
        // screen with addToBackStack, which is what "Next" and "Retake" pop.
        if (fragmentManager.backStackEntryCount > 0) {
            fragmentManager.popBackStackImmediate(null, FragmentManager.POP_BACK_STACK_INCLUSIVE)
        }
        // SDK callbacks can arrive after the activity saved its state (home pressed mid-scan).
        // Dropping the screen there is better than crashing the host app with commit().
        fragmentManager
            .beginTransaction()
            .replace(android.R.id.content, fragment, tag)
            .commitAllowingStateLoss()
    }

    override fun onDestroy() {
        if (instance === this) {
            instance = null
        }
        super.onDestroy()
    }
}
