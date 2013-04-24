//
//  CrushTask.h
//  Crusherator
//
//  Created by Raj on 4/20/13.
//  Copyright (c) 2013 Raj. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CrushStrikeLabel.h"
#import "CrushTaskObject.h"

@interface CrushWorkTaskListItem : UIView

@property (nonatomic,retain) CrushStrikeLabel *text;
@property (nonatomic,retain) CrushStrikeLabel *works;
@property (nonatomic,retain) CrushTaskObject *task;

- (id)initWithFrame:(CGRect)frame
           withTask:(CrushTaskObject *)item;

- (void)strike:(BOOL)strike;
- (void)bold:(BOOL)bold;

@end
