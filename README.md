# Zello Work Server API Libraries
## Project Structure

There are six client libraries in this repository:

1. [`PHP`](https://github.com/zelloptt/zellowork-server-api-libs/tree/master/php)
2. [`Python`](https://github.com/zelloptt/zellowork-server-api-libs/tree/master/python)
3. [`Swift`](https://github.com/zelloptt/zellowork-server-api-libs/tree/master/swift)
4. [`Objective C`](https://github.com/zelloptt/zellowork-server-api-libs/tree/master/objective-c)
5. [`Java`](https://github.com/zelloptt/zellowork-server-api-libs/tree/master/java)
6. [`C#`](https://github.com/zelloptt/zellowork-server-api-libs/tree/master/csharp)

Swift and Objective C are also published as [`CocoaPods`](https://cocoapods.org).

Each library exposes a Zello API client. PHP has `api_test.php`; Python has `main.py`; Swift, Objective C, Java, and C# ship an `APITest` project that prints results to the console.

## Authentication (1.2.0+)

**Breaking change.** `authenticate` / `auth` / `login` now call [`user/auth`](https://zellowork.com/api.htm#auth) by default. The client sends the password as given, plus `api_mac`: HMAC-SHA256 of `username:token` keyed by the network API key. It does not MD5-hash the password before login.

Older Zello Enterprise Server (ZES) that only implement MD5 [`user/login`](https://zellowork.com/api.htm#login) still work if you set the legacy flag:

| Language | Flag |
|----------|------|
| PHP | `$api->use_legacy_auth = true;` |
| Python | `zellowork_api(..., use_legacy_auth=True)` |
| Java, Swift, Objective-C | `api.useLegacyAuth = true` |
| C# | `api.UseLegacyAuth = true` |

Hosts with no scheme default to `https://`. Use HTTPS; HTTP sends credentials in the clear.

To smoke-test every library against a live network from a Mac, see [`tools/live-test/README.md`](tools/live-test/README.md).

## PHP Library
The [`PHP`](https://github.com/zelloptt/zellowork-server-api-libs/tree/master/php) library includes a `zello_server_api.class.php` file and a `api_test.php` script to test the functionality of the `zello_server_api.class.php` class.

To use `api_test.php`, replace the `$host` variable, the `$apikey` variable, and the username and password strings in the `auth` method. Then run the script. For older ZES, set `$ltapi->use_legacy_auth = true` before `auth`.

## Python Library
The [`Python`](https://github.com/zelloptt/zellowork-server-api-libs/tree/master/python) library is `utils.py` (`zellowork_api`) plus a `main.py` sample.

Create `params.json` next to `main.py` with `USERNAME`, `PASSWORD`, `NETWORK`, and `API_KEY`, then run `python main.py`. `login()` uses `/user/auth` unless you pass `use_legacy_auth=True` to `zellowork_api`.

Depends on [`requests`](https://pypi.org/project/requests/).

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
- The Swift library includes a reference to `CommonCrypto`, a C library, for HMAC-SHA256 login credentials and MD5 hashing of user password attributes. Unfortunately, due to Swift limitations, C libraries cannot be simply imported.
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
