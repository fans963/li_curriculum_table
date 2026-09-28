fun getRustlsPlatformVersion(): String {
    val lockFile = File(rootDir, "../rust/Cargo.lock")
    if (lockFile.exists()) {
        val lines = lockFile.readLines()
        val nameIdx = lines.indexOfFirst { it.trim() == "name = \"rustls-platform-verifier-android\"" }
        if (nameIdx >= 0) {
            val versionLine = lines.drop(nameIdx + 1).firstOrNull { it.trimStart().startsWith("version = ") }
            val version = versionLine?.substringAfter('"')?.substringBefore('"')
            if (!version.isNullOrEmpty()) return version
        }
    }
    return "0.2.0"
}

extra["rustlsVersion"] = getRustlsPlatformVersion()

allprojects {
    repositories {
        val isCi = System.getenv("CI") != null
        if (!isCi) {
            // Fallback mirrors for faster downloads in China
            maven { url = uri("https://maven.aliyun.com/repository/google") }
            maven { url = uri("https://maven.aliyun.com/repository/public") }
        }
        google()
        mavenCentral()
        maven { url = uri(File(rootDir, "local-maven")) }
        maven { url = uri("https://raw.githubusercontent.com/rustls/rustls-platform-verifier/maven-archive/android-release-support/maven/") }
        maven { url = uri("https://github.com/rustls/rustls-platform-verifier/raw/maven-archive/android-release-support/maven/") }
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

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
