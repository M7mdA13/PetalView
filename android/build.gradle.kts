// android/build.gradle.kts (Root project)

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// 🔧 حدّدي نسخة الـ NDK هنا كمصدر واحد للحقيقة
extra["ANDROID_NDK_VERSION"] = "29.0.13599879" // ← غيّريها لو عايزة 27.0.12077973

// (اختياري) حفظ المخرجات في build/ أعلى جذر المشروع لتقليل تكرار المسارات
val newBuildDir = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    // كل موديول يبني داخل build/<اسم-الموديول>
    val newSubprojectBuildDir = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)

    // (اختياري) لو محتاجة app يتقيّم قبل الباقي
    project.evaluationDependsOn(":app")
}

// مهمة تنظيف موحدة
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
