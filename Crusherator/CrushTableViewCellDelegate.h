//
//  CrushTableViewCellDelegate.h
//  Crusherator
//
//  Created by Raj on 4/14/13.
//  Copyright (c) 2013 Raj. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "listItem.h"

// A protocol that the CrushCell uses to inform of state change
@protocol CrushTableViewCellDelegate <NSObject>

// indicates that the given item has been deleted
-(void) toDoItemDeleted:(listItem*)todoItem;

@end
