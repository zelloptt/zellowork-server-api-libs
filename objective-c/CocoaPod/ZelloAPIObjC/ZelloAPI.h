//
//  Copyright © 2016 Zello. All rights reserved.
//

#import <Foundation/Foundation.h>

/// Completion Block for making API Requests that returns a success indicator, result dictionary and error.
/// A value for the error variable represents a client error. This is not the error returned by the API.
/// An error returned by the API can be retrieved through the result dictionary.
/// This block is always executed on the main thread.
typedef void (^ResultCompletionBlock)(BOOL,  NSDictionary * _Nullable , NSError * _Nullable);

/**
 ZelloWork server Objective C API wrapper class.
 
 This class provides an easy way to interact with the ZelloWork server
 from your Objective C code to add, modify and delete users and channels.
 Please note that all text values passed to the API must be in UTF-8 encoding
 and any text data returned are in UTF-8 as well.
 
 - Version 1.1.0
 - Minimum iOS Version 8.0
 */
@interface ZelloAPI : NSObject

#pragma mark Public Variables

/**
 *  API Version
 */
+ (nonnull NSString *)version;

/**
 *  Session ID used to identify logged in client. Typically you'll want to authenticate first and store Session ID to reuse later.
 */
@property(nonatomic, strong, nullable) NSString *sessionId;

/**
 *  Last accessed API URL. Useful for API troubleshooting.
 */
@property(atomic, strong, nullable) NSString *lastURL;

#pragma mark Initializers

- (nonnull id)initWithHost:(nonnull NSString *)host apiKey:(nonnull NSString *)apiKey;
- (nonnull id)initWithHost:(nonnull NSString *)host apiKey:(nonnull NSString *)apiKey sessionId:(nullable NSString *)sessionId;

#pragma mark Public Methods

/**
 API client authentication.
 If authentication fails, use the errorCode and errorDescription attributes on the response dictionary to get error details.
 If authentication succeeds, sessionId is set to the Session ID.
 The Session ID is reusable so it's recommended that you save this value and use it for further API calls.
 Once you are done using the API, call [ZelloAPI logout] to end the session and invalidate Session ID.
 
 - parameter username:        administrative username
 - parameter password:        administrative password
 - parameter completionBlock: completion block indicating success, response and error.
 */
- (void)authenticate:(nonnull NSString *)username password:(nonnull NSString *)password completionBlock:(nonnull ResultCompletionBlock)completionBlock;

/**
 Ends session identified by sessionId.
 Use this method to terminate the API session.
 See [ZelloAPI authenticate]
 
 - parameter completionHandler: completion handler indicating success, response and error.
 */
- (void)logout:(nonnull ResultCompletionBlock)completionBlock;

/**
 Gets the list of the users or detailed information regarding a particular user.
 
 - parameter username:        username of the user, for which the details are requested. If null, the full users list is returned.
 - parameter isGateway:       whether to return users or gateways.
 - parameter max:             maximum number of results to fetch.
 - parameter start:           start index of results to fetch.
 - parameter channel:         channel name.
 - parameter completionBlock: completion block indicating success, response and error.
 */
- (void)getUsers:(nullable NSString *)username isGateway:(BOOL)isGateway max:(nullable NSNumber *)max start:(nullable NSNumber *)start channel:(nullable NSString *)channel completionBlock:(nonnull ResultCompletionBlock)completionBlock;

/**
 Gets the list of the channels or detailed information regarding a particular channel.
 
 - parameter name:            name of the channel, for which the details are requested. If omitted, the full channels list is returned.
 - parameter max:             maximum number of results to fetch.
 - parameter start:           start index of results to fetch.
 - parameter completionBlock: completion block indicating success, response and error.
 */
- (void)getChannels:(nullable NSString *)name max:(nullable NSNumber *)max start:(nullable NSNumber *)start completionBlock:(nonnull ResultCompletionBlock)completionBlock;

/**
 Adds users to a channel.
 
 - parameter channelName:     name of the channel where the users will be added.
 - parameter users:           NSString array of usernames of the users to add.
 - parameter completionBlock: completion block indicating success, response and error.
 */
- (void)addToChannel:(nonnull NSString *)channelName users:(nonnull NSArray *)users completionBlock:(nonnull ResultCompletionBlock)completionBlock;

/**
 Add users to multiple channels.
 
 - parameter channelNames:    NSString array of channel names where the users are added.
 - parameter users:           NSString array of usernames of the users to add.
 - parameter completionBlock: completion handler indicating success, response and error.
 */
- (void)addToChannels:(nonnull NSArray *)channelNames users:(nonnull NSArray *)users completionBlock:(nonnull ResultCompletionBlock)completionBlock;

/**
 Removes users from a channel.
 
 - parameter channelName:     name of the channel.
 - parameter users:           NSString array of usernames of the users to remove from the channel.
 - parameter completionBlock: completion block indicating success, response and error.
 */
- (void)removeFromChannel:(nonnull NSString *)channelName users:(nonnull NSArray *)users completionBlock:(nonnull ResultCompletionBlock)completionBlock;

/**
 Removes users from multiple channels.
 
 - parameter channelNames:    NSString array of names of the channels.
 - parameter users:           NSString array of usernames of the users to remove from channels.
 - parameter completionBlock: completion block indicating success, response and error.
 */
- (void)removeFromChannels:(nonnull NSArray *)channelNames users:(nonnull NSArray *)users completionBlock:(nonnull ResultCompletionBlock)completionBlock;

/**
 Adds or updates the user.
 If username exists, the user is updated. Otherwise, a new user is created.
 When adding a user, the "name" and "password" attributes are required.
 When updating a user, the "name" attribute is required.
 
 See [ZelloAPI deleteUsers]
 
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
 
 - parameter user:            dictionary of user attributes. Key = String, Value = NSObject.
 - parameter completionBlock: completion block indicating success, response and error.
 */
- (void)saveUser:(nonnull NSDictionary *)user completionBlock:(nonnull ResultCompletionBlock)completionBlock;

/**
 Deletes users.
 
 See [ZelloAPI saveUser]
 
 - parameter users:           NSString array of usernames of the users to remove.
 - parameter completionBlock: completion block indicating success, response and error.
 */
- (void)deleteUsers:(nonnull NSArray *)users completionBlock:(nonnull ResultCompletionBlock)completionBlock;

/**
 Adds a new channel.
 
 - parameter name:            channel name.
 - parameter isGroup:         true means it is a group channel. false means it is a dynamic channel.
 - parameter isHidden:        when set to true in combination with isGroup set to true, a hidden group channel is created.
 - parameter completionBlock: completion block indicating success, response and error.
 */
- (void)addChannel:(nonnull NSString *)name isGroup:(BOOL)isGroup isHidden:(BOOL)isHidden completionBlock:(nonnull ResultCompletionBlock)completionBlock;

/**
 Deletes channels.
 
 - parameter channelNames:    NSString array of names of the channels to remove.
 - parameter completionBlock: completion block indicating success, response and error.
 */
- (void)deleteChannels:(nonnull NSArray *)channelNames completionBlock:(nonnull ResultCompletionBlock)completionBlock;

/**
 Get channel roles (simple format).
 
 - parameter channelName:     channel name.
 - parameter completionBlock: completion block indicating success, response and error.
 */
- (void)getChannelsRoles:(nonnull NSString *)channelName completionBlock:(nonnull ResultCompletionBlock)completionBlock;


/**
 Adds or updates channel role.
 
 - parameter channelName:     channel name.
 - parameter roleName:        new role name.
 - parameter settings:        role settings in JSON format: ["listen_only" : false, "no_disconnect" : true, "allow_alerts" : false, "to": ["dispatchers"]]
 - parameter completionBlock: completion block indicating success, response and error.
 */
- (void)saveChannelRole:(nonnull NSString *)channelName roleName:(nonnull NSString *)roleName settings:(nonnull NSDictionary *)settings completionBlock:(nonnull ResultCompletionBlock)completionBlock;

/**
 Deletes channel role.
 
 - parameter channelName:     channel name.
 - parameter roles:           NSString array of role names to delete.
 - parameter completionBlock: completion block indicating success, response and error.
 */
- (void)deleteChannelRole:(nonnull NSString *)channelName roles:(nonnull NSArray *)roles completionBlock:(nonnull ResultCompletionBlock)completionBlock;

/**
 Adds users to role in channel.
 
 - parameter channelName:     channel name.
 - parameter roleName:        role name.
 - parameter users:           NSString array of usernames to add to role in channel.
 - parameter completionBlock: completion block indicating success, response and error.
 */
- (void)addToChannelRole:(nonnull NSString *)channelName roleName:(nonnull NSString *)roleName users:(nonnull NSArray *)users completionBlock:(nonnull ResultCompletionBlock)completionBlock;

@end
