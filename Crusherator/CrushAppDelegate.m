//
//  CrushAppDelegate.m
//  Crusherator
//
//  Created by Raj on 4/11/13.
//  Copyright (c) 2013 Raj. All rights reserved.
//

#import "CrushAppDelegate.h"

#import "CrushWorkViewController.h"

#import "CrushListTableViewController.h"

#import "CrushSettingsViewController.h"

@implementation CrushAppDelegate
{
    CrushWorkViewController *viewController1;
    UIPageViewController *viewController2;
    CrushSettingsViewController *viewController3;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        viewController1 = [[CrushWorkViewController alloc] initWithNibName:@"CrushWorkViewController_iPhone" bundle:nil];
        
        viewController2 = [[UIPageViewController alloc]
                           initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll
                           navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal
                           options:@{UIPageViewControllerOptionInterPageSpacingKey : @20.0f}];
        viewController2.dataSource = self;
        viewController2.title = NSLocalizedString(@"List", @"List");
        viewController2.tabBarItem.image = [UIImage imageNamed:@"second"];
        CrushListTableViewController *pageZero = [CrushListTableViewController viewControllerForPageIndex:0];
        [viewController2 setViewControllers:@[pageZero]
                                  direction:UIPageViewControllerNavigationDirectionForward
                                   animated:NO
                                 completion:NULL];
        
        viewController3 = [[CrushSettingsViewController alloc]initWithNibName:@"CrushSettingsViewController_iPhone" bundle:nil];
    }
    self.tabBarController = [[UITabBarController alloc] init];
    self.tabBarController.viewControllers = @[viewController1, viewController2, viewController3];
    self.window.rootViewController = self.tabBarController;
    
    [self.window makeKeyAndVisible];
    return YES;
}

- (UIViewController *)pageViewController:(UIPageViewController *)pvc viewControllerBeforeViewController:(CrushListTableViewController *)vc
{
    NSInteger index = vc.pageIndex;
    return [CrushListTableViewController viewControllerForPageIndex:(index - 1)];
}

- (UIViewController *)pageViewController:(UIPageViewController *)pvc viewControllerAfterViewController:(CrushListTableViewController *)vc
{
    NSInteger index = vc.pageIndex;
    return [CrushListTableViewController viewControllerForPageIndex:(index + 1)];
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
    NSLog(@"willresignactive");
    // To do: save current time
    [viewController1 moveToBackground];
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    NSLog(@"didenterbackground");
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    NSLog(@"willenterforeground");
    [viewController1 moveToForeground];
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    NSLog(@"didbecomeactive");
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    NSLog(@"willterminate");
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

/*
// Optional UITabBarControllerDelegate method.
- (void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController
{
}
*/

/*
// Optional UITabBarControllerDelegate method.
- (void)tabBarController:(UITabBarController *)tabBarController didEndCustomizingViewControllers:(NSArray *)viewControllers changed:(BOOL)changed
{
}
*/

@end
