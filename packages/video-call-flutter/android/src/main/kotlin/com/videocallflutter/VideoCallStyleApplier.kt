package com.videocallflutter

import android.content.res.ColorStateList
import android.graphics.Color
import android.graphics.Typeface
import android.os.Build
import android.util.Log
import android.view.Gravity
import android.view.View
import android.view.ViewGroup
import android.widget.FrameLayout
import android.widget.ImageButton
import android.widget.TextView

/**
 * Applies the app's `VideoCallConfig` to the vendor `VCFragment`'s view tree, since the SDK only
 * supports build-time XML overrides. Views are looked up by resource name, not generated id, and one
 * that cannot be found is skipped: a later layout change loses styling rather than crashing the call.
 *
 * An element the app did not style is not touched, so the SDK keeps its own look. Colors are `#RGB`,
 * `#RRGGBB` or `#AARRGGBB`.
 */
internal class VideoCallStyleApplier(
    // Whether the microphone is on, or null while that is unknown because the call is not connected
    // yet. Supplied by the operator.
    private val micEnabled: () -> Boolean?
) {

    private var density = 1f
    private var packageName = ""
    private var resources: android.content.res.Resources? = null

    // Guards the mute icon swap specifically - setBackgroundResource re-inflates the drawable,
    // which a tint-only change should not trigger.
    private var muteBackgroundResource = 0

    /**
     * Re-applies [config] to [root], the vendor fragment's inflated view. Safe to call repeatedly
     * with the same values: every write is either idempotent or guarded by an equality check.
     */
    fun apply(root: View, config: Map<String, Any?>?) {
        if (config == null || config.isEmpty()) return
        try {
            resources = root.resources
            packageName = root.context.packageName
            density = root.resources.displayMetrics.density
            applyBackground(root, config)
            applyPipView(root, config)
            applyButtons(root, config)
            applyInstructionLabel(root, config)
        } catch (t: Throwable) {
            // Styling is cosmetic - a vendor layout change that moves or renames a view must not
            // take the call itself down with it.
            Log.w(TAG, "Failed to apply video call view styles", t)
        }
    }

    /** Forgets per-call state; the operator calls this as the call ends. */
    fun stop() {
        muteBackgroundResource = 0
        warned.clear()
    }

    // MARK: - Elements

    private fun applyBackground(root: View, config: Map<String, Any?>) {
        val backgroundColor = color(config, "backgroundColor") ?: return
        root.setBackgroundColor(backgroundColor)
        findView<View>(root, "overlay_video_call")?.setBackgroundColor(backgroundColor)
    }

    private fun applyPipView(root: View, config: Map<String, Any?>) {
        val style = map(config, "pipViewStyle")
        // Nothing about the PiP asked for: leave the SDK's view alone.
        if (style == null && string(config, "pipViewBorderColor") == null) return

        // The PiP container is the MaterialCardView wrapping the local camera renderer; only the
        // renderer itself carries an id.
        val card = findView<View>(root, "local_camera")?.parent as? View ?: return

        bool(style, "visible")?.let { card.visibility = if (it) View.VISIBLE else View.GONE }

        val params = card.layoutParams as? FrameLayout.LayoutParams
        if (params != null && style != null) {
            val horizontalAnchors = map(style, "horizontalAnchors")
            val verticalAnchors = map(style, "verticalAnchors")

            // Seeded from what the SDK already laid out, so an app that says nothing about the PiP
            // keeps the SDK's geometry and one that sets a single field changes only that field.
            var width = params.width
            var height = params.height
            var gravity = params.gravity
            var marginStart = params.marginStart
            var marginEnd = params.marginEnd
            var marginTop = params.topMargin
            var marginBottom = params.bottomMargin

            if (horizontalAnchors != null) {
                width = ViewGroup.LayoutParams.MATCH_PARENT
                marginStart = dp(dimen(horizontalAnchors, "leading") ?: 0f)
                marginEnd = dp(dimen(horizontalAnchors, "trailing") ?: 0f)
            } else {
                dimen(style, "width")?.let { width = dp(it) }
                map(style, "horizontalPosition")?.let { position ->
                    val horizontal = resolveHorizontal(position, PIP_POSITION_FLUSH_H)
                    gravity = (gravity and HORIZONTAL_GRAVITY.inv()) or horizontal.gravity
                    marginStart = horizontal.marginStart
                    marginEnd = horizontal.marginEnd
                }
            }

            if (verticalAnchors != null) {
                height = ViewGroup.LayoutParams.MATCH_PARENT
                marginTop = dp(dimen(verticalAnchors, "top") ?: 0f)
                marginBottom = dp(dimen(verticalAnchors, "bottom") ?: 0f)
            } else {
                dimen(style, "height")?.let { height = dp(it) }
                map(style, "verticalPosition")?.let { position ->
                    val vertical = resolveVertical(position, PIP_POSITION_FLUSH_V)
                    gravity = (gravity and VERTICAL_GRAVITY.inv()) or vertical.gravity
                    marginTop = vertical.marginTop
                    marginBottom = vertical.marginBottom
                }
            }

            val changed = params.width != width || params.height != height ||
                params.gravity != gravity || params.marginStart != marginStart ||
                params.marginEnd != marginEnd || params.topMargin != marginTop ||
                params.bottomMargin != marginBottom
            if (changed) {
                params.width = width
                params.height = height
                params.gravity = gravity
                params.marginStart = marginStart
                params.marginEnd = marginEnd
                params.topMargin = marginTop
                params.bottomMargin = marginBottom
                card.layoutParams = params
            }
        }

        // Reflective because MaterialCardView is only on the host app's classpath, not this
        // library's. setCardBackgroundColor, never setBackgroundColor: the latter replaces the
        // card's background drawable and takes the rounded corners and stroke with it.
        color(style, "backgroundColor")?.let {
            invoke(card, "setCardBackgroundColor", Int::class.javaPrimitiveType!!, it)
        }
        val borderColor = color(style, "borderColor") ?: color(config, "pipViewBorderColor")
        borderColor?.let { invoke(card, "setStrokeColor", Int::class.javaPrimitiveType!!, it) }
        dimen(style, "borderWidth")?.let {
            invoke(card, "setStrokeWidth", Int::class.javaPrimitiveType!!, dp(it))
        }
        dimen(style, "cornerRadius")?.let {
            invoke(card, "setRadius", Float::class.javaPrimitiveType!!, it * density)
        }
    }

    private fun applyButtons(root: View, config: Map<String, Any?>) {
        BUTTONS.forEach { spec ->
            val style = map(config, spec.configKey)
            // Not styled: leave the SDK's button exactly as it renders it.
            style ?: return@forEach

            val button = findView<ImageButton>(root, spec.idName) ?: return@forEach

            button.visibility =
                if (bool(style, "visible") ?: spec.defaultVisible) View.VISIBLE else View.GONE

            when (spec.idName) {
                MUTE_BUTTON_ID -> renderMute(button, style)
                // No per-facing state to render, unlike mute: the SDK bakes its own default into the
                // vector drawable (camera_switch.xml / @color/udentify_vc_button_camera_color).
                else -> applyButtonTint(button, style)
            }

            reposition(root, button, spec, style)
        }
    }

    // Tints rather than swaps the drawable, so the SDK's own icon, size and pressed-state
    // behaviour survive: only the colour is ours.
    private fun applyButtonTint(button: ImageButton, style: Map<String, Any?>?) {
        color(style, "color")?.let { button.backgroundTintList = ColorStateList.valueOf(it) }
    }

    // The SDK repaints the mute button itself, including its own colour, so the configured tint is
    // restored after every microphone change (the operator calls apply() on each one).
    private fun renderMute(button: ImageButton, style: Map<String, Any?>?) {
        // Only an explicit `false` is muted: null means the call is not connected yet, which is the
        // unmuted icon the SDK itself starts on.
        val muted = micEnabled() == false
        val resource = drawableId(if (muted) "mic_off" else "mic_on")
        // Guarded separately because setBackgroundResource re-inflates the drawable and requests a
        // layout, which a tint-only change should not.
        if (resource != 0 && resource != muteBackgroundResource) {
            button.setBackgroundResource(resource)
            muteBackgroundResource = resource
        }
        // After the drawable, never before: setBackgroundResource routes through
        // setBackgroundDrawable, which re-applies whatever tint is stored, and a null tint
        // restores the vector's own android:tint.
        val tint = if (muted) {
            color(style, "mutedColor") ?: color(style, "color")
        } else {
            color(style, "unmutedColor") ?: color(style, "color")
        }
        button.backgroundTintList = tint?.let { ColorStateList.valueOf(it) }
    }

    /**
     * Moves [button] out of the vendor's shared, permanently-`gone` `LinearLayout` into the root
     * `FrameLayout`, then positions it from [style]. Appending it to the root keeps it above the
     * video renderer in z-order.
     */
    private fun reposition(
        root: View,
        button: ImageButton,
        spec: ButtonSpec,
        style: Map<String, Any?>
    ) {
        val rootGroup = root as? FrameLayout ?: return

        if (button.parent !== rootGroup) {
            (button.parent as? ViewGroup)?.removeView(button)
            rootGroup.addView(button)
        }

        val size = dp(dimen(style, "size") ?: DEFAULT_BUTTON_SIZE)
        val horizontal = resolveHorizontal(map(style, "horizontalPosition"), spec.defaultHorizontal)
        val vertical = resolveVertical(map(style, "verticalPosition"), spec.defaultVertical)

        val current = button.layoutParams as? FrameLayout.LayoutParams
        val gravity = horizontal.gravity or vertical.gravity
        val unchanged = current != null && current.width == size && current.height == size &&
            current.gravity == gravity && current.marginStart == horizontal.marginStart &&
            current.marginEnd == horizontal.marginEnd &&
            current.topMargin == vertical.marginTop &&
            current.bottomMargin == vertical.marginBottom
        if (unchanged) return

        val params = FrameLayout.LayoutParams(size, size)
        params.gravity = gravity
        params.marginStart = horizontal.marginStart
        params.marginEnd = horizontal.marginEnd
        params.topMargin = vertical.marginTop
        params.bottomMargin = vertical.marginBottom
        button.layoutParams = params
    }

    private fun applyInstructionLabel(root: View, config: Map<String, Any?>) {
        val style = map(config, "instructionLabelStyle")
        val textColor = color(style, "textColor") ?: color(config, "textColor")
        if (style == null && textColor == null) return

        val label = findView<TextView>(root, "text_notification_label") ?: return

        textColor?.let { label.setTextColor(it) }
        dimen(style, "fontSize")?.let { label.textSize = it }

        applyLabelTypeface(label, style)

        when (string(style, "textAlign")) {
            "left" -> label.gravity = Gravity.START or Gravity.CENTER_VERTICAL
            "right" -> label.gravity = Gravity.END or Gravity.CENTER_VERTICAL
            "center" -> label.gravity = Gravity.CENTER
        }

        int(style, "numberOfLines")?.let { lines ->
            // 0 means "as many as needed", matching iOS' numberOfLines; Android spells that as a
            // large maxLines. minLines has to be relaxed too, because the vendor layout sets
            // android:lines="3", which pins the minimum at 3 as well.
            label.minLines = 1
            label.maxLines = if (lines <= 0) Int.MAX_VALUE else lines
        }
        dimen(style, "lineHeightMultiple")?.let {
            if (it > 0f) label.setLineSpacing(0f, it)
        }

        val leading = dimen(style, "leading")
        val trailing = dimen(style, "trailing")
        if (leading != null || trailing != null) {
            label.setPaddingRelative(
                dp(leading ?: 0f),
                label.paddingTop,
                dp(trailing ?: 0f),
                label.paddingBottom)
        }

        applyLabelVerticalPosition(label, map(style, "verticalPosition"))
    }

    /**
     * Resolves `fontFamily` + `fontWeight` onto [label]. API 28+ takes a real 100-900 weight; below
     * that only NORMAL/BOLD exist, so `medium` and `semibold` approximate.
     */
    private fun applyLabelTypeface(label: TextView, style: Map<String, Any?>?) {
        val fontFamily = string(style, "fontFamily")
        val fontWeight = string(style, "fontWeight")
        if (fontFamily == null && fontWeight == null) return

        val base = if (fontFamily != null) {
            Typeface.create(fontFamily, Typeface.NORMAL)
        } else {
            label.typeface ?: Typeface.DEFAULT
        }

        val numericWeight = when (fontWeight) {
            "regular" -> 400
            "medium" -> 500
            "semibold" -> 600
            "bold" -> 700
            else -> null
        }
        if (numericWeight == null) {
            label.typeface = base
            return
        }

        label.typeface = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            Typeface.create(base, numericWeight, false)
        } else {
            // Pre-28: only two weights exist, so round to the nearer one.
            Typeface.create(base, if (numericWeight >= 600) Typeface.BOLD else Typeface.NORMAL)
        }
    }

    /**
     * The label is constrained to all four edges of the overlay `ConstraintLayout`, so its vertical
     * placement is a bias rather than a gravity. The bias field is set reflectively because
     * ConstraintLayout is only on the host app's classpath, not this library's.
     */
    private fun applyLabelVerticalPosition(label: TextView, position: Map<String, Any?>?) {
        if (position == null) return
        val params = label.layoutParams ?: return
        val offset = dp(dimen(position, "offset") ?: 0f)

        val bias: Float
        var topMargin = 0
        var bottomMargin = 0
        when (string(position, "type")) {
            "center" -> bias = 0.5f
            "top" -> { bias = 0f; topMargin = offset }
            "bottom" -> { bias = 1f; bottomMargin = offset }
            "custom" -> { bias = 0f; topMargin = dp(dimen(position, "y") ?: 0f) }
            else -> return
        }

        try {
            params.javaClass.getField("verticalBias").setFloat(params, bias)
        } catch (t: Throwable) {
            Log.w(TAG, "Instruction label is not in a ConstraintLayout; vertical bias skipped", t)
        }
        (params as? ViewGroup.MarginLayoutParams)?.let {
            it.topMargin = topMargin
            it.bottomMargin = bottomMargin
        }
        label.layoutParams = params
    }

    // MARK: - Position resolution

    private class Horizontal(val gravity: Int, val marginStart: Int, val marginEnd: Int)

    private class Vertical(val gravity: Int, val marginTop: Int, val marginBottom: Int)

    private fun resolveHorizontal(position: Map<String, Any?>?, default: Position): Horizontal {
        val explicitType = string(position, "type")
        val type = explicitType ?: default.type
        // Once the app names an edge, an omitted offset means flush against it - the platform
        // default offset belongs to the default edge only.
        val offset = dp(dimen(position, "offset") ?: if (explicitType == null) default.offset else 0f)
        return when (type) {
            // For `center` the offset is a signed shift off centre rather than an edge inset.
            // FrameLayout lays a CENTER_HORIZONTAL child out at `centre + leftMargin - rightMargin`,
            // so the sign picks which margin carries it.
            "center" -> Horizontal(
                Gravity.CENTER_HORIZONTAL,
                if (offset > 0) offset else 0,
                if (offset < 0) -offset else 0)
            "right" -> Horizontal(Gravity.END, 0, offset)
            "custom" -> Horizontal(Gravity.START, dp(dimen(position, "x") ?: 0f), 0)
            else -> Horizontal(Gravity.START, offset, 0)
        }
    }

    private fun resolveVertical(position: Map<String, Any?>?, default: Position): Vertical {
        val explicitType = string(position, "type")
        val type = explicitType ?: default.type
        val offset = dp(dimen(position, "offset") ?: if (explicitType == null) default.offset else 0f)
        return when (type) {
            "center" -> Vertical(Gravity.CENTER_VERTICAL, 0, 0)
            "top" -> Vertical(Gravity.TOP, offset, 0)
            "custom" -> Vertical(Gravity.TOP, dp(dimen(position, "y") ?: 0f), 0)
            else -> Vertical(Gravity.BOTTOM, 0, offset)
        }
    }

    // MARK: - Reading helpers

    private fun <T : View> findView(root: View, idName: String): T? {
        val id = resources?.getIdentifier(idName, "id", packageName) ?: 0
        @Suppress("UNCHECKED_CAST")
        val view = if (id == 0) null else root.findViewById<View>(id) as? T
        if (view == null) warnMissing(idName)
        return view
    }

    // A later SDK drop may rename a view; say so once per call instead of failing silently, since the
    // style for that element is then not applied. Only reached for elements the app asked to style.
    private val warned = mutableSetOf<String>()

    private fun warnMissing(idName: String) {
        if (warned.add(idName)) {
            Log.w(TAG, "View '$idName' is not in this SDK's call layout; its style was not applied. " +
                "The SDK may have renamed it: check the styler against the new vc AAR.")
        }
    }

    private fun drawableId(name: String): Int =
        resources?.getIdentifier(name, "drawable", packageName) ?: 0

    @Suppress("UNCHECKED_CAST")
    private fun map(source: Map<String, Any?>?, key: String): Map<String, Any?>? =
        source?.get(key) as? Map<String, Any?>

    private fun string(source: Map<String, Any?>?, key: String): String? = source?.get(key) as? String

    private fun bool(source: Map<String, Any?>?, key: String): Boolean? = source?.get(key) as? Boolean

    private fun dimen(source: Map<String, Any?>?, key: String): Float? =
        (source?.get(key) as? Number)?.toFloat()

    private fun int(source: Map<String, Any?>?, key: String): Int? = dimen(source, key)?.toInt()

    /** Accepts `#RGB`, `#RRGGBB` and `#AARRGGBB`, the convention of every other plugin here. */
    private fun color(source: Map<String, Any?>?, key: String): Int? {
        val raw = string(source, key)?.trim() ?: return null
        if (!raw.startsWith("#")) return null
        val digits = raw.substring(1)
        val normalized = when (digits.length) {
            3 -> "#" + digits.map { "$it$it" }.joinToString("")
            6, 8 -> raw
            else -> return null
        }
        return try {
            Color.parseColor(normalized)
        } catch (t: IllegalArgumentException) {
            Log.w(TAG, "Ignoring unparseable color '$raw' for '$key'")
            null
        }
    }

    private fun dp(value: Float): Int = (value * density).toInt()

    private fun invoke(target: Any, method: String, argType: Class<*>, arg: Any) {
        try {
            target.javaClass.getMethod(method, argType).invoke(target, arg)
        } catch (t: Throwable) {
            Log.w(TAG, "PiP view does not support $method on this SDK build", t)
        }
    }

    private class Position(val type: String, val offset: Float)

    private class ButtonSpec(
        val idName: String,
        val configKey: String,
        val defaultVisible: Boolean,
        val defaultHorizontal: Position,
        val defaultVertical: Position
    )

    companion object {
        private const val TAG = "VideoCallStyleApplier"

        private const val MUTE_BUTTON_ID = "toggle_mic"
        private const val CAMERA_SWITCH_BUTTON_ID = "switch_camera"
        private const val FLASH_BUTTON_ID = "toggle_flash"

        // Only reached when the app has named a horizontalPosition / verticalPosition itself but
        // omitted the offset, which means flush against the edge it named. The SDK's own placement
        // is preserved by not entering that branch at all.
        private val PIP_POSITION_FLUSH_H = Position("right", 0f)
        private val PIP_POSITION_FLUSH_V = Position("bottom", 0f)
        private val HORIZONTAL_GRAVITY =
            Gravity.START or Gravity.END or Gravity.CENTER_HORIZONTAL or
                Gravity.LEFT or Gravity.RIGHT
        private val VERTICAL_GRAVITY =
            Gravity.TOP or Gravity.BOTTOM or Gravity.CENTER_VERTICAL
        private const val DEFAULT_BUTTON_SIZE = 50f

        // Defaults deliberately match the iOS SDK's own button layout (camera switch bottom-left,
        // mute bottom-center, both 50dp with a 20dp bottom inset), so an app that styles one button
        // gets the same controls in the same places on both platforms. Flash stays hidden by default.
        private val BUTTONS = listOf(
            ButtonSpec(
                idName = CAMERA_SWITCH_BUTTON_ID,
                configKey = "cameraSwitchButtonStyle",
                defaultVisible = true,
                defaultHorizontal = Position("left", 16f),
                defaultVertical = Position("bottom", 20f)),
            ButtonSpec(
                idName = MUTE_BUTTON_ID,
                configKey = "muteButtonStyle",
                defaultVisible = true,
                defaultHorizontal = Position("center", 0f),
                defaultVertical = Position("bottom", 20f)),
            ButtonSpec(
                idName = FLASH_BUTTON_ID,
                configKey = "flashButtonStyle",
                defaultVisible = false,
                defaultHorizontal = Position("right", 16f),
                defaultVertical = Position("bottom", 20f)))
    }
}
