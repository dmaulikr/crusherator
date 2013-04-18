//
//  CrushDummyTaskDatabase.m
//  Crusherator
//
//  Created by Raj on 4/16/13.
//  Copyright (c) 2013 Raj. All rights reserved.
//

#import "CrushDummyTaskDatabase.h"

@implementation CrushDummyTaskDatabase

@synthesize taskList;

- (id)init {
    if ((self = [super init]))
    {
        // create a dummy to-do list
        taskList = [[NSMutableArray alloc] init];
        [taskList addObject:[listItem toDoItemWithText:@"Feed the cat"]];
        [taskList addObject:[listItem toDoItemWithText:@"Buy eggs"]];
        [taskList addObject:[listItem toDoItemWithText:@"Pack bags for WWDC"]];
        [taskList addObject:[listItem toDoItemWithText:@"Rule the web"]];
        [taskList addObject:[listItem toDoItemWithText:@"Buy a new iPhone"]];
        [taskList addObject:[listItem toDoItemWithText:@"Find missing socks"]];
        [taskList addObject:[listItem toDoItemWithText:@"Write a new tutorial"]];
        [taskList addObject:[listItem toDoItemWithText:@"Master Objective-C"]];
        [taskList addObject:[listItem toDoItemWithText:@"Remember your wedding anniversary!"]];
        [taskList addObject:[listItem toDoItemWithText:@"Drink less beer"]];
        [taskList addObject:[listItem toDoItemWithText:@"Learn to draw"]];
        [taskList addObject:[listItem toDoItemWithText:@"Take the car to the garage"]];
        [taskList addObject:[listItem toDoItemWithText:@"Sell things on eBay"]];
        [taskList addObject:[listItem toDoItemWithText:@"Learn to juggle"]];
        [taskList addObject:[listItem toDoItemWithText:@"Give up"]];
    }
    return self;
}

@end
