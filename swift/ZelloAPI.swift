//
//  Copyright © 2016 Zello. All rights reserved.
//

import Foundation

/// Completion Handler for making API Requests that returns a success indicator, result dictionary and error.
/// A value for the error variable represents a client error. This is not the error returned by the API.
/// An error returned by the API can be retrieved through the result dictionary.
/// This closure is always executed on the main thread.
public typealias ResultCompletionHandler = (Bool, [String : AnyObject]?, NSError?) -> Void

/**
 Zello for Work server Swift API wrapper class.

 The class provides an easy way to interact with Zello for Work server
 from your Swift code to add, modify and delete users and channels.
 Please note that all text values passed to the API must be in UTF-8 encoding
 and any text data returned are in UTF-8 as well.

 - Version 1.0.0
 - Swift Version 2.2
 - Minimum iOS Version 7.0
*/
public class ZelloAPI {
  
  // MARK: Public Variables
  
  /// API Version
  public static let version = "1.0.0"
  
  /// Session ID used to identify logged in client. Typically you'll want to authenticate first and store the Session ID to reuse later.
  public var sessionId: String?
  
  /// Last accessed API URL. Useful for API troubleshooting.
  public var lastURL: String?
  
  // MARK: Private Variables
  
  /// Server hostname or IP address
  private var host: String?
  /// API Key
  private var apiKey: String?
  
  // MARK: Initializer
  
  public convenience init(host: String, apiKey: String, sessionId: String?=nil) {
    self.init()
    
    self.host = host
    self.apiKey = apiKey
    self.sessionId = sessionId
  }
  
  // MARK: Public Methods
  
  /**
   API client authentication.
   If authentication fails, use the errorCode and errorDescription attributes on the response dictionary to get error details.
   If authentication succeeds, sessionId is set to the Session ID.
   The Session ID is reusable so it's recommended that you save this value and use it for further API calls.
   Once you are done using the API, call ZelloAPI.logout() to end the session and invalidate Session ID.
   
   - parameter username:          administrative username
   - parameter password:          administrative password
   - parameter completionHandler: completion handler indicating success, response and error.
   */
  public func authenticate(username: String, password: String, completionHandler: ResultCompletionHandler) {
    callAPI("user/gettoken", httpMethod: .GET, completionHandler: { [weak self] (success, response, error) -> Void in
      // On main thread
      guard let weakSelf = self else {
        completionHandler(false, response, error)
        return
      }
      
      if !success {
        completionHandler(success, response, error)
        return
      }
      
      guard let response = response else {
        completionHandler(false, nil, error)
        return
      }
      
      guard let token = response["token"] as? String else {
        completionHandler(false, response, error)
        return
      }
      
      weakSelf.sessionId = response["sid"] as? String
      
      guard let apiKey = weakSelf.apiKey else {
        completionHandler(false, response, error)
        return
      }
      
      let parameters = "username=\(username)&password=\((password.MD5() + token + apiKey).MD5())"
      
      weakSelf.callAPI("user/login", httpMethod: .POST, parameters: parameters, completionHandler: completionHandler)
    })
  }
  
  /**
   Ends session identified by sessionId.
   Use this method to terminate the API session.
   See ZelloAPI.authenticate()
   
   - parameter completionHandler: completion handler indicating success, response and error.
   */
  public func logout(completionHandler: ResultCompletionHandler) {
    callAPI("user/logout", httpMethod: .GET, completionHandler: { [weak self] (success, response, error) -> Void in
      self?.sessionId = nil
      
      completionHandler(success, response, error)
    })
  }
  
  /**
   Gets the list of the users or detailed informatino regarding a particular user.
   
   - parameter username:          username of the user, for which the details are requested. If nil, the full users list is returned.
   - parameter isGateway:         whether to return users or gateways.
   - parameter max:               maximum number of results to fetch.
   - parameter start:             start index of results to fetch.
   - parameter channel:           channel name.
   - parameter completionHandler: completion handler indicating success, response and error.
   */
  public func getUsers(username: String?=nil, isGateway: Bool?=false, max: Int?=nil, start: Int?=nil, channel: String?=nil, completionHandler: ResultCompletionHandler) {
    var command = "user/get"
    
    if let username = username {
      command += "/login/" + username.urlEncode()
    }
    if let channel = channel {
      command += "/channel/" + channel.urlEncode()
    }
    if let isGateway = isGateway where isGateway {
      command += "/gateway/1"
    }
    if let max = max {
      command += "/max/" + String(max)
    }
    if let start = start {
      command += "/start/" + String(start)
    }
    
    callAPI(command, httpMethod: .GET, completionHandler: completionHandler)
  }
  
  /**
   Gets the list of the channels or detailed information regarding a particular channel.
   
   - parameter name:              name of the channel, for which the details are requested. If omitted, the full channels list is returned.
   - parameter max:               maximum number of results to fetch.
   - parameter start:             start index of results to fetch.
   - parameter completionHandler: completion handler indicating success, response and error.
   */
  public func getChannels(name: String?=nil, max: Int?=nil, start: Int?=nil, completionHandler: ResultCompletionHandler) {
    var command = "channel/get"
    
    if let name = name {
      command += "/name/" + name.urlEncode()
    }
    if let max = max {
      command += "/max/" + String(max)
    }
    if let start = start {
      command += "/start/" + String(start)
    }
    
    callAPI(command, httpMethod: .GET, completionHandler: completionHandler)
  }
  
  /**
   Adds users to a channel.
   
   - parameter channelName: name of the channel where the users will be added.
   - parameter users:       usernames of the users to add.
   - parameter completionHandler: completion handler indicating success, response and error.
   */
  public func addToChannel(channelName: String, users: [String], completionHandler: ResultCompletionHandler) {
    let command = "user/addto/" + channelName.urlEncode()
    
    let parameters = "login[]=".implode("&login[]=", pieces: users)

    callAPI(command, httpMethod: .POST, parameters: parameters, completionHandler: completionHandler)
  }
  
  /**
   Add users to multiple channels.
   
   - parameter channelNames:      channel names where the users are added.
   - parameter users:             usernames of the users to add.
   - parameter completionHandler: completion handler indicating success, response and error.
   */
  public func addToChannels(channelNames: [String], users: [String], completionHandler: ResultCompletionHandler) {
    let command = "user/addtochannels"
    
    var parameters = "users[]=".implode("&users[]=", pieces: users)
    parameters += "&channels[]=".implode("&channels[]=", pieces: channelNames)
    
    callAPI(command, httpMethod: .POST, parameters: parameters, completionHandler: completionHandler)
  }
  
  /**
   Removes users from a channel.
   
   - parameter channelName:       name of the channel.
   - parameter users:             usernames of the users to remove from the channel.
   - parameter completionHandler: completion handler indicating success, response and error.
   */
  public func removeFromChannel(channelName: String, users: [String], completionHandler: ResultCompletionHandler) {
    let command = "user/removefrom/" + channelName.urlEncode()
    
    let parameters = "login[]=".implode("&login[]=", pieces: users)
    
    callAPI(command, httpMethod: .POST, parameters: parameters, completionHandler: completionHandler)
  }
  
  /**
   Removes users from multiple channels.
   
   - parameter channelNames:      names of the channels.
   - parameter users:             usernames of the users to remove from channels.
   - parameter completionHandler: completion handler indicating success, response and error.
   */
  public func removeFromChannels(channelNames: [String], users: [String], completionHandler: ResultCompletionHandler) {
    let command = "user/removefromchannels"
    
    var parameters = "users[]=".implode("&users[]=", pieces: users)
    parameters += "&channels[]=".implode("&channels[]=", pieces: channelNames)
    
    callAPI(command, httpMethod: .POST, parameters: parameters, completionHandler: completionHandler)
  }
  
  /**
   Adds or updates the user.
   If username exists, the user is updated. Otherwise, a new user is created.
   When adding a user, the "name" and "password" attributes are required.
   When updating a user, the "name" attribute is required.
   
   See ZelloAPI.deleteUsers()
   
   Attributes:
   - name (required) - username
   - password - password md5 hash
   - email - e-mail address
   - full_name - user alias
   - job - user position
   - admin - "true" or "false". Defines whether the user has access to the admin console.
   - limited_access - "true" or "false". Defines whether the user is restricted from starting 1-on-1 conversations or not.
   - gateway - set to "true" for adding a gateway, "false" if normal user.
   - add - "true" or "false". If set to "true", the existing user will not be updated and an error will be returned.
   
   - parameter user:              dictionary of user attributes.
   - parameter completionHandler: completion handler indicating success, response and error.
   */
  public func saveUser(user: [String : String], completionHandler: ResultCompletionHandler) {
    let command = "user/save"
    
    let parameters = createURLStringFromDictionary(user)
    
    callAPI(command, httpMethod: .POST, parameters: parameters, completionHandler: completionHandler)
  }
  
  /**
   Deletes users.
   
   See ZelloAPI.saveUser()
   
   - parameter users:             usernames of the users to remove.
   - parameter completionHandler: completion handler indicating success, response and error.
   */
  public func deleteUsers(users: [String], completionHandler: ResultCompletionHandler) {
    let command = "user/delete"
    
    let parameters = "login[]=".implode("&login[]=", pieces: users)
    
    callAPI(command, httpMethod: .POST, parameters: parameters, completionHandler: completionHandler)
  }
  
  /**
   Adds a new channel.
   
   - parameter name:              channel name.
   - parameter isGroup:           true means it is a group channel. false means it is a dynamic channel.
   - parameter isHidden:          when set to true in combination with isGroup set to true, a hidden group channel is created.
   - parameter completionHandler: completion handler indicating success, response and error.
   */
  public func addChannel(name: String, isGroup: Bool?=nil, isHidden: Bool?=nil, completionHandler: ResultCompletionHandler) {
    var command = "channel/add/name/" + name.urlEncode()
    
    if let isGroup = isGroup {
      command += "/shared/" + (isGroup ? "true" : "false")
    }
    if let isHidden = isHidden {
      command += "/invisible/" + (isHidden ? "true" : "false")
    }
    
    callAPI(command, httpMethod: .GET, completionHandler: completionHandler)
  }
  
  /**
   Deletes channels.
   
   - parameter channelNames:      names of the channels to remove.
   - parameter completionHandler: completion handler indicating success, response and error.
   */
  public func deleteChannels(channelNames: [String], completionHandler: ResultCompletionHandler) {
    let command = "channel/delete"
    
    let parameters = "name[]=".implode("&name[]=", pieces: channelNames)
    
    callAPI(command, httpMethod: .POST, parameters: parameters, completionHandler: completionHandler)
  }
  
  /**
   Get channel roles (simple format).
   
   - parameter channelName:       channel name.
   - parameter completionHandler: completion handler indicating success, response and error.
   */
  public func getChannelsRoles(channelName: String, completionHandler: ResultCompletionHandler) {
    let command = "channel/roleslist/name/" + channelName.urlEncode()
    
    callAPI(command, httpMethod: .GET, completionHandler: completionHandler)
  }
  
  /**
   Adds or updates channel role.
   
   - parameter channelName:       channel name.
   - parameter roleName:          new role name.
   - parameter settings:          role settings in JSON format: ["listen_only" : false, "no_disconnect" : true, "allow_alerts" : false, "to": ["dispatchers"]]
   - parameter completionHandler: completion handler indicating success, response and error.
   */
  public func saveChannelRole(channelName: String, roleName: String, settings: [String : AnyObject], completionHandler: ResultCompletionHandler) {
    let command = "channel/saverole/channel/" + channelName.urlEncode() + "/name/" + roleName.urlEncode()
    
    var parameters: String?
    do {
      let data = try NSJSONSerialization.dataWithJSONObject(settings, options: NSJSONWritingOptions(rawValue: 0))
      if let dataString = String(data: data, encoding: NSUTF8StringEncoding) {
        parameters = "settings=" + dataString
      }
    } catch {
      
    }
    
    callAPI(command, httpMethod: .POST, parameters: parameters, completionHandler: completionHandler)
  }
  
  /**
   Deletes channel role.
   
   - parameter channelName:       channel name.
   - parameter roles:             role names to delete.
   - parameter completionHandler: completion handler indicating success, response and error.
   */
  public func deleteChannelRole(channelName: String, roles: [String], completionHandler: ResultCompletionHandler) {
    let command = "channel/deleterole/channel/" + channelName.urlEncode()
    
    let parameters = "roles[]=".implode("&roles[]=", pieces: roles)
    
    callAPI(command, httpMethod: .POST, parameters: parameters, completionHandler: completionHandler)
  }
  
  /**
   Adds users to role in channel.
   
   - parameter channelName:       channel name.
   - parameter roleName:          role name.
   - parameter users:             usernames to add to role in channel.
   - parameter completionHandler: completion handler indicating success, response and error.
   */
  public func addToChannelRole(channelName: String, roleName: String, users: [String], completionHandler: ResultCompletionHandler) {
    let command = "channel/addtorole/channel/" + channelName.urlEncode() + "/name/" + roleName.urlEncode()
    
    let parameters = "login[]=".implode("&login[]=", pieces: users)
    
    callAPI(command, httpMethod: .POST, parameters: parameters, completionHandler: completionHandler)
  }
  
  // MARK: Private Methods
  
  private func callAPI(command: String, httpMethod: HTTPMethod, parameters: String?=nil, completionHandler: ResultCompletionHandler) {
    let session = NSURLSession.sharedSession()
    
    guard let host = host else {
      return
    }
    
    var urlString = host + "/" + command

    if let sessionId = sessionId {
      urlString += "?sid=" + sessionId
    }
    
    lastURL = urlString
    
    guard let nsURL = NSURL(string: urlString) else {
      dispatch_async(dispatch_get_main_queue(), { 
        completionHandler(false, nil, NSError.unknownError())
      })
      return
    }
    
    let request = NSMutableURLRequest(URL: nsURL)
    request.HTTPMethod = httpMethod.rawValue
    
    if let parameters = parameters {
      request.setBodyContentFromString(parameters)
    }
    
    session.dataTaskWithRequest(request) { (data, response, error) -> Void in
      if error == nil {
        guard let data = data else {
          dispatch_async(dispatch_get_main_queue(), { 
            completionHandler(false, nil, NSError.unknownError())
          })
          return
        }
        
        var responseDictionary: [String : AnyObject]?
        do {
          responseDictionary = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions(rawValue: 0)) as? [String : AnyObject]
        } catch let error as NSError {
          dispatch_async(dispatch_get_main_queue(), { 
            completionHandler(false, nil, error)
          })
          return
        }
        
        guard let unwrappedResponseDictionary = responseDictionary else {
          dispatch_async(dispatch_get_main_queue(), {
            completionHandler(false, nil, NSError.unknownError())
          })
          return
        }
        
        guard let statusCode = unwrappedResponseDictionary["code"] as? String else {
          dispatch_async(dispatch_get_main_queue(), {
            completionHandler(false, unwrappedResponseDictionary, NSError.unknownError())
          })
          return
        }
        
        let success = statusCode == "200"
        dispatch_async(dispatch_get_main_queue(), { 
          completionHandler(success, unwrappedResponseDictionary, nil)
        })
        return
      } else {
        dispatch_async(dispatch_get_main_queue(), { 
          completionHandler(false, nil, NSError.unknownError())
        })
        return
      }
    }.resume()
  }
  
  private func createURLStringFromDictionary(dictionary: [String : String]) -> String {
    var string = ""
    for (index, key) in dictionary.keys.enumerate() {
      if index == 0 {
        string += key + "=" + dictionary[key]!.urlEncode()
      } else {
        string += "&" + key + "=" + dictionary[key]!.urlEncode()
      }
    }
    
    return string
  }

}

// MARK: Helpers

/**
 Represents the different HTTP methods that can be used when making requests to the Zello Server API.
 */
private enum HTTPMethod: String {
  
  case POST = "POST"
  case GET = "GET"
  
}

private enum ZelloAPIErrorDomain: String {
  
  case UnknownError = "ZELLOUnknownError"

}

private extension NSError {
  
  static func unknownError() -> NSError {
    return NSError(domain: ZelloAPIErrorDomain.UnknownError.rawValue, code: 0, userInfo: nil)
  }
  
}

private extension String {
  
  /// Calculates the MD5 hash of a string.
  func MD5() -> String {
    guard let str = cStringUsingEncoding(NSUTF8StringEncoding) else {
      return ""
    }
    
    let strLen = CC_LONG(lengthOfBytesUsingEncoding(NSUTF8StringEncoding))
    let digestLen = Int(CC_MD5_DIGEST_LENGTH)
    let result = UnsafeMutablePointer<CUnsignedChar>.alloc(digestLen)
    
    CC_MD5(str, strLen, result)
    
    let hash = NSMutableString()
    for i in 0..<digestLen {
      hash.appendFormat("%02x", result[i])
    }
    
    result.dealloc(digestLen)
    
    return String(format: hash as String)
  }
  
  /// URL encodes a string.
  func urlEncode() -> String {
    if let string = stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.alphanumericCharacterSet()) {
      return string
    }
    
    return self
  }

  /**
   Join array elements with a glue string. URL encodes all pieces.
   */
  func implode(glue: String, pieces: [String]) -> String {
    var string = self
    
    for (index, piece) in pieces.enumerate() {
      string += piece.urlEncode()
      
      if (index < pieces.count - 1) {
        string += glue
      }
    }
    
    return string
  }
  
}

private extension NSMutableURLRequest {
  
  /**
   Sets the HTTPBody of the NSMutableURLRequest to the contents of a string.
   
   - parameter string: string to encode into HTTPBody.
   */
  func setBodyContentFromString(string: String) {
    HTTPBody = string.dataUsingEncoding(NSUTF8StringEncoding)
    
    addValue("application/x-www-form-urlencoded; charset=utf-8", forHTTPHeaderField: "Content-Type")
  }
  
}
