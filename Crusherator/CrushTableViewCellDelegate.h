//
//  CrushTableViewCellDelegate.h
//  Crusherator
//
//  Created by Raj on 4/14/13.
//  Copyright (c) 2013 Raj. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CrushTaskInfo.h"
@class CrushListTableViewCell;

// A protocol that the CrushCell uses to inform of state change
@protocol CrushTableViewCellDelegate <NSObject>

// indicates that the given item has been deleted
-(void) toDoItemDeleted:(CrushTaskInfo*)todoItem;

// Indicates that the edit process has begun for the given cell
-(void)cellDidBeginEditing:(CrushListTableViewCell*)cell;

// Indicates that the edit process has committed for the given cell
-(void)cellDidEndEditing:(CrushListTableViewCell*)cell;

@end
