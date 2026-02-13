plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.parthi.play"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    // Enable build optimizations
    buildFeatures {
        buildConfig = false
    }

    packagingOptions {
        resources {
            // Exclude duplicate files
            pickFirsts.add("**/libc++_shared.so")
            pickFirsts.add("**/libjsc.so")
            
            // Exclude unnecessary metadata
            excludes.add("META-INF/DEPENDENCIES")
            excludes.add("META-INF/LICENSE")
            excludes.add("META-INF/LICENSE.txt")
            excludes.add("META-INF/NOTICE")
            excludes.add("META-INF/NOTICE.txt")
            excludes.add("META-INF/ASL2.0")
        }
    }

    defaultConfig {
        applicationId = "com.parthi.play"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // Split APKs disabled due to media_kit_libs_video NDI conflicts
    // Using universal APK instead

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
            
            // Flutter apps can break with R8/resource shrinking in release;
            // keep them off unless fully audited with proper keep rules.
            isMinifyEnabled = false
            isShrinkResources = false
            
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }

    // Enable Android App Bundle for smaller distribution size
    bundle {
        language {
            enableSplit = true
        }
        density {
            enableSplit = true
        }
        abi {
            enableSplit = true
        }
    }
}

flutter {
    source = "../.."
}
