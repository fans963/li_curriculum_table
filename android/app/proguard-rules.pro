# Play Store deferred components — not used, safe to ignore
-dontwarn com.google.android.play.core.**

# Flutter — keep the Flutter engine entry points
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep Rust FFI native methods (flutter_rust_bridge)
-keepclasseswithmembernames class ** {
    native <methods>;
}

# Keep data classes used by generated Flutter Rust Bridge code
-keep class ** implements io.flutter.plugin.common.MethodChannel$MethodCallHandler { *; }

# Kotlin runtime — required for plugins
-keep class kotlin.** { *; }
-dontwarn kotlin.**

# AndroidX — required for plugins (share_plus, flutter_secure_storage, etc.)
-keep class androidx.core.** { *; }
-dontwarn androidx.core.**

# rustls-platform-verifier JVM component
-keep, includedescriptorclasses class org.rustls.platformverifier.** { *; }
