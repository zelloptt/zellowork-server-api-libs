//
//  Copyright © 2016 Zello. All rights reserved.
//

#import "ViewController.h"
#import "APITest.h"

@interface ViewController ()

@property(nonatomic, strong) APITest *apiTest;

@end

@implementation ViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  
  // Input your host url or IP address, your API key, and the administrative username/password combination.
  self.apiTest = [[APITest alloc] initWithHost:@"" apiKey:@"" username:@"" password:@""];
}

@end
