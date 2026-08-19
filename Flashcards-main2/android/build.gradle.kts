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

    // camera_android_camerax does not currently expose this transitive
    // dependency, although camera-core references CallbackToFutureAdapter.
    if (project.name == "camera_android_camerax") {
        project.pluginManager.withPlugin("com.android.library") {
            project.dependencies.add(
                "implementation",
                "androidx.concurrent:concurrent-futures:1.3.0",
            )
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
