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

subprojects {
    project.evaluationDependsOn(":app")
}

subprojects {
    val configureProject = {
        val android = project.extensions.findByName("android")
        if (android != null) {
            try {
                val compileOptions = android.javaClass.getMethod("getCompileOptions").invoke(android)
                compileOptions.javaClass.getMethod("setSourceCompatibility", JavaVersion::class.java).invoke(compileOptions, JavaVersion.VERSION_17)
                compileOptions.javaClass.getMethod("setTargetCompatibility", JavaVersion::class.java).invoke(compileOptions, JavaVersion.VERSION_17)
            } catch (e: Exception) {
                // Ignore if compileOptions setup is not supported
            }
        }

        tasks.configureEach {
            if (this.javaClass.name.startsWith("org.jetbrains.kotlin.gradle.tasks.KotlinCompile")) {
                try {
                    val compilerOptions = this.javaClass.getMethod("getCompilerOptions").invoke(this)
                    val jvmTargetProp = compilerOptions.javaClass.getMethod("getJvmTarget").invoke(compilerOptions)
                    val jvmTargetClass = Class.forName("org.jetbrains.kotlin.gradle.dsl.JvmTarget")
                    val jvmTargetValue = jvmTargetClass.getField("JVM_17").get(null)
                    jvmTargetProp.javaClass.getMethod("set", Object::class.java).invoke(jvmTargetProp, jvmTargetValue)
                } catch (e1: Exception) {
                    try {
                        val kotlinOptions = this.javaClass.getMethod("getKotlinOptions").invoke(this)
                        kotlinOptions.javaClass.getMethod("setJvmTarget", String::class.java).invoke(kotlinOptions, "17")
                    } catch (e2: Exception) {
                        // Ignore
                    }
                }
            }
        }
    }

    if (project.state.executed) {
        configureProject()
    } else {
        project.afterEvaluate {
            configureProject()
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
