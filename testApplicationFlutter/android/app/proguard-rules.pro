# Add project specific ProGuard rules here.
# You can control the set of applied configuration files using the
# proguardFiles setting in build.gradle.

# Keep all native library classes and their methods
-keep class com.livenessflutter.** { *; }
-keep class com.mrzflutter.** { *; }
-keep class com.nfcflutter.** { *; }
-keep class com.ocrflutter.** { *; }
-keep class com.videocallflutter.** { *; }

# Keep all classes that might be accessed via reflection
-keepclassmembers class * {
    public <fields>;
    public <methods>;
}

# Keep all classes with native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep all enums
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Keep Flutter engine classes
-keep class io.flutter.** { *; }
-keep class io.flutter.embedding.** { *; }

# Keep TensorFlow Lite classes (for liveness detection)
-keep class org.tensorflow.lite.** { *; }

# Keep ML Kit classes (for face detection)
-keep class com.google.mlkit.** { *; }

# Keep OkHttp classes (used by native libraries)
-keep class okhttp3.** { *; }
-keep class okio.** { *; }

# Keep Gson classes (used for JSON parsing)
-keep class com.google.gson.** { *; }

# Keep all classes that have @Keep annotation
-keep @androidx.annotation.Keep class * {*;}
-keepclassmembers class * {
    @androidx.annotation.Keep *;
}

# Keep all Serializable classes
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}
