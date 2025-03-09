# General Rules
# ========================================================================
-keepattributes Signature, InnerClasses, EnclosingMethod, Exceptions, *Annotation*, SourceFile, LineNumberTable
-renamesourcefileattribute SourceFile
-optimizations !code/simplification/arithmetic,!code/simplification/cast,!field/*,!class/merging/*
-keepattributes *Annotation*
-keepattributes SourceFile,LineNumberTable
-keep public class * extends java.lang.Exception
-keep class kotlin.Metadata { *; }

# ========================================================================
# Android Framework Rules
# ========================================================================
-keep class * implements android.os.Parcelable {
  public static final android.os.Parcelable$Creator *;
}
-keep class * extends android.os.Parcelable {
  public static final android.os.Parcelable$Creator *;
}
-keep public class * extends android.app.Activity
-keep public class * extends android.app.Application
-keep public class * extends android.app.Service
-keep public class * extends android.content.BroadcastReceiver
-keep public class * extends android.content.ContentProvider
-keep public class * extends android.view.View
-keep public class * extends android.preference.Preference
-keep public class * extends androidx.fragment.app.Fragment
-keep public class * extends androidx.appcompat.app.AppCompatActivity
-keep public class * extends androidx.lifecycle.ViewModel
-keep public class * extends androidx.lifecycle.AndroidViewModel

# ========================================================================
# Kotlin Serialization Rules
# ========================================================================
# Keep Kotlin serialization
-keepattributes *Annotation*, InnerClasses
-dontnote kotlinx.serialization.AnnotationsKt
-keepclassmembers class kotlinx.serialization.json.** {
    *** Companion;
}
-keepclasseswithmembers class kotlinx.serialization.json.** {
    kotlinx.serialization.KSerializer serializer(...);
}
-keep class kotlinx.serialization.**{ *; }
-keepclassmembers class com.amirawellness.data.models.** {
    *** Companion;
    kotlinx.serialization.KSerializer serializer(...);
}
-keepclassmembers @kotlinx.serialization.Serializable class com.amirawellness.** {
    # lookup for plugin generated serializable classes
    *** Companion;
    # lookup for serializer instances
    kotlinx.serialization.KSerializer serializer(...);
}

# ========================================================================
# Retrofit and OkHttp Rules
# ========================================================================
# Retrofit does reflection on generic parameters. InnerClasses is required to use Signature and
# EnclosingMethod is required to use InnerClasses.
-keepattributes Signature, InnerClasses, EnclosingMethod
# Retrofit does reflection on method and parameter annotations.
-keepattributes RuntimeVisibleAnnotations, RuntimeVisibleParameterAnnotations
# Keep annotation default values (e.g., retrofit2.http.Field.encoded).
-keepattributes AnnotationDefault
# Retain service method parameters when optimizing.
-keepclassmembers,allowshrinking,allowobfuscation interface * {
    @retrofit2.http.* <methods>;
}
# Ignore JSR 305 annotations for embedding nullability information.
-dontwarn javax.annotation.**
# Guarded by a NoClassDefFoundError try/catch and only used when on the classpath.
-dontwarn kotlin.Unit
# Top-level functions that can only be used by Kotlin.
-dontwarn retrofit2.KotlinExtensions
-dontwarn retrofit2.KotlinExtensions$*
# With R8 full mode, it sees no subtypes of Retrofit interfaces since they are created with a Proxy
# and replaces all potential values with null. Explicitly keeping the interfaces prevents this.
-if interface * { @retrofit2.http.* <methods>; }
-keep,allowobfuscation interface <1>
# Keep inherited services.
-if interface * { @retrofit2.http.* <methods>; }
-keep,allowobfuscation interface * extends <1>
# With R8 full mode generic signatures are stripped for classes that are not
# kept. Suspend functions are wrapped in continuations where the type argument
# is used.
-keep,allowobfuscation,allowshrinking class kotlin.coroutines.Continuation
# R8 full mode strips generic signatures from return types if not kept.
-if interface * { @retrofit2.http.* public *** *(...); }
-keep,allowoptimization,allowshrinking,allowobfuscation class <3>
# With R8 full mode generic signatures are stripped for classes that are not kept.
-keep,allowobfuscation,allowshrinking class retrofit2.Response
# OkHttp rules
-dontwarn okhttp3.**
-dontwarn okio.**
-dontwarn javax.annotation.**
-dontwarn org.conscrypt.**
-keepnames class okhttp3.internal.publicsuffix.PublicSuffixDatabase

# ========================================================================
# Room Database Rules
# ========================================================================
# Room Database
-keep class * extends androidx.room.RoomDatabase
-keep @androidx.room.Entity class *
-dontwarn androidx.room.paging.**
-keep class * extends androidx.room.RoomDatabase { *; }
-keep @androidx.room.Database class *
-keep @androidx.room.Dao class * { *; }
-keep @androidx.room.Entity class * { *; }
-keep class com.amirawellness.data.local.** { *; }
-keep class com.amirawellness.data.models.** { *; }

# ========================================================================
# Hilt Dependency Injection Rules
# ========================================================================
# Hilt
-keep class androidx.hilt.** { *; }
-keep class dagger.hilt.** { *; }
-keep class javax.inject.** { *; }
-keep class * extends dagger.hilt.android.internal.managers.ViewComponentManager$ViewComponentBuilderEntryPoint { *; }
-keep @dagger.hilt.android.AndroidEntryPoint class *
-keepclasseswithmembers class * {
    @dagger.hilt.* <fields>;
}
-keepclasseswithmembers class * {
    @dagger.hilt.* <methods>;
}
-keep @dagger.hilt.android.lifecycle.HiltViewModel class *
-keep class * extends androidx.lifecycle.ViewModel { *; }

# ========================================================================
# Firebase Rules
# ========================================================================
# Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**
-keep class com.google.firebase.analytics.** { *; }
-keep class com.google.firebase.messaging.** { *; }

# ========================================================================
# Media3/ExoPlayer Rules
# ========================================================================
# ExoPlayer/Media3
-keep class androidx.media3.** { *; }
-keep class com.google.android.exoplayer2.** { *; }
-dontwarn com.google.android.exoplayer2.**
-dontwarn androidx.media3.**

# ========================================================================
# Encryption and Security Rules
# ========================================================================
# Encryption classes
-keep class com.amirawellness.services.encryption.** { *; }
-keep class javax.crypto.** { *; }
-keep class javax.crypto.spec.** { *; }
-keep class java.security.** { *; }
-keep class androidx.security.crypto.** { *; }

# ========================================================================
# Coroutines Rules
# ========================================================================
# Coroutines
-keepclassmembernames class kotlinx.** {
    volatile <fields>;
}
-keepclassmembers class kotlin.coroutines.** { *; }
-keep class kotlinx.coroutines.** { *; }
-dontwarn kotlinx.coroutines.**
-dontwarn org.jetbrains.annotations.**

# ========================================================================
# MPAndroidChart Rules
# ========================================================================
# MPAndroidChart
-keep class com.github.mikephil.charting.** { *; }
-dontwarn com.github.mikephil.charting.**

# ========================================================================
# Lottie Rules
# ========================================================================
# Lottie
-keep class com.airbnb.lottie.** { *; }
-dontwarn com.airbnb.lottie.**

# ========================================================================
# Coil Rules
# ========================================================================
# Coil
-keep class coil.** { *; }
-dontwarn coil.**
-keepclassmembers class * {
    @coil.annotation.* <methods>;
}

# ========================================================================
# App-Specific Rules
# ========================================================================
# Keep model classes
-keep class com.amirawellness.data.models.** { *; }
# Keep API interfaces
-keep interface com.amirawellness.data.remote.api.ApiService { *; }
# Keep DTO classes
-keep class com.amirawellness.data.remote.dto.** { *; }
# Keep Enum classes
-keep enum com.amirawellness.** { *; }
# Keep sealed classes
-keep class com.amirawellness.services.audio.PlaybackState { *; }
-keep class com.amirawellness.services.audio.PlaybackError { *; }
# Keep analytics constants
-keep class com.amirawellness.services.analytics.AnalyticsTrackers { *; }