//
//  listItem.m
//  Crusherator
//
//  Created by Raj on 4/13/13.
//  Copyright (c) 2013 Raj. All rights reserved.
//

#import "listItem.h"

@implementation listItem

-(id)initWithText:(NSString*)text {
    if (self = [super init]) {
        self.works = 0;
        self.text = text;
        self.textWorks = @"*";
        self.completed = FALSE;
    }
    return self;
}

+(id)toDoItemWithText:(NSString *)text {
    return [[listItem alloc] initWithText:text];
}

@end
