allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

// AGP 9 + android.builtInKotlin=false:
// - Plugins viejos (desktop_drop) aplican kotlin-android → OK
// - Plugins migrados (file_picker) NO lo aplican (asumen built-in) → Kotlin no compila
subprojects {
    pluginManager.withPlugin("com.android.library") {
        val hasKotlinSrc = file("src/main/kotlin").exists()
        val hasKotlinPlugin =
            pluginManager.hasPlugin("org.jetbrains.kotlin.android") ||
                pluginManager.hasPlugin("kotlin-android")
        if (hasKotlinSrc && !hasKotlinPlugin) {
            pluginManager.apply("org.jetbrains.kotlin.android")
        }
    }
}

// Unificar JVM 17 en plugins (después de que cada build.gradle fije 1.8/etc.).
subprojects {
    afterEvaluate {
        val android = extensions.findByName("android")
        if (android != null) {
            try {
                val compileOptions =
                    android.javaClass.methods
                        .first { it.name == "getCompileOptions" && it.parameterCount == 0 }
                        .invoke(android)
                compileOptions.javaClass
                    .getMethod("setSourceCompatibility", JavaVersion::class.java)
                    .invoke(compileOptions, JavaVersion.VERSION_17)
                compileOptions.javaClass
                    .getMethod("setTargetCompatibility", JavaVersion::class.java)
                    .invoke(compileOptions, JavaVersion.VERSION_17)
            } catch (_: ReflectiveOperationException) {
                // ignore
            }
        }

        tasks.withType<JavaCompile>().configureEach {
            sourceCompatibility = JavaVersion.VERSION_17.toString()
            targetCompatibility = JavaVersion.VERSION_17.toString()
        }
        tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
            compilerOptions {
                jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
