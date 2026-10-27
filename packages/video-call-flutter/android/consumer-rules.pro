# See udentify-core-flutter/android/consumer-rules.pro for why these are kept.
-keep class io.udentify.** { *; }
# Reached by name from the plugin (the participant type is read from the LiveKit room by reflection).
-keep class io.livekit.** { *; }
