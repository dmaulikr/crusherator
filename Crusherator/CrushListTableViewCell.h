//
//  CrushCell.h
//  Crusherator
//
//  Created by Raj on 4/13/13.
//  Copyright (c) 2013 Raj. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CrushTableViewCellDelegate.h"
#import "CrushTaskObject.h"
#import "CrushStrikeLabel.h"
#define SHC_ROW_HEIGHT 70.0f

// A custom table cell that renders listItem items.
@interface CrushListTableViewCell : UITableViewCell <UITextFieldDelegate>

// The item that this cell renders.
@property (nonatomic) CrushTaskObject *toDoItem;

// The object that acts as delegate for this cell. 
@property (nonatomic, assign) id<CrushTableViewCellDelegate> delegate;

// Tells whether cell is being edited or not.
@property (nonatomic, assign) BOOL isBeingEdited;

// the label used to render the to-do text
@property (nonatomic, strong) CrushStrikeLabel* label;
@property (nonatomic, strong) CrushStrikeLabel* workLabel;
@property (nonatomic, strong) CrushStrikeLabel* estimatedWorksLabel;

-(void)dismissKeyboard;

@end
