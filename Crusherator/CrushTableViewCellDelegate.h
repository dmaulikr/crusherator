//
//  CrushTableViewCellDelegate.h
//  Crusherator
//
//  Created by Raj on 4/14/13.
//  Copyright (c) 2013 Raj. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CrushTaskObject.h"
@class CrushListTableViewCell;

// A protocol that the CrushListTableViewCell uses to inform of state change (applies to CrushListTableViewController)
@protocol CrushTableViewCellDelegate <NSObject>

// indicates that the given item has been deleted
-(void) toDoItemDeleted:(CrushTaskObject*)todoItem;

// Indicates that the edit process has begun for the given cell
-(void)cellDidBeginEditing:(CrushListTableViewCell*)cell;

// Indicates that the edit process has committed for the given cell
-(void)cellDidEndEditing:(CrushListTableViewCell*)cell;

// Indicates that the edit process has committed for the given cell
-(BOOL)cellShouldBeginEditing:(CrushListTableViewCell*)cell;

-(void)cellIsBeingMoved:(CrushListTableViewCell *)cellBeingMoved;

-(void)cellIsDoneBeingMoved:(CrushListTableViewCell *)cellBeingMoved;

-(void)cellIsBeingDragged:(CrushListTableViewCell *)cellBeingMoved to:(CGPoint)number;

-(void)handlePan:(id)gestureRecognizer;

@end
