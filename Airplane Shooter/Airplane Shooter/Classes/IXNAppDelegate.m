//
//  IXNAppDelegate.m
//  Airplane Shooter
//
//  Created by Ikhsan Assaat on 1/11/14.
//  Copyright (c) 2014 Ikhsan Assaat. All rights reserved.
//

#import "IXNAppDelegate.h"
#import "IXNViewController.h"

@implementation IXNAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    // Override point for customization after application launch.
    IXNViewController *vc = [[IXNViewController alloc] init];
    [self.window setRootViewController:vc];
    [self.window makeKeyAndVisible];
    return YES;
}



@end
