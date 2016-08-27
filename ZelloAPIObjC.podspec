Pod::Spec.new do |s|

  s.name             = 'ZelloAPIObjC'
  s.version          = '1.0'
  s.summary          = 'ZelloAPIObjC is a Zello for Work server API client library written in Objective C.'
  s.license          = { :type => "MIT", :file => "LICENSE" }

  s.description      =
  <<-DESC
  The Zello server API offers an easy way to interact with Zello server in order to manipulate users and channels from your application.
  The API is based on JSON over HTTP protocol. Requests are sent using GET and POST HTTP requests, server responses are returned in HTTP response body and presented in JSON.
  Each response includes "status" and "code" fields, indicating the response success status or error details. In the case of success, code is "200" and status is "OK".
  DESC

  s.homepage         = 'https://github.com/zelloptt/zello-for-work-server-api-libs/tree/master/objective-c/CocoaPod'
  s.author           = { 'Zello' => 'support@zello.com' }

  s.source           = { :git => 'https://github.com/zelloptt/zello-for-work-server-api-libs.git', :tag => s.version.to_s }

  s.ios.deployment_target = '8.0'

  s.source_files    = "objective-c/CocoaPod/ZelloAPISwift/*"
  s.requires_arc    = true

end
