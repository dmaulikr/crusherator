//
//  listItem.h
//  Crusherator
//
//  Created by Raj on 4/13/13.
//  Copyright (c) 2013 Raj. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface listItem : NSObject

// A text description of this item.
@property (nonatomic, copy) NSString *text;
@property (nonatomic, copy) NSString *textWorks;

// A Boolean value that determines the completed state of this item.
@property (nonatomic) BOOL completed;
@property (nonatomic) int works;

// Returns an SHCToDoItem item initialized with the given text.
-(id)initWithText:(NSString*)text;

// Returns an SHCToDoItem item initialized with the given text.
+(id)toDoItemWithText:(NSString*)text;

@end
