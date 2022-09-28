//
//  AppDelegate.m
//  scan
//
//  Created by xu yongpan on 2021/6/1.
//

#import "AppDelegate.h"
#import "BaseViewController.h"
@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    self.window = [[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
    self.window.backgroundColor = UIColor.whiteColor;
    self.window.rootViewController = [[UINavigationController alloc]initWithRootViewController:[BaseViewController new]];
    [self.window makeKeyAndVisible];
    return YES;
}



@end
