import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Chave de assinatura: android/key.properties (fora do git) ou variáveis do CI.
val chave = Properties().apply {
    val arquivo = rootProject.file("key.properties")
    if (arquivo.exists()) arquivo.inputStream().use { load(it) }
}
fun segredo(nome: String): String? = chave.getProperty(nome) ?: System.getenv(nome)

android {
    namespace = "com.agsterr.encaixa"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.agsterr.encaixa"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        // ID do app no AdMob. Sem a variável, usa o ID de teste do Google.
        manifestPlaceholders["admobAppId"] =
            segredo("ADMOB_APP_ID") ?: "ca-app-pub-3940256099942544~3347511713"
    }

    signingConfigs {
        create("release") {
            segredo("ANDROID_KEYSTORE_PATH")?.let { storeFile = file(it) }
            storePassword = segredo("ANDROID_KEYSTORE_PASSWORD")
            keyAlias = segredo("ANDROID_KEY_ALIAS")
            keyPassword = segredo("ANDROID_KEY_PASSWORD")
        }
    }

    buildTypes {
        release {
            // Sem chave configurada, assina com a de debug (só para testar no aparelho).
            signingConfig = if (segredo("ANDROID_KEYSTORE_PATH") != null) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
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
