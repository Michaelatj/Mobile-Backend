// Top-level build file where you can add configuration options common to all sub-projects/modules.

buildscript {
    repositories {
        google()
        mavenCentral()
    }

    dependencies {
        classpath("com.android.tools.build:gradle:8.7.0")
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:2.1.0")
        classpath("com.google.gms:google-services:4.4.4")
    }
}

// Kotlin DSL tidak punya allprojects, gunakan subprojects
subprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Menentukan lokasi folder build baru (opsional, biar rapi)
val newBuildDir = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.set(newBuildDir)

subprojects {
    val subBuildDir = newBuildDir.dir(project.name)
    project.layout.buildDirectory.set(subBuildDir)
    project.evaluationDependsOn(":app")
}

// Task clean
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
