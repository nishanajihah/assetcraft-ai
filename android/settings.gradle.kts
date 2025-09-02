
pluginManagement {
    plugins {
        // Updated AGP version to recommended 8.6.0
        id("com.android.application") version "8.6.0" apply false
        id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    }
    
    val flutterSdkPath = {
        val properties = java.util.Properties()
        file("local.properties").inputStream().use { properties.load(it) }
        val flutterSdkPath = properties.getProperty("flutter.sdk")
        require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
        flutterSdkPath
    }()

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

include(":app")
