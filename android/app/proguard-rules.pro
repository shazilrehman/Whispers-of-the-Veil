# Flutter / Flame — keep engine and plugin classes
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

# SharedPreferences
-keep class androidx.datastore.** { *; }
