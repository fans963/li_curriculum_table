import groovy.json.JsonSlurper

fun rustlsPlatformVerifierMaven(): File {
    val manifestPath = File(projectDir, "../rust/Cargo.toml").canonicalPath
    val output = providers.exec {
        workingDir = projectDir.parentFile
        commandLine(
            "cargo",
            "metadata",
            "--format-version",
            "1",
            "--filter-platform",
            "aarch64-linux-android",
            "--manifest-path",
            manifestPath,
        )
    }.standardOutput.asText.get()

    val json = JsonSlurper().parseText(output) as Map<String, Any?>
    val packages = json["packages"] as List<Map<String, Any?>>
    val pkg = packages.first { it["name"] == "rustls-platform-verifier-android" }
    val manifest = File(pkg["manifest_path"] as String)
    return File(manifest.parentFile, "maven")
}

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
        maven { url = uri(rustlsPlatformVerifierMaven()) }
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
