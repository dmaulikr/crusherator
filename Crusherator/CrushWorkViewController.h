//
//  CrushFirstViewController.h
//  Crusherator
//
//  Created by Raj on 4/11/13.
//  Copyright (c) 2013 Raj. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CrushListTableViewController.h"
#import "CrushWorkTaskListItem.h"
#import "CircularTimer.h"

@interface CrushWorkViewController : UIViewController

// ** do all of these need to be synthesized?  Probably not.  Should be instance variables.

// Statistics
@property (nonatomic, retain) UILabel *workCount;
@property (nonatomic, retain) UILabel *relaxedCount;
@property (nonatomic, retain) UILabel *taskCount;

// Variables that make the timer work
@property (nonatomic, retain) NSString *currentMode;

// Arrays that hold the list labels
@property (nonatomic, retain) NSMutableArray *taskLabels;
@property (nonatomic, retain) NSMutableArray *workLabels;

@property (nonatomic, strong) CircularTimer *circularTimer;

- (void) saveState;
- (void) reloadState;

@end
