//
//  CrushFirstViewController.h
//  Crusherator
//
//  Created by Raj on 4/11/13.
//  Copyright (c) 2013 Raj. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "listItem.h"

@interface CrushWorkViewController : UIViewController

@property (nonatomic, retain) UILabel *countdown;
@property (nonatomic, retain) UILabel *workCount;
@property (nonatomic, retain) UILabel *relaxedCount;
@property (nonatomic, retain) UILabel *taskCount;
@property (nonatomic, retain) NSString *currentMode;
@property (nonatomic, retain) UIButton *buttonGoStop;
@property (nonatomic, retain) UIButton *buttonNextTask;
@property (nonatomic, retain) UIButton *buttonCompleteTask;
@property (nonatomic, retain) NSMutableArray *taskLabels;
@property (nonatomic, retain) NSMutableArray *workLabels;
@property (nonatomic, retain) NSMutableArray *completedStrikes;

@end
