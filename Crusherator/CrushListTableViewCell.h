//
//  CrushCell.h
//  Crusherator
//
//  Created by Raj on 4/13/13.
//  Copyright (c) 2013 Raj. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CrushTableViewCellDelegate.h"
#import "CrushStrikeLabel.h"
#define SHC_ROW_HEIGHT 50.0f

// A custom table cell that renders listItem items.
@interface CrushListTableViewCell : UITableViewCell <UITextFieldDelegate>

// The item that this cell renders.
@property (nonatomic) listItem *toDoItem;

// The object that acts as delegate for this cell. 
@property (nonatomic, assign) id<CrushTableViewCellDelegate> delegate;

// the label used to render the to-do text
@property (nonatomic, strong, readonly) CrushStrikeLabel* label;

@end
