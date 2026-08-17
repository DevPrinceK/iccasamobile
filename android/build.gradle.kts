allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val externalBuildDir = providers.environmentVariable("ICCASA_MOBILE_BUILD_DIR").orNull
if (externalBuildDir.isNullOrBlank()) {
    rootProject.layout.buildDirectory.value(
        rootProject.layout.buildDirectory.dir("../../build").get()
    )
} else {
    rootProject.layout.buildDirectory.set(file(externalBuildDir))
}
val newBuildDir: Directory = rootProject.layout.buildDirectory.get()

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
