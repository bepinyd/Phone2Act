# Keep generic ARCore classes
-keep class com.google.ar.core.** { *; }

# Keep Sceneform classes (critical for the plugin you are using)
-keep class com.google.ar.sceneform.** { *; }
-dontwarn com.google.ar.sceneform.**

# Keep Google devtools runtime classes that often get stripped
-keep class com.google.devtools.build.android.desugar.runtime.** { *; }
-dontwarn com.google.devtools.build.android.desugar.runtime.**