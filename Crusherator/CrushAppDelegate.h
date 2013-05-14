//
//  CrushAppDelegate.h
//  Crusherator
//
//  Created by Raj on 4/11/13.
//  Copyright (c) 2013 Raj. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CrushAppDelegate : UIResponder <UIApplicationDelegate, UITabBarControllerDelegate, UIPageViewControllerDataSource>

@property (strong, nonatomic) UIWindow *window;

@property (strong, nonatomic) UITabBarController *tabBarController;

@end
