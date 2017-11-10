# Repository Composition

This repository contains two projects.
- Cirrent_Android: This project shows how to work CirrentSDK and shows how to be imported CirrentSDK to real project and how to be called CirrentSDK APIs.

- Cirrent_OpenSource: This project has opened source of CirrentSDK. So it can be possible to change and test CirrentSDK for real mode.

# CirrentSDK development

Main development should be done with Cirrent_OpenSource project.

Testing should be done with Cirrent_Android project.

* Requirements

Android Asynchronous Http Client (A Callback-Based Http Client Library for Android)

https://github.com/loopj/android-async-http

This library has been included with gradle script.

```
dependencies {
                        ...
    compile 'com.loopj.android:android-async-http:1.4.9'
                        ...    
}
```

* Development

All CirrentSDK source files in CirrentSDK module of Cirrent_OpenSource project. 

If you want to get cirrentsdk.jar (CirrentSDK library file), please write below script to build.gradle(Module: cirrentsdk)

```
task deleteJar(type: Delete) {
    delete 'libs/cirrentsdk.jar'
}

task createJar(type: Copy) {
    from('build/intermediates/bundles/release')
    into('libs/')
    include('classes.jar')
    rename('classes.jar', 'cirrentsdk.jar')
}

createJar.dependsOn(deleteJar, build)
```

http://stackoverflow.com/a/35431416/5915638

When build project with this script, android studio generates jar file automatically.
Manually, you can see gradle tab on left of android studio. Also when you click this tab, you can see cirrentsdk root.
You can double click cirrentsdk/Tasks/other/createjar. Then gradle will be running and generate jar file.

Then you can get cirrentsdk.jar file from [rootDir]/cirrentsdk/libs folder.

* Testing

To import cirrentsdk.jar file to new project, copy jar file to [rootDir]/app/libs folder.

And add gradle script to build.gradle(Module: app)

```
dependencies {
    compile fileTree(dir: 'libs', include: ['*.jar'])
                   ...
    compile 'com.loopj.android:android-async-http:1.4.9'
    compile files('libs/cirrentsdk.jar')
}
```

To import package in source code.

`import com.cirrent.cirrentsdk.[class name]`

# Specification

Android SDK 2.3.3(API 11) - 6.0(API 23)

Android Studio 2.2.2

Gradle 2.14.1

# Build Error

When you build the OpenSource project, you can get one build error. 

```
Error:Execution failed for task ':app:transformClassesWithDexForDebug'.
> com.android.build.api.transform.TransformException: com.android.ide.common.process.ProcessException: java.util.concurrent.ExecutionException: com.android.dex.DexException: Multiple dex files define
```

If you get this error

1. You should delete script for building jar file

2. delete jar file from [rootDir]/cirrentsdk/libs

3. Clean the project

4. Rebuild project

