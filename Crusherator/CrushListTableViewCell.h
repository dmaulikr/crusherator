//
//  CrushCell.h
//  Crusherator
//
//  Created by Raj on 4/13/13.
//  Copyright (c) 2013 Raj. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CrushTableViewCellDelegate.h"

// A custom table cell that renders listItem items.
@interface CrushListTableViewCell : UITableViewCell

// The item that this cell renders.
@property (nonatomic) listItem *toDoItem;

// The object that acts as delegate for this cell. 
@property (nonatomic, assign) id<CrushTableViewCellDelegate> delegate;

@end
