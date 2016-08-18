//
//  Copyright © 2016 Zello. All rights reserved.
//

#import "APITest.h"
#import "ZelloAPI.h"
#import <CommonCrypto/CommonCrypto.h>

@interface APITest ()

@property (nonatomic, strong) ZelloAPI *api;

@end

@implementation APITest

- (id)initWithHost:(NSString *)host apiKey:(NSString *)apiKey username:(NSString *)username password:(NSString *)password {
  self = [super init];
  
  if (self) {
    self.api = [[ZelloAPI alloc] initWithHost:host apiKey:apiKey];
    [self authenticate:username password:password];
  }
  
  return self;
}

- (void)authenticate:(NSString *)username password:(NSString *)password {
  __weak typeof(self) weakSelf = self;
  [self.api authenticate:username password:password completionBlock:^(BOOL success, NSDictionary *response, NSError *error) {
    NSLog(@"authenticate: %i", success);
    
    if (success) {
      [weakSelf startTesting];
    } else {
      NSLog(@"Input the correct credentials for your network in ViewController.m");
    }
  }];
}

- (void)startTesting {
  __weak typeof(self) weakSelf = self;
  [self.api getUsers:NULL isGateway:NO max:NULL start:NULL channel:NULL completionBlock:^(BOOL success, NSDictionary *response, NSError *error) {
    NSLog(@"getUsers: %i", success);
    if (success) {
      NSLog(@"%@", response);
    }
    
    [weakSelf.api getChannels:NULL max:NULL start:NULL completionBlock:^(BOOL success, NSDictionary *response, NSError *error) {
      NSLog(@"getChannels: %i", success);
      if (success) {
        NSLog(@"%@", response);
      }
      
      // Add or update user
      NSMutableDictionary *userDictionary = [[NSMutableDictionary alloc] init];
      [userDictionary setValue:@"zelloapi_test" forKeyPath:@"name"];
      [userDictionary setValue:[self MD5:@"test"] forKey:@"password"];
      [userDictionary setValue:@"support@zello.com" forKey:@"email"];
      [userDictionary setValue:@"API Test 'На здоровье'" forKey:@"full_name"]; // UTF-8 is fully supported
      [weakSelf.api saveUser:userDictionary completionBlock:^(BOOL success, NSDictionary *response, NSError *error) {
        NSLog(@"saveUser: %i", success);
        
        // List users again -- look the new user is there
        [weakSelf.api getUsers:NULL isGateway:NO max:NULL start:NULL channel:NULL completionBlock:^(BOOL success, NSDictionary *response, NSError *error) {
          NSLog(@"getUsers: %i", success);
          if (success) {
            NSLog(@"%@", response);
          }
          
          [weakSelf continueTesting];
        }];
      }];
    }];
  }];
}

- (void)continueTesting {
  __weak typeof(self) weakSelf = self;
  // Add channel
  [self.api addChannel:@"Test channel" isGroup:NULL isHidden:NULL completionBlock:^(BOOL success, NSDictionary *response, NSError *error) {
    NSLog(@"addChannel: %i", success);

    // Add user to a channel
    NSMutableArray *users = [[NSMutableArray alloc] init];
    [users addObject:@"zelloapi_test"];
    [weakSelf.api addToChannel:@"Test channel" users:users completionBlock:^(BOOL success, NSDictionary *response, NSError *error) {
      NSLog(@"addToChannel: %i", success);

      // List channels again
      [weakSelf.api getChannels:NULL max:NULL start:NULL completionBlock:^(BOOL success, NSDictionary *response, NSError *error) {
        NSLog(@"getChannels: %i", success);
        if (success) {
          NSLog(@"%@", response);
        }
        
        // Create channel role

        NSMutableDictionary *channelRoleDictionary = [[NSMutableDictionary alloc] init];
        [channelRoleDictionary setValue:@(NO) forKeyPath:@"listen_only"];
        [channelRoleDictionary setValue:@(YES) forKey:@"no_disconnect"];
        [channelRoleDictionary setValue:@(NO) forKey:@"allow_alerts"];
        NSArray *toArray = [[NSArray alloc] init];
        [channelRoleDictionary setValue:toArray forKey:@"to"];
        [weakSelf.api saveChannelRole:@"Test channel" roleName:@"Dispatcher" settings:channelRoleDictionary completionBlock:^(BOOL sucess, NSDictionary *response, NSError *error) {
          NSLog(@"saveChannelRole: %i", success);

          NSMutableDictionary *channelRoleDictionary = [[NSMutableDictionary alloc] init];
          [channelRoleDictionary setValue:@(YES) forKeyPath:@"listen_only"];
          [channelRoleDictionary setValue:@(NO) forKey:@"no_disconnect"];
          [channelRoleDictionary setValue:@(YES) forKey:@"allow_alerts"];
          NSArray *toArray = [[NSArray alloc] initWithObjects:@"Dispatcher", nil];
          [channelRoleDictionary setValue:toArray forKey:@"to"];
          [weakSelf.api saveChannelRole:@"Test channel" roleName:@"Driver" settings:channelRoleDictionary completionBlock:^(BOOL success, NSDictionary *response, NSError *error) {
            NSLog(@"saveChannelRole: %i", success);

            // List channel roles
            [weakSelf.api getChannelsRoles:@"Test channel" completionBlock:^(BOOL success, NSDictionary *response, NSError *error) {
              NSLog(@"getChannelsRoles: %i", success);
              if (success) {
                NSLog(@"%@", response);
              }
              
              [weakSelf cleanUp];
            }];
          }];
        }];
      }];
    }];
  }];
}

- (void)cleanUp {
  __weak typeof(self) weakSelf = self;
  // Remove the channel
  NSArray *channelNames = [[NSArray alloc] initWithObjects:@"Test channel", nil];
  [self.api deleteChannels:channelNames completionBlock:^(BOOL success, NSDictionary *response, NSError *error) {
    NSLog(@"deleteChannels: %i", success);

    // Delete the user we just added
    NSArray *users = [[NSArray alloc] initWithObjects:@"zelloapi_test", nil];
    [weakSelf.api deleteUsers:users completionBlock:^(BOOL success, NSDictionary *response, NSError *error) {
      NSLog(@"deleteUsers: %i", success);

      // List users one last time -- the new user is gone
      [weakSelf.api getUsers:NULL isGateway:NO max:NULL start:NULL channel:NULL completionBlock:^(BOOL success, NSDictionary *response, NSError *error) {
        NSLog(@"getUsers: %i", success);
        if (success) {
          NSLog(@"%@", response);
        }
      }];
    }];
  }];
}

- (NSString *)MD5:(NSString *)string {
  const char *pointer = [string UTF8String];
  unsigned char md5Buffer[CC_MD5_DIGEST_LENGTH];
  
  CC_MD5(pointer, (CC_LONG)strlen(pointer), md5Buffer);
  
  NSMutableString *returnString = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
  for (int i = 0; i < CC_MD5_DIGEST_LENGTH; i++) {
    [returnString appendFormat:@"%02x",md5Buffer[i]];
  }
  
  return returnString;
}

@end
