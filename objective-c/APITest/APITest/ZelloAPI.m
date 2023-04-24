//
//  Copyright © 2016 Zello. All rights reserved.
//

#import "ZelloAPI.h"
#import <CommonCrypto/CommonCrypto.h>

/**
 Represents the different HTTP methods that can be used when making requests to the Zello Server API.
 */
typedef NS_ENUM(NSInteger, HTTPMethod) {
  HTTPMethodGET,
  HTTPMethodPOST
};

@interface ZelloAPI ()

@property (nonatomic, strong) NSString *host;
@property (nonatomic, strong) NSString *apiKey;

@end
  
@implementation ZelloAPI

static NSString *version = @"1.1.0";

#pragma mark Version

+ (NSString *)version {
  return version;
}

#pragma mark Initializer

- (id)initWithHost:(NSString *)host apiKey:(NSString *)apiKey {
  return [self initWithHost:host apiKey:apiKey sessionId:NULL];
}

- (id)initWithHost:(NSString *)host apiKey:(NSString *)apiKey sessionId:(NSString *)sessionId {
  self = [super init];
  
  if (self) {
    self.host = host;
    self.apiKey = apiKey;
    self.sessionId = sessionId;
  }
  
  return self;
}

#pragma mark Public Methods

- (void)authenticate:(NSString *)username password:(NSString *)password completionBlock:(ResultCompletionBlock)completionBlock {
  __weak typeof(self) weakSelf = self;
  
  [self callAPI:@"user/gettoken" httpMethod:HTTPMethodGET parameters:nil completionBlock:^(BOOL success, NSDictionary * _Nullable response, NSError * _Nullable error) {
    // On main thread
    if (!weakSelf) {
      completionBlock(NO, response, error);
      return;
    }
    
    if (!success) {
      completionBlock(success, response, error);
      return;
    }
    
    if (!response) {
      completionBlock(NO, response, error);
      return;
    }
    
    NSString *token = [response valueForKey:@"token"];
    
    if (!token) {
      completionBlock(NO, response, error);
      return;
    }
    
    weakSelf.sessionId = [response valueForKey:@"sid"];
    
    if (!weakSelf.apiKey) {
      completionBlock(NO, response, error);
      return;
    }
    
    NSString *hashedPassword = [weakSelf MD5:[[[weakSelf MD5:password] stringByAppendingString:token] stringByAppendingString:weakSelf.apiKey]];
    NSString *parameters = [[[@"username=" stringByAppendingString:username] stringByAppendingString:@"&password="] stringByAppendingString:hashedPassword];
    
    [weakSelf callAPI:@"user/login" httpMethod:HTTPMethodPOST parameters:parameters completionBlock:completionBlock];
  }];
}

- (void)logout:(ResultCompletionBlock)completionBlock {
  __weak typeof(self) weakSelf = self;
  [self callAPI:@"user/logout" httpMethod:HTTPMethodGET parameters:NULL completionBlock:^(BOOL success, NSDictionary * _Nullable response, NSError * _Nullable error) {
    weakSelf.sessionId = NULL;
    
    completionBlock(success, response, error);
  }];
}

- (void)getUsers:(NSString *)username isGateway:(BOOL)isGateway max:(NSNumber *)max start:(NSNumber *)start channel:(NSString *)channel completionBlock:(ResultCompletionBlock)completionBlock {
  NSString *command = @"user/get";
  
  if (username) {
    command = [[command stringByAppendingString:@"/login/"] stringByAppendingString:[self urlEncode:username]];
  }
  if (channel) {
    command = [[command stringByAppendingString:@"/channel/"] stringByAppendingString:[self urlEncode:channel]];
  }
  if (isGateway) {
    command = [command stringByAppendingString:@"/gateway/1"];
  }
  if (max) {
    command = [[command stringByAppendingString:@"/max/"] stringByAppendingString:[max stringValue]];
  }
  if (start) {
    command = [[command stringByAppendingString:@"/start/"] stringByAppendingString:[start stringValue]];
  }
  
  [self callAPI:command httpMethod:HTTPMethodGET parameters:NULL completionBlock:completionBlock];
}

- (void)getChannels:(NSString *)name max:(NSNumber *)max start:(NSNumber *)start completionBlock:(ResultCompletionBlock)completionBlock {
  NSString *command = @"channel/get";
  
  if (name) {
    command = [[command stringByAppendingString:@"/name/"] stringByAppendingString:[self urlEncode:name]];
  }
  if (max) {
    command = [[command stringByAppendingString:@"/max/"] stringByAppendingString:[max stringValue]];
  }
  if (max) {
    command = [[command stringByAppendingString:@"/start/"] stringByAppendingString:[start stringValue]];
  }
  
  [self callAPI:command httpMethod:HTTPMethodGET parameters:NULL completionBlock:completionBlock];
}

- (void)addToChannel:(NSString *)channelName users:(NSArray *)users completionBlock:(ResultCompletionBlock)completionBlock {
  NSString *command = [@"user/addto/" stringByAppendingString:[self urlEncode:channelName]];
  
  NSString *parameters = [self implode:@"login[]=" glue:@"&login[]=" pieces:users];
  
  [self callAPI:command httpMethod:HTTPMethodPOST parameters:parameters completionBlock:completionBlock];
}

- (void)addToChannels:(NSArray *)channelNames users:(NSArray *)users completionBlock:(ResultCompletionBlock)completionBlock {
  NSString *command = @"user/addtochannels";
  
  NSString *parameters = [self implode:@"users[]=" glue:@"&users[]=" pieces:users];
  parameters = [parameters stringByAppendingString:[self implode:@"&channels[]=" glue:@"&channels[]=" pieces:channelNames]];
  
  [self callAPI:command httpMethod:HTTPMethodPOST parameters:parameters completionBlock:completionBlock];
}

- (void)removeFromChannel:(NSString *)channelName users:(NSArray *)users completionBlock:(ResultCompletionBlock)completionBlock {
  NSString *command = [@"user/removefrom/" stringByAppendingString:[self urlEncode:channelName]];
  
  NSString *parameters = [self implode:@"login[]=" glue:@"&login[]=" pieces:users];
  
  [self callAPI:command httpMethod:HTTPMethodPOST parameters:parameters completionBlock:completionBlock];
}

- (void)removeFromChannels:(NSArray *)channelNames users:(NSArray *)users completionBlock:(ResultCompletionBlock)completionBlock {
  NSString *command = @"user/removefromchannels";
  
  NSString *parameters = [self implode:@"users[]=" glue:@"&users[]=" pieces:users];
  parameters = [parameters stringByAppendingString: [self implode:@"&channels[]=" glue:@"&channels[]=" pieces:channelNames]];
  
  [self callAPI:command httpMethod:HTTPMethodPOST parameters:parameters completionBlock:completionBlock];
}

- (void)saveUser:(NSDictionary *)user completionBlock:(ResultCompletionBlock)completionBlock {
  NSString *command = @"user/save";
  
  NSString *parameters = [self createURLStringFromDictionary:user];
  
  [self callAPI:command httpMethod:HTTPMethodPOST parameters:parameters completionBlock:completionBlock];
}

- (void)deleteUsers:(NSArray *)users completionBlock:(ResultCompletionBlock)completionBlock {
  NSString *command = @"user/delete";
  
  NSString *parameters = [self implode:@"login[]=" glue:@"&login[]=" pieces:users];
  
  [self callAPI:command httpMethod:HTTPMethodPOST parameters:parameters completionBlock:completionBlock];
}

- (void)addChannel:(NSString *)name isGroup:(BOOL)isGroup isHidden:(BOOL)isHidden completionBlock:(ResultCompletionBlock)completionBlock {
  NSString *command = [@"channel/add/name/" stringByAppendingString:[self urlEncode:name]];
  
  if (isGroup) {
    command = [[command stringByAppendingString:@"/shared/"] stringByAppendingString:@"true"];
  }
  if (isHidden) {
    command = [[command stringByAppendingString:@"/invisible/"] stringByAppendingString:@"true"];
  }
  
  [self callAPI:command httpMethod:HTTPMethodGET parameters:NULL completionBlock:completionBlock];
}

- (void)deleteChannels:(NSArray *)channelNames completionBlock:(ResultCompletionBlock)completionBlock {
  NSString *command = @"channel/delete";
  
  NSString *parameters = [self implode:@"name[]=" glue:@"&name[]=" pieces:channelNames];
  
  [self callAPI:command httpMethod:HTTPMethodPOST parameters:parameters completionBlock:completionBlock];
}

- (void)getChannelsRoles:(NSString *)channelName completionBlock:(ResultCompletionBlock)completionBlock {
  NSString *command = [@"channel/roleslist/name/" stringByAppendingString:[self urlEncode:channelName]];
  
  [self callAPI:command httpMethod:HTTPMethodGET parameters:NULL completionBlock:completionBlock];
}

- (void)saveChannelRole:(NSString *)channelName roleName:(NSString *)roleName settings:(NSDictionary *)settings completionBlock:(ResultCompletionBlock)completionBlock {
  NSString *command = [[[@"channel/saverole/channel/" stringByAppendingString:[self urlEncode:channelName]] stringByAppendingString:@"/name/"] stringByAppendingString:[self urlEncode:roleName]];
  
  NSString *parameters;
  
  NSError *error;
  NSData *data = [NSJSONSerialization dataWithJSONObject:settings options:kNilOptions error:&error];
  
  NSString *dataString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
  if (dataString) {
    parameters = [@"settings=" stringByAppendingString:dataString];
  }
  
  [self callAPI:command httpMethod:HTTPMethodPOST parameters:parameters completionBlock:completionBlock];
}

- (void)deleteChannelRole:(NSString *)channelName roles:(NSArray *)roles completionBlock:(ResultCompletionBlock)completionBlock {
  NSString *command = [@"channel/deleterole/channel/" stringByAppendingString:[self urlEncode:channelName]];
  
  NSString *parameters = [self implode:@"roles[]=" glue:@"&roles[]=" pieces:roles];
  
  [self callAPI:command httpMethod:HTTPMethodPOST parameters:parameters completionBlock:completionBlock];
}

- (void)addToChannelRole:(NSString *)channelName roleName:(NSString *)roleName users:(NSArray *)users completionBlock:(ResultCompletionBlock)completionBlock {
  NSString *command = [[[@"channel/addtorole/channel/" stringByAppendingString:[self urlEncode:channelName]] stringByAppendingString:@"/name/"] stringByAppendingString:[self urlEncode:roleName]];
  
  NSString *parameters = [self implode:@"login[]=" glue:@"&login[]=" pieces:users];
  
  [self callAPI:command httpMethod:HTTPMethodPOST parameters:parameters completionBlock:completionBlock];
}

#pragma mark Private Methods

- (void)callAPI:(NSString *)command httpMethod:(HTTPMethod)method parameters:(NSString *)parameters completionBlock:(ResultCompletionBlock)completionBlock {
  NSURLSession *session = [NSURLSession sharedSession];
  
  __weak typeof(self) weakSelf = self;

  if (!self.host) {
    dispatch_async(dispatch_get_main_queue(), ^{
      completionBlock(NO, NULL, [weakSelf unknownError]);
    });
    return;
  }
  
  NSString *prefix = @"http://";
  if ([self.host containsString:@"http://"] || [self.host containsString:@"https://"]) {
    prefix = @"";
  }
  
  NSString *urlString = [prefix stringByAppendingString:[[self.host stringByAppendingString:@"/"] stringByAppendingString:command]];
  
  if (self.sessionId) {
    urlString = [[urlString stringByAppendingString:@"?sid="] stringByAppendingString:_sessionId];
  }
  
  self.lastURL = urlString;
  
  NSURL *url = [[NSURL alloc] initWithString:urlString];
  
  if (!url) {
    dispatch_async(dispatch_get_main_queue(), ^{
      completionBlock(NO, NULL, [weakSelf unknownError]);
    });
    return;
  }
  
  NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
  request.HTTPMethod = [self convertToString:method];
  
  if (parameters) {
    request.HTTPBody = [parameters dataUsingEncoding:NSUTF8StringEncoding];
    
    [request addValue:@"application/x-www-form-urlencoded; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
  }
  
  [[session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
    if (!error) {
      if (!data) {
        dispatch_async(dispatch_get_main_queue(), ^{
          completionBlock(NO, NULL, [weakSelf unknownError]);
        });
        return;
      }
      
      NSError *error;
      NSDictionary *responseDictionary = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
      
      if (error) {
        dispatch_async(dispatch_get_main_queue(), ^{
          completionBlock(NO, NULL, error);
        });
        return;
      }
      
      if (responseDictionary) {
        NSString *statusCode = [responseDictionary valueForKey:@"code"];
        if (statusCode) {
          // Happy path
          BOOL success = [statusCode isEqualToString:@"200"];
          dispatch_async(dispatch_get_main_queue(), ^{
            completionBlock(success, responseDictionary, NULL);
          });
          return;
        } else {
          dispatch_async(dispatch_get_main_queue(), ^{
            completionBlock(NO, NULL, [weakSelf unknownError]);
          });
          return;
        }
      } else {
        dispatch_async(dispatch_get_main_queue(), ^{
          completionBlock(NO, NULL, [weakSelf unknownError]);
        });
        return;
      }
    } else {
      dispatch_async(dispatch_get_main_queue(), ^{
        completionBlock(NO, NULL, error);
      });
      return;
    }
  }] resume];
}

/**
 *  Converts HTTPMethod to NSString.
 *
 *  @param method method to convert.
 *
 *  @return NSString representation of method.
 */
- (NSString *)convertToString:(HTTPMethod)method {
  NSString *result = nil;
  
  switch(method) {
    case HTTPMethodGET:
      result = @"GET";
      break;
    case HTTPMethodPOST:
      result = @"POST";
      break;
  }
  
  return result;
}

/**
 Calculates the MD5 hash of a string.
 */
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

/**
 URL encodes a string.
 */
- (NSString *)urlEncode:(NSString *)string {
  NSString *returnString = [string stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet alphanumericCharacterSet]];
  
  return returnString ? returnString : string;
}

/**
 Join array elements with a glue string. URL encodes all pieces.
 */
- (NSString *)implode:(NSString *)baseString glue:(NSString *)glue pieces:(NSArray *)pieces {
  for (int i = 0; i < pieces.count; i++) {
    baseString = [baseString stringByAppendingString:[self urlEncode:pieces[i]]];
    
    if (i < pieces.count - 1) {
      baseString = [baseString stringByAppendingString:glue];
    }
  }
  
  return baseString;
}

- (NSError *)unknownError {
  return [[NSError alloc] initWithDomain:@"ZELLOUnknownError" code:0 userInfo:nil];
}

- (NSString *)createURLStringFromDictionary:(NSDictionary *)dictionary {
  NSString *string = @"";
  for (int i = 0; i < dictionary.allKeys.count; i++) {
    NSString *key = dictionary.allKeys[i];
    NSString *value = [dictionary valueForKey:key];
    
    if (i == 0) {
      string = [[[string stringByAppendingString:key] stringByAppendingString:@"="] stringByAppendingString:[self urlEncode:value]];
    } else {
      string = [[[[string stringByAppendingString:@"&"] stringByAppendingString:key] stringByAppendingString:@"="] stringByAppendingString:[self urlEncode:value]];
    }
  }
  
  return string;
}

@end
