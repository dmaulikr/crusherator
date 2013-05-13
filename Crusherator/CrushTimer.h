//
//  CrushTimer.h
//  Crusherator
//
//  Created by Raj on 5/13/13.
//  Copyright (c) 2013 Raj. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CircularTimer.h"

@interface CrushTimer : UIView

// Interface and output
@property (nonatomic, retain) UILabel *countdown;

// Statistics
@property (nonatomic, retain) UILabel *workCount;
@property (nonatomic, retain) UILabel *relaxedCount;
@property (nonatomic, retain) UILabel *taskCount;
@property (nonatomic, assign) NSTimeInterval elapsedTime;

// Variables that make the timer work
@property (nonatomic, retain) NSString *currentMode;
@property (nonatomic, assign) BOOL *running;

// Buttons
@property (nonatomic, retain) UIButton *buttonGoStop;
@property (nonatomic, retain) UIButton *buttonNextTask;
@property (nonatomic, retain) UIButton *buttonCompleteTask;

// Arrays that hold the list labels
@property (nonatomic, retain) NSMutableArray *taskLabels;
@property (nonatomic, retain) NSMutableArray *workLabels;

@property (nonatomic, strong) CircularTimer *circularTimer;

-(void)updateLabels;
-(void)nextTask;
-(void)addWork;
-(void)completeTask;
-(void)startCircularTimerWithTime:(int)time;
-(void)changeModes:(NSString *)modeName;

@end
