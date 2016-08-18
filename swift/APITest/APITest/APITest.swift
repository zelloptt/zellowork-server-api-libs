//
//  Copyright © 2016 Zello. All rights reserved.
//

import Foundation

public class APITest {
  
  var api: ZelloAPI!
  
  public convenience init(host: String, apiKey: String, username: String, password: String) {
    self.init()
    
    api = ZelloAPI(host: host, apiKey: apiKey)
    authenticate(username, password: password)
  }
  
  private func authenticate(username: String, password: String) {
    api.authenticate(username, password: password) { [weak self] (success, response, error) in
      print("authenticate: " + String(success))

      if success {
        self?.startTesting()
      } else {
        print("Input the correct credentials for your network in ViewController.swift")
      }
    }
  }
  
  private func startTesting() {
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
  
  private func continueTesting() {
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
          channelRoleDictionary["listen_only"] = false
          channelRoleDictionary["no_disconnect"] = true
          channelRoleDictionary["allow_alerts"] = false
          var toArray = []
          channelRoleDictionary["to"] = toArray
          
          self?.api.saveChannelRole("Test channel", roleName: "Dispatcher", settings: channelRoleDictionary, completionHandler: { (success, response, error) in
            print("saveChannelRole: " + String(success))

            channelRoleDictionary = [String : AnyObject]()
            channelRoleDictionary["listen_only"] = true
            channelRoleDictionary["no_disconnect"] = false
            channelRoleDictionary["allow_alerts"] = true
            toArray = ["Dispatcher"]
            channelRoleDictionary["to"] = toArray
            
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
  
  private func cleanUp() {
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
}
