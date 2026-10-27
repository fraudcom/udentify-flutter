package com.mrzflutter

import android.Manifest
import android.annotation.TargetApi
import android.app.Activity
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.content.res.Configuration
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.ImageFormat
import android.graphics.Matrix
import android.graphics.Point
import android.graphics.Rect
import android.graphics.RectF
import android.graphics.SurfaceTexture
import android.hardware.camera2.CameraAccessException
import android.hardware.camera2.CameraCaptureSession
import android.hardware.camera2.CameraCharacteristics
import android.hardware.camera2.CameraDevice
import android.hardware.camera2.CameraManager
import android.hardware.camera2.CaptureRequest
import android.hardware.camera2.CaptureResult
import android.hardware.camera2.TotalCaptureResult
import android.hardware.camera2.params.StreamConfigurationMap
import android.media.ImageReader
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.HandlerThread
import android.util.Base64
import android.util.Log
import android.util.Size
import android.util.SparseIntArray
import android.view.Surface
import android.view.TextureView
import android.view.View
import android.view.WindowManager
import android.widget.Button
import android.widget.TextView
import android.widget.Toast

import androidx.annotation.NonNull
import androidx.core.app.ActivityCompat

import org.json.JSONException
import org.json.JSONObject

import java.util.ArrayList
import java.util.Arrays
import java.util.Collections
import java.util.Comparator
import java.util.List
import java.util.concurrent.Semaphore
import java.util.concurrent.TimeUnit

import io.udentify.android.mrz.AutoFitTextureView
import io.udentify.android.mrz.enums.MrzReaderMode
import io.udentify.android.mrz.reader.MrzReaderActivity

class MrzCameraActivity : MrzReaderActivity() {

    companion object {
        private const val TAG = "MrzCameraActivity"
        const val RESULT_MRZ_DATA = "result"
        // The SDK's own error name (ERR_MRZ_NOT_FOUND, ERR_INVALID_DOC_NO, ...) when a static image could not be read.
        const val RESULT_ERROR = "error"

        // Extras used to run this activity in "single image" mode (processMrzImage),
        // instead of the live camera scanning mode (startMrzCamera)
        const val EXTRA_IMAGE_BASE64 = "imageBase64"

        // A photo as base64 is several megabytes, far more than an Intent extra can carry (the Binder limit is
        // about 1 MB and a larger one makes startActivity fail), so processMrzImage hands it over in-process
        // and the activity takes it once.
        @Volatile
        private var pendingImageBase64: String? = null

        fun setPendingImage(imageBase64: String?) {
            pendingImageBase64 = imageBase64
        }

        private fun takePendingImage(): String? = pendingImageBase64.also { pendingImageBase64 = null }
        const val EXTRA_MRZ_MODE = "mode"

        /** The live scanning activity, if one is on screen, so the plugin can close it on cancel. */
        @Volatile
        private var current: java.lang.ref.WeakReference<MrzCameraActivity>? = null

        /** Closes the scanning screen if it is showing. Safe to call from any thread. */
        fun finishCurrent() {
            current?.get()?.let { activity -> activity.runOnUiThread { activity.finish() } }
        }

        private const val REQUEST_VIDEO_PERMISSIONS = 1
        private val VIDEO_PERMISSIONS = arrayOf(Manifest.permission.CAMERA)
        
        private const val STATE_PREVIEW = 0
        private const val STATE_WAITING_LOCK = 1
        private const val STATE_WAITING_PRECAPTURE = 2
        private const val STATE_WAITING_NON_PRECAPTURE = 3
        private const val STATE_PICTURE_TAKEN = 4
        
        private const val MAX_PREVIEW_WIDTH = 1920
        private const val MAX_PREVIEW_HEIGHT = 1080
    }

    private val ORIENTATIONS = SparseIntArray().apply {
        append(Surface.ROTATION_0, 90)
        append(Surface.ROTATION_90, 0)
        append(Surface.ROTATION_180, 270)
        append(Surface.ROTATION_270, 180)
    }

    private var isCameraReady = false
    private var isProcessFinished = true
    private var completed = false
    private var mrzResult: String? = null

    // When set, this activity processes a single supplied image instead of running
    // the live camera preview (backs MrzFlutter.processMrzImage)
    private val staticImageBase64: String? by lazy { intent.getStringExtra(EXTRA_IMAGE_BASE64) ?: takePendingImage() }
    private val isStaticImageMode: Boolean get() = !staticImageBase64.isNullOrEmpty()

    private var mCameraId: String? = null
    private var mTextureView: AutoFitTextureView? = null
    private var mCaptureSession: CameraCaptureSession? = null
    private var mCameraDevice: CameraDevice? = null
    private var mPreviewSize: Size? = null
    private var mBackgroundThread: HandlerThread? = null
    private var mBackgroundHandler: Handler? = null
    private var mImageReader: ImageReader? = null
    private var rect: Rect? = null
    
    private var txtDocNo: TextView? = null
    private var txtBirthDate: TextView? = null
    private var txtExpireDate: TextView? = null
    private var btnNext: Button? = null
    
    private var mPreviewRequestBuilder: CaptureRequest.Builder? = null
    private var mPreviewRequest: CaptureRequest? = null
    private var mState = STATE_PREVIEW
    private val mCameraOpenCloseLock = Semaphore(1)
    private var mFlashSupported = false
    private var mSensorOrientation = 0

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        current = java.lang.ref.WeakReference(this)
        
        // Configure window for better camera experience
        window.setFlags(
            WindowManager.LayoutParams.FLAG_FULLSCREEN,
            WindowManager.LayoutParams.FLAG_FULLSCREEN
        )
        
        // Keep screen on during scanning
        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        
        setContentView(R.layout.activity_mrz_camera)
        
        txtDocNo = findViewById(R.id.txtDocNo)
        txtBirthDate = findViewById(R.id.txtBirthDate)
        txtExpireDate = findViewById(R.id.txtExpirationDate)
        btnNext = findViewById(R.id.btnNext)
        
        btnNext?.setOnClickListener {
            val returnIntent = Intent().apply {
                putExtra(RESULT_MRZ_DATA, mrzResult)
            }
            setResult(Activity.RESULT_OK, returnIntent)
            finish()
        }
    }

    override fun onResume() {
        super.onResume()
        resetViews()

        completed = false
        isProcessFinished = true

        if (isStaticImageMode) {
            // processMrzImage(): process the supplied image once, no camera needed.
            processStaticImage()
            return
        }

        val previewView = findViewById<View>(R.id.mrz_preview)
        previewView?.post {
            rect = Rect(
                previewView.left,
                previewView.top,
                previewView.right,
                previewView.bottom
            )
        }

        mTextureView = findViewById(R.id.mrz_camera_texture)

        startBackgroundThread()

        mTextureView?.let { textureView ->
            if (textureView.isAvailable) {
                openCamera(textureView.width, textureView.height)
            } else {
                textureView.surfaceTextureListener = mSurfaceTextureListener
            }
        }
    }

    /**
     * Decodes the Base64 image supplied by MrzFlutter.processMrzImage() and runs it through
     * the same MrzReader.readMRZ(bitmap, rect) recognizer used by the live camera preview
     * (see mSurfaceTextureListener below), reusing its onSuccess/onFailure callbacks.
     */
    private fun processStaticImage() {
        val base64Image = staticImageBase64
        if (base64Image.isNullOrEmpty()) {
            onFailure(IllegalArgumentException("No image data provided"))
            return
        }

        try {
            val imageBytes = Base64.decode(base64Image, Base64.DEFAULT)
            val bitmap = BitmapFactory.decodeByteArray(imageBytes, 0, imageBytes.size)
                ?: throw IllegalArgumentException("Failed to decode image")

            Log.i(TAG, "🖼️ Processing static MRZ image (${bitmap.width}x${bitmap.height})")
            isProcessFinished = false
            readMRZ(bitmap, Rect(0, 0, bitmap.width, bitmap.height))
        } catch (e: Exception) {
            Log.e(TAG, "Error decoding static MRZ image", e)
            onFailure(e)
        }
    }
    
    override fun onPause() {
        closeCamera()
        stopBackgroundThread()
        super.onPause()
    }
    
    private fun resetViews() {
        btnNext?.visibility = View.GONE
        txtDocNo?.text = ""
        txtBirthDate?.text = ""
        txtExpireDate?.text = ""
    }
    
    override fun getCallerActivity(): Activity = this
    
    override fun getMrzReaderMode(): MrzReaderMode {
        // In single-image mode, honor the mode requested by processMrzImage(); otherwise
        // keep the existing FAST mode used for live camera scanning.
        return when (intent.getStringExtra(EXTRA_MRZ_MODE)?.lowercase()) {
            "accurate" -> MrzReaderMode.ACCURATE
            "fast" -> MrzReaderMode.FAST
            else -> MrzReaderMode.FAST
        }
    }
    
    override fun onSuccess(s: String) {
        try {
            // The SDK's result is a JSON object with doc_no, date_of_birth and date_of_expire. The
            // values are personal data: they are shown on screen and returned, never logged.
            mrzResult = s
            val mrzDataObject = JSONObject(s)
            val docNo = mrzDataObject.optString("doc_no", "")
            val birthDate = mrzDataObject.optString("date_of_birth", "")
            val expireDate = mrzDataObject.optString("date_of_expire", "")

            isProcessFinished = false
            completed = true

            // Scanning finished - let Dart's onProgress listener know before delivering the result
            // The recognizer may call back off the main thread; Flutter channel calls must be on it.
            runOnUiThread { MrzFlutterPlugin.progressChannel?.invokeMethod("onProgress", 100) }

            if (isStaticImageMode) {
                val returnIntent = Intent().apply {
                    putExtra(RESULT_MRZ_DATA, mrzResult)
                }
                setResult(Activity.RESULT_OK, returnIntent)
                finish()
                return
            }

            // The SDK's advice is to confirm the values by eye before the NFC step, so the scan ends on
            // a screen that shows them and waits for "Next".
            runOnUiThread {
                btnNext?.visibility = View.VISIBLE
                txtDocNo?.text = docNo
                txtBirthDate?.text = birthDate
                txtExpireDate?.text = expireDate
            }

        } catch (e: JSONException) {
            Log.e(TAG, "❌ Error parsing MRZ JSON: ${e.message}", e)
            onFailure(e)
        }
    }

    override fun onDestroy() {
        if (current?.get() === this) current = null
        super.onDestroy()
    }

    override fun onFailure(throwable: Throwable) {
        isProcessFinished = true
        Log.i(TAG, "❌ MRZ scanning failed: ${throwable.message}")

        if (isStaticImageMode) {
            // No SDK progress/frame retries in single-image mode - a failed read is final.
            if (!completed) {
                completed = true
                // Not a user cancel: carry the SDK's error name so the plugin can report it.
                setResult(Activity.RESULT_CANCELED, Intent().putExtra(RESULT_ERROR, throwable.message))
                finish()
            }
            return
        }

        // Live mode: an unreadable frame is not final. isProcessFinished is set above, so the next
        // camera frame is scanned again until the SDK reports success or the user cancels.
    }

    private val mSurfaceTextureListener = object : TextureView.SurfaceTextureListener {
        override fun onSurfaceTextureAvailable(texture: SurfaceTexture, width: Int, height: Int) {
            openCamera(width, height)
        }
        
        override fun onSurfaceTextureSizeChanged(texture: SurfaceTexture, width: Int, height: Int) {
            configureTransform(width, height)
        }
        
        override fun onSurfaceTextureDestroyed(texture: SurfaceTexture): Boolean = true
        
        override fun onSurfaceTextureUpdated(texture: SurfaceTexture) {
            if (isCameraReady && !completed && rect != null) {
                if (!isProcessFinished) return
                
                isProcessFinished = false

                // The MRZ SDK reports no progress on Android (MrzListener only has onSuccess and
                // onFailure), so none is emitted while scanning; onProgress fires once, at 100,
                // when onSuccess arrives. iOS reports real progress.
                mTextureView?.let { textureView ->
                    val photo = textureView.getBitmap()
                    rect?.let { r -> readMRZ(photo, r) }  // This is the key - direct call to SDK method!
                }
            }
        }
    }
    
    private val mStateCallback = object : CameraDevice.StateCallback() {
        override fun onOpened(cameraDevice: CameraDevice) {
            mCameraOpenCloseLock.release()
            mCameraDevice = cameraDevice
            createCameraPreviewSession()
        }
        
        override fun onDisconnected(cameraDevice: CameraDevice) {
            mCameraOpenCloseLock.release()
            cameraDevice.close()
            mCameraDevice = null
        }
        
        override fun onError(cameraDevice: CameraDevice, error: Int) {
            mCameraOpenCloseLock.release()
            cameraDevice.close()
            mCameraDevice = null
            finish()
        }
    }
    
    private fun startBackgroundThread() {
        mBackgroundThread = HandlerThread("CameraBackground")
        mBackgroundThread?.start()
        mBackgroundHandler = Handler(mBackgroundThread?.looper!!)
    }
    
    private fun stopBackgroundThread() {
        mBackgroundThread?.quitSafely()
        try {
            mBackgroundThread?.join()
            mBackgroundThread = null
            mBackgroundHandler = null
        } catch (e: InterruptedException) {
            e.printStackTrace()
        }
    }
    
    @TargetApi(Build.VERSION_CODES.M)
    private fun requestVideoPermissions() {
        requestPermissions(VIDEO_PERMISSIONS, REQUEST_VIDEO_PERMISSIONS)
    }
    
    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<String>,
        grantResults: IntArray
    ) {
        if (requestCode == REQUEST_VIDEO_PERMISSIONS) {
            if (grantResults.isNotEmpty() && grantResults.all { it == PackageManager.PERMISSION_GRANTED }) {
                // Permissions granted
            } else {
                Toast.makeText(this, getString(R.string.mrz_toast_camera_permission_required), Toast.LENGTH_SHORT).show()
                finish()
            }
        } else {
            super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        }
    }
    
    private fun hasPermissionsGranted(permissions: Array<String>): Boolean {
        return permissions.all {
            ActivityCompat.checkSelfPermission(this, it) == PackageManager.PERMISSION_GRANTED
        }
    }
    
    @Suppress("MissingPermission")
    private fun openCamera(width: Int, height: Int) {
        if (!hasPermissionsGranted(VIDEO_PERMISSIONS)) {
            requestVideoPermissions()
            return
        }
        
        setUpCameraOutputs(width, height)
        configureTransform(width, height)
        
        val manager = getSystemService(Context.CAMERA_SERVICE) as CameraManager
        try {
            if (!mCameraOpenCloseLock.tryAcquire(2500, TimeUnit.MILLISECONDS)) {
                throw RuntimeException("Time out waiting to lock camera opening.")
            }
            mCameraId?.let { cameraId ->
                manager.openCamera(cameraId, mStateCallback, mBackgroundHandler)
                isCameraReady = true
            }
        } catch (e: CameraAccessException) {
            e.printStackTrace()
        } catch (e: InterruptedException) {
            throw RuntimeException("Interrupted while trying to lock camera opening.", e)
        }
    }
    
    private fun closeCamera() {
        try {
            mCameraOpenCloseLock.acquire()
            mCaptureSession?.close()
            mCaptureSession = null
            mCameraDevice?.close()
            mCameraDevice = null
            mImageReader?.close()
            mImageReader = null
            isCameraReady = false
        } catch (e: InterruptedException) {
            throw RuntimeException("Interrupted while trying to lock camera closing.", e)
        } finally {
            mCameraOpenCloseLock.release()
        }
    }
    
    private fun setUpCameraOutputs(width: Int, height: Int) {
        val manager = getSystemService(Context.CAMERA_SERVICE) as CameraManager
        try {
            for (cameraId in manager.cameraIdList) {
                val characteristics = manager.getCameraCharacteristics(cameraId)
                
                val facing = characteristics.get(CameraCharacteristics.LENS_FACING)
                if (facing != null && facing == CameraCharacteristics.LENS_FACING_FRONT) {
                    continue
                }
                
                val map = characteristics.get(CameraCharacteristics.SCALER_STREAM_CONFIGURATION_MAP)
                    ?: continue
                
                val largest = chooseFullScreenPreview(map.getOutputSizes(ImageFormat.JPEG))
                val standard = Size(1280, 720)
                
                val finalSize = if (largest.width > standard.width && largest.height > standard.height) {
                    standard
                } else {
                    largest
                }
                
                mImageReader = ImageReader.newInstance(finalSize.width, finalSize.height, ImageFormat.JPEG, 1)
                
                val displayRotation = windowManager.defaultDisplay.rotation
                mSensorOrientation = characteristics.get(CameraCharacteristics.SENSOR_ORIENTATION) ?: 0
                
                var swappedDimensions = false
                when (displayRotation) {
                    Surface.ROTATION_0, Surface.ROTATION_180 -> {
                        if (mSensorOrientation == 90 || mSensorOrientation == 270) {
                            swappedDimensions = true
                        }
                    }
                    Surface.ROTATION_90, Surface.ROTATION_270 -> {
                        if (mSensorOrientation == 0 || mSensorOrientation == 180) {
                            swappedDimensions = true
                        }
                    }
                }
                
                val displaySize = Point()
                windowManager.defaultDisplay.getSize(displaySize)
                
                var rotatedPreviewWidth = width
                var rotatedPreviewHeight = height
                var maxPreviewWidth = displaySize.x
                var maxPreviewHeight = displaySize.y
                
                if (swappedDimensions) {
                    rotatedPreviewWidth = height
                    rotatedPreviewHeight = width
                    maxPreviewWidth = displaySize.y
                    maxPreviewHeight = displaySize.x
                }
                
                if (maxPreviewWidth > MAX_PREVIEW_WIDTH) {
                    maxPreviewWidth = MAX_PREVIEW_WIDTH
                }
                
                if (maxPreviewHeight > MAX_PREVIEW_HEIGHT) {
                    maxPreviewHeight = MAX_PREVIEW_HEIGHT
                }
                
                mPreviewSize = chooseOptimalSize(
                    map.getOutputSizes(SurfaceTexture::class.java),
                    rotatedPreviewWidth, rotatedPreviewHeight,
                    maxPreviewWidth, maxPreviewHeight, finalSize
                )
                
                val orientation = resources.configuration.orientation
                if (orientation == Configuration.ORIENTATION_LANDSCAPE) {
                    mTextureView?.setAspectRatio(mPreviewSize?.width ?: 0, mPreviewSize?.height ?: 0)
                } else {
                    mTextureView?.setAspectRatio(displaySize.x, displaySize.y)
                }
                
                val available = characteristics.get(CameraCharacteristics.FLASH_INFO_AVAILABLE)
                mFlashSupported = available ?: false
                
                mCameraId = cameraId
                return
            }
        } catch (e: CameraAccessException) {
            e.printStackTrace()
        } catch (e: NullPointerException) {
            Toast.makeText(this, getString(R.string.mrz_camera2_not_supported), Toast.LENGTH_SHORT).show()
        }
    }
    
    private fun createCameraPreviewSession() {
        try {
            val texture = mTextureView?.surfaceTexture ?: return
            
            texture.setDefaultBufferSize(mPreviewSize?.width ?: 0, mPreviewSize?.height ?: 0)
            val surface = Surface(texture)
            
            mPreviewRequestBuilder = mCameraDevice?.createCaptureRequest(CameraDevice.TEMPLATE_PREVIEW)
            mPreviewRequestBuilder?.addTarget(surface)
            
            mCameraDevice?.createCaptureSession(
                Arrays.asList(surface, mImageReader?.surface),
                object : CameraCaptureSession.StateCallback() {
                    override fun onConfigured(cameraCaptureSession: CameraCaptureSession) {
                        if (mCameraDevice == null) return
                        
                        mCaptureSession = cameraCaptureSession
                        try {
                            mPreviewRequestBuilder?.set(
                                CaptureRequest.CONTROL_AF_MODE,
                                CaptureRequest.CONTROL_AF_MODE_CONTINUOUS_PICTURE
                            )
                            
                            setAutoFlash(mPreviewRequestBuilder)
                            
                            mPreviewRequest = mPreviewRequestBuilder?.build()
                            mPreviewRequest?.let { request ->
                                mCaptureSession?.setRepeatingRequest(request, null, mBackgroundHandler)
                            }
                        } catch (e: CameraAccessException) {
                            e.printStackTrace()
                        }
                    }
                    
                    override fun onConfigureFailed(cameraCaptureSession: CameraCaptureSession) {
                        Toast.makeText(this@MrzCameraActivity, getString(R.string.mrz_toast_camera_configuration_failed), Toast.LENGTH_SHORT).show()
                    }
                }, null
            )
        } catch (e: CameraAccessException) {
            e.printStackTrace()
        }
    }
    
    private fun configureTransform(viewWidth: Int, viewHeight: Int) {
        val textureView = mTextureView ?: return
        val previewSize = mPreviewSize ?: return
        
        val rotation = windowManager.defaultDisplay.rotation
        val matrix = Matrix()
        val viewRect = RectF(0f, 0f, viewWidth.toFloat(), viewHeight.toFloat())
        val bufferRect = RectF(0f, 0f, previewSize.height.toFloat(), previewSize.width.toFloat())
        val centerX = viewRect.centerX()
        val centerY = viewRect.centerY()
        
        if (Surface.ROTATION_90 == rotation || Surface.ROTATION_270 == rotation) {
            bufferRect.offset(centerX - bufferRect.centerX(), centerY - bufferRect.centerY())
            matrix.setRectToRect(viewRect, bufferRect, Matrix.ScaleToFit.FILL)
            val scale = Math.max(
                viewHeight.toFloat() / previewSize.height,
                viewWidth.toFloat() / previewSize.width
            )
            matrix.postScale(scale, scale, centerX, centerY)
            matrix.postRotate(90f * (rotation - 2), centerX, centerY)
        } else if (Surface.ROTATION_180 == rotation) {
            matrix.postRotate(180f, centerX, centerY)
        }
        textureView.setTransform(matrix)
    }
    
    private fun setAutoFlash(requestBuilder: CaptureRequest.Builder?) {
        if (mFlashSupported) {
            requestBuilder?.set(
                CaptureRequest.CONTROL_AE_MODE,
                CaptureRequest.CONTROL_AE_MODE_ON_AUTO_FLASH
            )
        }
    }
    
    private fun chooseOptimalSize(
        choices: Array<Size>,
        textureViewWidth: Int,
        textureViewHeight: Int,
        maxWidth: Int,
        maxHeight: Int,
        aspectRatio: Size
    ): Size {
        val bigEnough = ArrayList<Size>()
        val notBigEnough = ArrayList<Size>()
        val w = aspectRatio.width
        val h = aspectRatio.height
        
        for (option in choices) {
            if (option.width <= maxWidth && option.height <= maxHeight &&
                option.height == option.width * h / w
            ) {
                if (option.width >= textureViewWidth && option.height >= textureViewHeight) {
                    bigEnough.add(option)
                } else {
                    notBigEnough.add(option)
                }
            }
        }
        
        return when {
            bigEnough.size > 0 -> Collections.min(bigEnough, CompareSizesByArea())
            notBigEnough.size > 0 -> Collections.max(notBigEnough, CompareSizesByArea())
            else -> {
                Log.e(TAG, "Couldn't find any suitable preview size")
                choices[1]
            }
        }
    }
    
    private fun chooseFullScreenPreview(sizes: Array<Size>): Size {
        val fullScreenSizes = ArrayList<Size>()
        for (size in sizes) {
            if (size.width > size.height) {
                if (size.height * 16 / size.width == 9) {
                    fullScreenSizes.add(size)
                }
            } else {
                if (size.width * 16 / size.height == 9) {
                    fullScreenSizes.add(size)
                }
            }
        }
        return if (fullScreenSizes.isNotEmpty()) {
            Collections.max(fullScreenSizes, CompareSizesByArea())
        } else {
            sizes[0]
        }
    }
    
    class CompareSizesByArea : Comparator<Size> {
        override fun compare(lhs: Size, rhs: Size): Int {
            return java.lang.Long.signum(
                lhs.width.toLong() * lhs.height - rhs.width.toLong() * rhs.height
            )
        }
    }
}