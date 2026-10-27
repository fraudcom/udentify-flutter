# Shipped with the plugin so an app's R8 / ProGuard keeps what the Udentify SDK needs. The plugins reach into
# the SDK by name (Class.forName, a dynamic Proxy over its interfaces, reflection on its result objects), and
# Flutter enables R8 for release builds by default, so renamed or removed SDK classes would break at runtime.
-keep class io.udentify.** { *; }
