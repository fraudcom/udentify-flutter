package com.ocrflutter

/** The sentinel the camera events carry instead of image data (the captures stay native). */
internal const val IMAGE_PATH_STORED = "IMAGE_PATH_STORED"

/**
 * The front and back photos a call works on.
 *
 * What the app passed wins. The [IMAGE_PATH_STORED] sentinel and an empty value mean "none passed", and a
 * `data:image/...;base64,` prefix is tolerated. When no photo was passed at all, the camera's captures are used,
 * which is what `performOCR` does and what iOS does for the liveness calls. A null or empty result is "no photo".
 */
internal fun resolvePhotos(
    front: String?,
    back: String?,
    storedFront: String?,
    storedBack: String?
): Pair<String?, String?> {
    fun clean(photo: String?): String? =
        photo?.takeIf { it != IMAGE_PATH_STORED && it.isNotEmpty() }
            ?.let { if (it.contains("base64,")) it.substringAfter("base64,") else it }

    val passedFront = clean(front)
    val passedBack = clean(back)
    return if (passedFront == null && passedBack == null) {
        storedFront?.takeIf { it.isNotEmpty() } to storedBack?.takeIf { it.isNotEmpty() }
    } else {
        passedFront to passedBack
    }
}
