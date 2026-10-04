import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// ---------------------------------------------------------------- signing ---
// Where the upload key comes from, in order:
//
//   1. android/key.properties — git-ignored, for a release built by hand.
//   2. ANDROID_KEYSTORE_* in the environment — for a release built by CI,
//      where the keystore is a secret decoded to a file on the runner.
//   3. Neither, in which case the release build falls back to the debug key.
//
// That third case is deliberate and is the one worth explaining. CI builds a
// release APK on every push to scan its dex for Play Services, and anyone can
// run `flutter build apk --release` to check a release-mode bug. Neither has
// any business holding the upload key, and neither should break because it
// does not. So an unsigned-for-release build stays possible — and, because a
// debug-signed artifact that nobody notices is exactly the failure this file
// is here to prevent, demanding the upload key turns the fallback into a hard
// error. The release workflow does, so a publishable artifact cannot quietly
// come out debug-signed.
//
// Two ways to demand it, because there are two ways Gradle gets run here.
// `-PrequireUploadKey=true` is for a direct `./gradlew` invocation;
// `REQUIRE_UPLOAD_KEY` in the environment is for `flutter build`, which does
// not promise to forward an arbitrary `-P` to the Gradle it spawns.
val keystoreProperties = Properties()
rootProject.file("key.properties").let { f ->
    if (f.exists()) f.inputStream().use { keystoreProperties.load(it) }
}

// A blank value is treated as absent. An unset repository secret arrives as
// an empty string rather than as nothing, so without this a CI build would
// construct a signing config out of four empty strings and fail deep inside
// Gradle instead of here.
fun signingValue(propertyName: String, envName: String): String? =
    (keystoreProperties.getProperty(propertyName) ?: System.getenv(envName))
        ?.takeIf { it.isNotBlank() }

val uploadStorePath = signingValue("storeFile", "ANDROID_KEYSTORE_PATH")
val uploadStorePassword = signingValue("storePassword", "ANDROID_KEYSTORE_PASSWORD")
val uploadKeyAlias = signingValue("keyAlias", "ANDROID_KEY_ALIAS")
val uploadKeyPassword = signingValue("keyPassword", "ANDROID_KEY_PASSWORD")

val uploadKeyParts = mapOf(
    "storeFile/ANDROID_KEYSTORE_PATH" to uploadStorePath,
    "storePassword/ANDROID_KEYSTORE_PASSWORD" to uploadStorePassword,
    "keyAlias/ANDROID_KEY_ALIAS" to uploadKeyAlias,
    "keyPassword/ANDROID_KEY_PASSWORD" to uploadKeyPassword,
)
val haveUploadKey = uploadKeyParts.values.all { it != null }

// Resolved against android/ rather than android/app/, so a relative path in
// key.properties means what someone writing that file would expect.
// `Project.file` leaves an absolute path alone, which is what the workflow
// passes.
val uploadStoreFile = uploadStorePath?.let { rootProject.file(it) }

val requireUploadKey = project.hasProperty("requireUploadKey") ||
    System.getenv("REQUIRE_UPLOAD_KEY")?.isNotBlank() == true

if (requireUploadKey) {
    val missing = uploadKeyParts.filterValues { it == null }.keys
    if (missing.isNotEmpty()) {
        throw GradleException(
            "An upload key was demanded but is incomplete. " +
                "Missing: ${missing.joinToString(", ")}. " +
                "See docs/RELEASING.md."
        )
    }
    if (uploadStoreFile != null && !uploadStoreFile.exists()) {
        throw GradleException(
            "An upload key was demanded but the keystore is not at " +
                "${uploadStoreFile.absolutePath}."
        )
    }
}

android {
    namespace = "my.getgroup.get_teksi"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // flutter_local_notifications schedules against java.time, which is
        // API 26+. Desugaring back-fills it so the notification code runs on
        // the older devices this app is meant to reach.
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        applicationId = "my.getgroup.get_teksi"
        // API 23 covers Huawei devices still on EMUI 4/5 as well as the
        // HarmonyOS 2-4 releases, which run Android APKs.
        minSdk = 23
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (haveUploadKey) {
            create("upload") {
                storeFile = uploadStoreFile
                storePassword = uploadStorePassword
                keyAlias = uploadKeyAlias
                keyPassword = uploadKeyPassword
            }
        }
    }

    buildTypes {
        release {
            // The upload key when there is one, the debug key when there is
            // not. `-PrequireUploadKey=true` has already failed the build
            // above if the fallback would have been taken, so reaching the
            // debug branch here means nobody asked for a publishable build.
            signingConfig = if (haveUploadKey) {
                signingConfigs.getByName("upload")
            } else {
                signingConfigs.getByName("debug")
            }
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
