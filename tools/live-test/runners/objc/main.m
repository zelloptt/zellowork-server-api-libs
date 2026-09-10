#import <Foundation/Foundation.h>
#import "ZelloAPI.h"

static void emit(NSString *scenario, BOOL ok, NSString *error) {
  NSMutableDictionary *obj = [@{
    @"lang": @"objc",
    @"scenario": scenario,
    @"ok": @(ok)
  } mutableCopy];
  if (error.length > 0) {
    obj[@"error"] = error;
  }
  NSData *data = [NSJSONSerialization dataWithJSONObject:obj options:0 error:nil];
  NSString *line = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
  printf("%s\n", line.UTF8String);
}

static void waitFor(void (^block)(void (^done)(void))) {
  __block BOOL finished = NO;
  block(^{
    finished = YES;
    CFRunLoopStop(CFRunLoopGetMain());
  });
  NSDate *deadline = [NSDate dateWithTimeIntervalSinceNow:60];
  while (!finished && [[NSDate date] compare:deadline] == NSOrderedAscending) {
    [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.05]];
  }
}

static NSString *env(NSString *key) {
  const char *v = getenv(key.UTF8String);
  if (!v || !*v) return nil;
  return [NSString stringWithUTF8String:v];
}

int main(int argc, const char * argv[]) {
  @autoreleasepool {
    NSString *host = env(@"ZW_HOST");
    NSString *username = env(@"ZW_USERNAME");
    NSString *apiKeyEnv = env(@"ZW_API_KEY");
    NSString *passwordEnv = env(@"ZW_PASSWORD");
    NSString *scenarioPath = env(@"ZW_SCENARIO");

    if (!host || !username || !apiKeyEnv || !passwordEnv || !scenarioPath) {
      emit(@"unknown", NO, @"missing ZW_HOST, ZW_USERNAME, ZW_API_KEY, ZW_PASSWORD, or ZW_SCENARIO");
      return 1;
    }

    NSData *data = [NSData dataWithContentsOfFile:scenarioPath];
    NSDictionary *scenario = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    if (![scenario isKindOfClass:[NSDictionary class]]) {
      emit(@"unknown", NO, @"failed to parse scenario JSON");
      return 1;
    }

    NSString *scenarioId = scenario[@"id"] ?: [[scenarioPath lastPathComponent] stringByDeletingPathExtension];
    BOOL expectSuccess = scenario[@"expect_success"] ? [scenario[@"expect_success"] boolValue] : YES;
    NSArray *steps = scenario[@"steps"];

    ZelloAPI *api = nil;
    BOOL stepsOk = YES;
    NSString *error = nil;

    for (NSDictionary *step in steps) {
      NSString *op = step[@"op"];
      if ([op isEqualToString:@"authenticate"]) {
        NSString *key = step[@"api_key"] ?: apiKeyEnv;
        NSString *pass = step[@"password"] ?: passwordEnv;
        BOOL legacy = [step[@"legacy_auth"] boolValue];
        api = [[ZelloAPI alloc] initWithHost:host apiKey:key];
        api.useLegacyAuth = legacy;

        __block BOOL authOk = NO;
        __block NSString *authErr = nil;
        waitFor(^(void (^done)(void)) {
          [api authenticate:username password:pass completionBlock:^(BOOL success, NSDictionary *response, NSError *err) {
            authOk = success;
            if (!success) {
              authErr = err.localizedDescription ?: [response description] ?: @"authenticate failed";
            }
            done();
          }];
        });
        if (!authOk) {
          stepsOk = NO;
          error = authErr;
          break;
        }
      } else if ([op isEqualToString:@"get_users"]) {
        if (!api) {
          stepsOk = NO;
          error = @"no api";
          break;
        }
        __block BOOL callOk = NO;
        __block NSString *callErr = nil;
        waitFor(^(void (^done)(void)) {
          [api getUsers:nil isGateway:NO max:nil start:nil channel:nil completionBlock:^(BOOL success, NSDictionary *response, NSError *err) {
            callOk = success;
            if (!success) {
              callErr = err.localizedDescription ?: [response description];
            }
            done();
          }];
        });
        if (!callOk) {
          stepsOk = NO;
          error = callErr;
          break;
        }
      } else if ([op isEqualToString:@"logout"]) {
        if (!api) {
          stepsOk = NO;
          error = @"no api";
          break;
        }
        __block BOOL callOk = NO;
        __block NSString *callErr = nil;
        waitFor(^(void (^done)(void)) {
          [api logout:^(BOOL success, NSDictionary *response, NSError *err) {
            callOk = success;
            if (!success) {
              callErr = err.localizedDescription ?: [response description];
            }
            done();
          }];
        });
        if (!callOk) {
          stepsOk = NO;
          error = callErr;
          break;
        }
      } else {
        stepsOk = NO;
        error = [NSString stringWithFormat:@"unknown op: %@", op];
        break;
      }
    }

    BOOL ok = (stepsOk == expectSuccess);
    if (!ok && error == nil) {
      error = expectSuccess ? @"steps failed" : @"expected failure but steps succeeded";
    }
    emit(scenarioId, ok, ok ? nil : error);
    return ok ? 0 : 1;
  }
}
