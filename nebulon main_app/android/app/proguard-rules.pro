# Flutter ProGuard Rules

# Keep Flutter classes
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# local_auth ProGuard rules
-keep class io.flutter.plugins.localauth.** { *; }

# Keep androidx.biometric classes
-keep class androidx.biometric.** { *; }

# Prevent obfuscation of GeneratedPluginRegistrant
-keep class io.flutter.plugins.GeneratedPluginRegistrant { *; }

# Flutter Secure Storage
-keep class com.it_nomads.fluttersecurestorage.** { *; }

# Hive
-keep class com.google.common.reflect.** { *; }
-keep class com.hannesdorfmann.mosby3.** { *; }

# Prevent R8 from stripping away important classes
-keepattributes Signature,Annotation,Enums
-keepattributes *Annotation*
-keepattributes InnerClasses
-keepattributes EnclosingMethod
-dontwarn io.flutter.embedding.** 
