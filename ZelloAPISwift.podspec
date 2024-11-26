Pod::Spec.new do |s|

  s.name             = 'ZelloAPISwift'
  s.version          = '1.1.0'
  s.summary          = 'ZelloAPISwift is a ZelloWork server API client library written in Swift.'
  s.license          = { :type => "MIT", :file => "LICENSE" }

  s.description      =
  <<-DESC
  The Zello server API offers an easy way to interact with Zello server in order to manipulate users and channels from your application.
  The API is based on JSON over HTTP protocol. Requests are sent using GET and POST HTTP requests, server responses are returned in HTTP response body and presented in JSON.
  Each response includes "status" and "code" fields, indicating the response success status or error details. In the case of success, code is "200" and status is "OK".
  DESC

  s.homepage         = 'https://github.com/zelloptt/zellowork-server-api-libs/tree/master/swift/CocoaPod'
  s.author           = { 'Zello' => 'support@zello.com' }

  # Be mindful of this :tag. Remember to update it when releasing new versions.
  s.source           = { :git => 'https://github.com/zelloptt/zellowork-server-api-libs.git', :tag => s.version.to_s }

  s.ios.deployment_target = '12.4'

  s.preserve_paths  = "swift/CocoaPod/CommonCrypto/*"
  s.source_files    = "swift/CocoaPod/ZelloAPISwift/*.{h,m,swift}"
  s.requires_arc    = true

s.xcconfig          = {  }

  s.prepare_command = <<-CMD
                        mkdir -p CommonCrypto/iphoneos
                        mkdir -p CommonCrypto/iphonesimulator
                        mkdir -p CommonCrypto/appletvos
                        mkdir -p CommonCrypto/appletvsimulator
                        cp swift/CocoaPod/CommonCrypto/iphoneos.modulemap CommonCrypto/iphoneos/module.modulemap
                        cp swift/CocoaPod/CommonCrypto/iphonesimulator.modulemap CommonCrypto/iphonesimulator/module.modulemap
                        cp swift/CocoaPod/CommonCrypto/iphonesimulator.modulemap CommonCrypto/appletvos/module.modulemap
                        cp swift/CocoaPod/CommonCrypto/iphonesimulator.modulemap CommonCrypto/appletvsimulator/module.modulemap
                        CMD

end
