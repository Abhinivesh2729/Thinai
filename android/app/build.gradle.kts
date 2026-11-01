import java.util.Properties
import java.io.FileInputStream
import java.net.URI
import java.security.MessageDigest

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "in.atmega.thinai"
    compileSdk = flutter.compileSdkVersion
    buildToolsVersion = "36.0.0"
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "in.atmega.thinai"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 24
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String?
            keyPassword = keystoreProperties["keyPassword"] as String?
            storeFile = (keystoreProperties["storeFile"] as String?)?.let { file(it) }
            storePassword = keystoreProperties["storePassword"] as String?
        }
    }

    packaging {
        // Extract .so files to disk so the bundled cloudflared can be executed.
        jniLibs {
            useLegacyPackaging = true
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            // Play flags an unshrunk release as costing memory and start-up
            // time. Resource shrinking requires code shrinking to be on, so
            // the two go together; see proguard-rules.pro for what R8 cannot
            // work out on its own.
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }
    }
}

flutter {
    source = "../.."
}

// Open-source cloudflared (Apache-2.0) for the public tunnel. Fetched at a
// pinned version and checksum rather than committing the ~37 MB binary, then
// stripped of debug info, which nearly halves what it adds to the APK.
val cloudflaredVersion = "2026.10.3"
val cloudflaredSha256 = "89297ebfb9e8c99c0dc013a1140601453cf3798d8306c5591651f4a3f5210be8"
val cloudflaredRaw = layout.buildDirectory.file("cloudflared/cloudflared-$cloudflaredVersion").get().asFile
val cloudflaredLib = file("src/main/jniLibs/arm64-v8a/libcloudflared.so")

fun sha256(f: File): String =
    MessageDigest.getInstance("SHA-256").digest(f.readBytes()).joinToString("") { "%02x".format(it) }

val fetchCloudflared by tasks.registering {
    inputs.property("version", cloudflaredVersion)
    outputs.file(cloudflaredLib)
    doLast {
        if (!cloudflaredRaw.exists() || sha256(cloudflaredRaw) != cloudflaredSha256) {
            cloudflaredRaw.parentFile.mkdirs()
            val url = "https://github.com/cloudflare/cloudflared/releases/download/" +
                "$cloudflaredVersion/cloudflared-linux-arm64"
            URI(url).toURL().openStream().use { input ->
                cloudflaredRaw.outputStream().use { input.copyTo(it) }
            }
            if (sha256(cloudflaredRaw) != cloudflaredSha256) {
                cloudflaredRaw.delete()
                throw GradleException("cloudflared checksum mismatch for $url")
            }
        }
        val os = System.getProperty("os.name").lowercase()
        val host = when {
            os.contains("win") -> "windows-x86_64"
            os.contains("mac") -> "darwin-x86_64"
            else -> "linux-x86_64"
        }
        val strip = android.ndkDirectory.resolve(
            "toolchains/llvm/prebuilt/$host/bin/llvm-strip" + if (os.contains("win")) ".exe" else "",
        )
        cloudflaredLib.parentFile.mkdirs()
        val exit = ProcessBuilder(strip.path, "-o", cloudflaredLib.path, cloudflaredRaw.path)
            .inheritIO().start().waitFor()
        if (exit != 0) throw GradleException("llvm-strip failed ($exit) on cloudflared")
    }
}

tasks.named("preBuild") { dependsOn(fetchCloudflared) }
