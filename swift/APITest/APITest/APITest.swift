//
//  Copyright © 2016 Zello. All rights reserved.
//

import Foundation

open class APITest {
  
  var api: ZelloAPI!
  
  public convenience init(host: String, apiKey: String, username: String, password: String) {
    self.init()
    
    api = ZelloAPI(host: host, apiKey: apiKey)
    authenticate(username, password: password)
  }
  
  fileprivate func authenticate(_ username: String, password: String) {
    api.authenticate(username, password: password) { [weak self] (success, response, error) in
      print("authenticate: " + String(success))

      if success {
        self?.startTesting()
      } else {
        print("Input the correct credentials for your network in ViewController.swift")
      }
    }
  }
  
  fileprivate func startTesting() {
    api.getUsers { [weak self] (success, response, error) in
      print("getUsers: " + String(success))

      self?.api.getChannels(completionHandler: { (success, response, error) in
        print("getChannels: " + String(success))
        if success {
          print(response)
        }
        
        // Add or update user
        var userDictionary = [String : String]()
        userDictionary["name"] = "zelloapi_test"
        userDictionary["password"] = "test".MD5()
        userDictionary["email"] = "support@zello.com"
        userDictionary["full_name"] = "API Test 'На здоровье'" // UTF-8 is fully supported
        self?.api.saveUser(userDictionary, completionHandler: { (success, response, error) in
          print("saveUser: " + String(success))

          // List users again -- look the new user is there
          self?.api.getUsers(completionHandler: { (success, response, error) in
            print("getUsers: " + String(success))

            if success {
              print(response)
            }
            
            self?.continueTesting()
          })
        })
      })
    }
  }
  
  fileprivate func continueTesting() {
    // Add channel
    api.addChannel("Test channel") { [weak self] (success, response, error) in
      print("addChannel: " + String(success))

      // Add user to a channel
      let users = ["zelloapi_test"]
      self?.api.addToChannel("Test channel", users: users, completionHandler: { (success, response, error) in
        print("addToChannel: " + String(success))

        // List channels again
        self?.api.getChannels(completionHandler: { (success, response, error) in
          print("getChannels: " + String(success))

          if success {
            print(response)
          }
          
          // Create channel role
          
          var channelRoleDictionary = [String : AnyObject]()
          channelRoleDictionary["listen_only"] = false as AnyObject?
          channelRoleDictionary["no_disconnect"] = true as AnyObject?
          channelRoleDictionary["allow_alerts"] = false as AnyObject?
          var toArray: [AnyObject] = []
          channelRoleDictionary["to"] = toArray as AnyObject?
          
          self?.api.saveChannelRole("Test channel", roleName: "Dispatcher", settings: channelRoleDictionary, completionHandler: { (success, response, error) in
            print("saveChannelRole: " + String(success))

            channelRoleDictionary = [String : AnyObject]()
            channelRoleDictionary["listen_only"] = false as AnyObject?
            channelRoleDictionary["no_disconnect"] = false as AnyObject?
            channelRoleDictionary["allow_alerts"] = true as AnyObject?
            toArray = ["Dispatcher" as AnyObject]
            channelRoleDictionary["to"] = toArray as AnyObject?
            
            self?.api.saveChannelRole("Test channel", roleName: "Driver", settings: channelRoleDictionary, completionHandler: { (success, response, error) in
              print("saveChannelRole: " + String(success))

              // List channel roles
              self?.api.getChannelsRoles("Test channel", completionHandler: { (success, response, error) in
                print("getChannelsRoles: " + String(success))

                if success {
                  print(response)
                }
                
                self?.cleanUp()
              })
            })
          })
        })
      })
    }
  }
  
  fileprivate func cleanUp() {
    // Remove the channel
    let channelNames = ["Test channel"]
    api.deleteChannels(channelNames) { [weak self] (success, response, error) in
      print("deleteChannels: " + String(success))

      // Delete the user we just added
      let users = ["zelloapi_test"]
      self?.api.deleteUsers(users, completionHandler: { (success, response, error) in
        print("deleteUsers: " + String(success))

        // List users one last time -- the new user is gone
        self?.api.getUsers(completionHandler: { (success, response, error) in
          print("getUsers: " + String(success))

          if success{
            print(response)
          }
        })
      })
    }
  }
  
}

private extension String {
  
  /// Calculates the MD5 hash of a string.
  func MD5() -> String {
    guard let str = cString(using: String.Encoding.utf8) else {
      return ""
    }
    
    let strLen = CC_LONG(lengthOfBytes(using: String.Encoding.utf8))
    let digestLen = Int(CC_MD5_DIGEST_LENGTH)
    let result = UnsafeMutablePointer<CUnsignedChar>.allocate(capacity: digestLen)
    
    CC_MD5(str, strLen, result)
    
    let hash = NSMutableString()
    for i in 0..<digestLen {
      hash.appendFormat("%02x", result[i])
    }
    
    result.deallocate(capacity: digestLen)
    
    return String(format: hash as String)
  }
}
