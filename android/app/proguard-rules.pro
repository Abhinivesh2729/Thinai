# Keep rules for the release build's R8 pass.
#
# The Flutter Gradle plugin contributes the engine's own rules, and most
# plugins ship consumer rules inside their AAR. What is listed here is the
# code R8 cannot see being used: entry points reached by name from native or
# from the platform rather than from Java call sites.

# The foreground service and its notification receivers are named in the
# manifest and instantiated by the system, and the task handler is resolved
# through a Flutter callback handle rather than a direct reference.
-keep class com.pravera.flutter_foreground_task.** { *; }

# Reached over the platform channel by name.
-keep class com.mr.flutter.plugin.filepicker.** { *; }

# Registered from the generated plugin registrant; keeping the embedding's
# entry points avoids a stripped class surfacing only at runtime.
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugin.** { *; }

# fllama reaches libfllama.so through dart:ffi (dlopen plus symbol lookup),
# so there is no Java side for R8 to keep. Listed so the absence is a
# recorded decision rather than an oversight.

# The engine ships PlayStoreDeferredComponentManager, which references Play
# Core's split-install classes. Those are only on the classpath for apps that
# use deferred components; this app does not, so the manager is never
# instantiated and the references are dead. Without this R8 fails the build
# outright rather than warning.
#
# in_app_update pulls in com.google.android.play:app-update, which lands in
# the same package namespace but is a separate artifact and is present. It
# carries its own consumer rules inside the AAR, so this line suppresses
# warnings about the split-install half without touching it.
-dontwarn com.google.android.play.core.**
