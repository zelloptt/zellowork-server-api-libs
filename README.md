# Zello Work Server API Libraries
## Project Structure

There are five client libraries included in this repository:

1. [`PHP`](https://github.com/zelloptt/zellowork-server-api-libs/tree/master/php)
2. [`Swift`](https://github.com/zelloptt/zellowork-server-api-libs/tree/master/swift)
3. [`Objective C`](https://github.com/zelloptt/zellowork-server-api-libs/tree/master/objective-c)
4. [`Java`](https://github.com/zelloptt/zellowork-server-api-libs/tree/master/java)
5. [`C#`](https://github.com/zelloptt/zellowork-server-api-libs/tree/master/csharp)

In addition, we offer our Swift and Objective C libraries available as [`CocoaPods.`](https://cocoapods.org)

Each library provides a ZelloAPI class and an test for the ZelloAPI. For the Swift, Objective C, Java and C# libraries, this test comes in the form of a project titled `APITest`. These projects will output the results of the `APITest` to the console.

## PHP Library
The [`PHP`](https://github.com/zelloptt/zellowork-server-api-libs/tree/master/php) library includes a `zello_server_api.class.php` file and a `api_test.php` script to test the functionality of the `zello_server_api.class.php` class.

To use `api_test.php`, replace the $host variable, the $apikey variable and replace the username and password strings in the `auth` method. Then, simply run the script and view the output.

## Swift Library
### CocoaPod
The [`Swift`](https://github.com/zelloptt/zellowork-server-api-libs/tree/master/swift/CocoaPod) CocoaPod creates a `ZelloAPISwift` module that can be imported into any Swift file that wishes to access the Zello Work API.

To install using Swift 3, add `pod 'ZelloAPISwift'` to your Podfile. To use Swift 2.2, add `pod 'ZelloAPISwift', '1.0.3'` to your Podfile. For more information, please see the [`Example Project.`](https://github.com/zelloptt/zellowork-server-api-libs/tree/master/swift/CocoaPod/Example)

#### Dependencies
- Swift 2.2 or higher.
- Minimum iOS Version: 8.0

### Manual Installation
The [`Swift`](https://github.com/zelloptt/zellowork-server-api-libs/tree/master/swift) library includes a `ZelloAPI.swift` file and a test project `APITest` to test the functionality of the `ZelloAPI.swift` class.

`APITest` is an iOS app project that can be run using Xcode on macOS. Open `ViewController.swift` and replace the `APITest` constructor Strings with the hostname, API key, username, and password. Then, simply run the project and view the output.

#### Dependencies
- The Swift library includes a reference to `CommonCrypto`, a C library, for the MD5 hashing of login credentials. Unfortunately, due to Swift limitations, C libraries cannot be simply imported.
Instead, Swift provides a method of importing C code through [`Bridging Headers`](https://developer.apple.com/library/ios/documentation/Swift/Conceptual/BuildingCocoaApps/MixandMatch.html).
**Any project using the `ZelloAPI.swift` class will need to having a bridging header with the following import:** `#import <CommonCrypto/CommonCrypto.h>`
- Swift 3. For those wishing to target Swift 2.2, the source code can be found [`here.`](https://github.com/zelloptt/zellowork-server-api-libs/blob/e62401243864f17314f052911b47706a01f8e826/swift/ZelloAPI.swift)
- Minimum iOS Version: 7.0

## Objective C Library
### CocoaPod
The [`Objective C`](https://github.com/zelloptt/zellowork-server-api-libs/tree/master/objective-c/CocoaPod) CocoaPod creates a `ZelloAPIObjC` module that can be imported into any Objective C file that wishes to access the Zello Work API.

To install, add `pod 'ZelloAPIObjC'` to your Podfile. For more information, please see the [`Example Project.`](https://github.com/zelloptt/zellowork-server-api-libs/tree/master/objective-c/CocoaPod/Example)

#### Dependencies
- Minimum iOS Version: 8.0

### Manual Installation
The [`Objective C`](https://github.com/zelloptt/zellowork-server-api-libs/tree/master/objective-c) library includes `ZelloAPI.h` and `ZelloAPI.m` files and a test project `APITest` to test the functionality of the `ZelloAPI` class.

`APITest` is an iOS app project that can be run using Xcode on macOS. Open `ViewController.m` and replace the `APITest` constructor NSStrings with the hostname, API key, username, and password. Then, simply run the project and view the output.

#### Dependencies
- Minimum iOS Version: 7.0

## Java Library
The [`Java`](https://github.com/zelloptt/zellowork-server-api-libs/tree/master/java) library includes a `ZelloAPI.java` file and a test project `APITest` to test the functionality of the `ZelloAPI.java` class.

`APITest` is an Android app project that can be run using Android Studio. Open `MainActivity.java` and replace the `APITest` constructor Strings with the hostname, API key, username and password. Then, simply run the project and view the output.

## C# Library
The [`C#`](https://github.com/zelloptt/zellowork-server-api-libs/tree/master/csharp) library includes a `ZelloAPI.cs` file and a test project `APITest` to test the functionality of the `ZelloAPI.cs` class.

`APITest` is a Visual Studio console project that can be run using Visual Studio on Windows or Xamarin Studio on macOS. Open `Program.cs` and replace the `APITest` constructor strings with the hostname and API key for your network. Then, replace the `Authenticate` method strings with the administrative username and password. Lastly, run the project and view the output.

### Dependencies
A reference to the `System.Web.Extensions` component is required for any project adding the `ZelloAPI.cs` class.

## See also
* [Zello Work API reference](https://zellowork.com/api.htm)
* [Zello Work client SDK for Android](https://github.com/zelloptt/zello-android-client-sdk)
