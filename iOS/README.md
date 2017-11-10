# Repository Composition

This repository has three projects.

1. Cirrent-iOS: 
This project shows how to work CirrentSDK and shows how to be imported CirrentSDK to real project and how to be called CirrentSDK APIs.

2. CirrentSDK:
This project is for building CirrentSDK.

3. Cirrent_OpenSource:
This project has opened source of CirrentSDK. So it can be possible to change and test CirrentSDK for real mode.

# Build Project

```
sudo gem install cocoapods
pod install
```

cocoapods is required only for SDWebImage, JDProgressHUD (Cirrent-iOS, Cirrent_OpenSource).

If you don't use this third party library, it will not be required.

So CirrentSDK is an independent module and everything is inside of SDK.

Only CirrentSDK use SwiftyJSON in itself. When you change CirrentSDK, pleaes update SwiftyJSON.

https://github.com/SwiftyJSON/SwiftyJSON/tree/master/Source/SwiftyJSON.swift

# Usage of CirrentSDK

When you create a new project, you can see General tab on project panel.

If you click + button in Embedded Binaries category, it shows "Choose item to add".

Also select CirretSDK.framework file and add it.

+ Swift version: 

The framework should be imported by "import CirrentSDK" in source code.

+ Objective-C version: 

The framework should be imported by "@import CirrentSDK" in source code.

# Specification

CirrentSDK is written with Swift 3.0 and compatible iOS 8 ~ iOS 10.

Xcode 8






