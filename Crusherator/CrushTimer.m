//
//  CrushTimer.m
//  Crusherator
//
//  Created by Raj on 5/13/13.
//  Copyright (c) 2013 Raj. All rights reserved.
//

#import "CrushTimer.h"
#import <QuartzCore/QuartzCore.h>
#import "CrushWorkTaskListItem.h"
#import "CrushTaskDatabase.h"

#define UIColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]

@implementation CrushTimer
{
    // an array of to-do items
    CrushTaskDatabase *database;
    UILabel *buttonLabel;
    
    // Variables that make the timer work
    NSTimeInterval startTime;
    NSTimeInterval timerInterval;
    int defaultTasksOnScreen;
    int tasksOnScreen;
    
    // Variables that make the task list work
    NSMutableArray *taskList;
    CrushWorkTaskListItem *currentTask;
    
    // Options that will be changeable by the user in the future
    int lengthOfWorkBlocks;
    int lengthOfRelaxBlocks;
    
    // Statistics on work completed so far
    int workUnitsCompleted;
    int relaxUnitsCompleted;
    int tasksCompleted;
    //    NSTimeInterval workTimeCompleted;
    //    NSTimeInterval playTimeCompleted;
    
    // Dimensions and spacing
    int screenWidth;
    int screenHeight;
    int heightButton;
    double ypad;
    double widthLabel;
    double heightOutput;
    double heightOutputText;
    double heightDialogText;
    double widthButton;
    double indent;
    
    // Fonts and colors
    CAGradientLayer *gradientHot;
    CAGradientLayer *gradientCold;
    UIFont *fontCountdown;
    UIFont *fontButton;
    UIFont *fontDialog;
    UIFont *fontDialogStrong;
}

// Timer interface
@synthesize countdown;
@synthesize circularTimer;

// List elements
@synthesize taskLabels;
@synthesize workLabels;

// Statistics
@synthesize workCount;
@synthesize relaxedCount;
@synthesize taskCount;

// For shifting between work and play
@synthesize currentMode;

const float WORK_CUES_MARGIN = 10.0f;
const float WORK_CUES_WIDTH = 50.0f;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
        database = [CrushTaskDatabase sharedInstance];
        taskList = database.taskInfos;
        
        lengthOfRelaxBlocks = 5;
        lengthOfWorkBlocks = 25;
        
        // set page properties
        screenWidth = self.frame.size.width;
        screenHeight = self.frame.size.height;
        heightButton = screenHeight*.1;
        ypad = screenHeight*.05;
        heightOutput = screenHeight;
        heightOutputText = 80.0;
        heightDialogText = 15.0;
        indent = screenWidth*.15;
        widthLabel = screenWidth-(2*indent);
        widthButton = screenWidth/3.0;
        
        // fonts and colors
        fontCountdown = [UIFont fontWithName:@"Gotham Medium" size:heightOutputText];
        fontButton = [UIFont fontWithName:@"Gotham Medium" size:20.0];
        fontDialog = [UIFont fontWithName:@"Gotham Light" size:heightDialogText];
        fontDialogStrong = [UIFont fontWithName:@"Gotham Medium" size:15.0];
        [self setBackgroundColor:[UIColor blackColor]];
        
        // text field for results
        countdown = [[UILabel alloc] initWithFrame:(CGRectMake(0,ypad,screenWidth,heightOutputText))];
        countdown.center = CGPointMake(screenWidth/2,heightOutput/2);
        countdown.backgroundColor = [UIColor clearColor];
        countdown.font = fontCountdown;
        countdown.textColor = [UIColor whiteColor];
        countdown.textAlignment = NSTextAlignmentCenter;
        countdown.layer.shadowColor = [UIColor blackColor].CGColor;
        countdown.layer.shadowOffset = CGSizeMake(0.0, 0.0);
        countdown.layer.shadowRadius = 5.0;
        countdown.layer.shadowOpacity = 0.4;
        countdown.layer.masksToBounds = NO;
        [self addSubview:countdown];
        
        // building the buttons
        buttonLabel = [[UILabel alloc] initWithFrame:CGRectMake(widthButton,heightOutput-100,widthButton,heightButton)];
        buttonLabel.textAlignment = NSTextAlignmentCenter;
        [buttonLabel setFont:fontButton];
        [buttonLabel setBackgroundColor:[UIColor clearColor]];
        [buttonLabel setTextColor:UIColorFromRGB(0xFFFFFF)];
        
        [self addSubview:buttonLabel];
        
        // add a layer that overlays the cell adding a subtle gradient effect
        gradientHot = [CAGradientLayer layer];
        gradientHot.frame = CGRectMake(0,0,screenWidth,heightOutput);
        gradientHot.colors = @[(id)[[UIColor colorWithRed:(254.0 / 256.0) green:(0.0 / 256.0) blue:(4.0 / 256.0) alpha:1.0f] CGColor],
                               (id)[[UIColor colorWithRed:(253.0 / 256.0) green:(116.0 / 256.0) blue:(16.0 / 256.0) alpha:1.0f] CGColor]];
        gradientHot.locations = @[@0.00f,@1.00f];
        gradientHot.hidden = NO;
        [self.layer insertSublayer:gradientHot atIndex:0];
        
        // add a layer that overlays the cell adding a subtle gradient effect
        gradientCold = [CAGradientLayer layer];
        gradientCold.frame = CGRectMake(0,0,screenWidth,heightOutput);
        gradientCold.colors = @[(id)[[UIColor colorWithRed:(29.0 / 256.0) green:(247.0 / 256.0) blue:(255.0 / 256.0) alpha:1.0f] CGColor],
                                (id)[[UIColor colorWithRed:(0.0 / 256.0) green:(168.0 / 256.0) blue:(253.0 / 256.0) alpha:1.0f] CGColor]];
        gradientCold.locations = @[@0.00f, @1.00f];
        gradientCold.hidden = YES;
        [self.layer insertSublayer:gradientCold atIndex:0];
        
        // task list
        taskLabels = [[NSMutableArray alloc]init];
        for (int i = 0; i<1; i++)
        {
            [self nextTaskWithAnimationDuration:0.5];
        }

    }
    return self;
}

// changing modes dictates colors, button names, etc.
- (void)changeModes:(NSString *)modeName
{
    if ([modeName isEqualToString:@"workReady"])
    {
        self.running = FALSE;
        currentMode = @"workReady";
        timerInterval = lengthOfWorkBlocks;
        self.elapsedTime = 0;
        [self updateLabels];
        [buttonLabel setText:@"CRUSH!"];
        gradientCold.hidden = YES;
        gradientHot.hidden = NO;
        [self.circularTimer removeFromSuperview];
        NSLog(@"workReady");
    }
    else if ([modeName isEqualToString:@"playReady"])
    {
        self.running = FALSE;
        currentMode = @"playReady";
        timerInterval = lengthOfRelaxBlocks;
        self.elapsedTime = 0;
        [buttonLabel setText:@"RELAX!"];
        gradientCold.hidden = NO;
        gradientHot.hidden = YES;
        [self addWork];
        [workCount setText:[NSString stringWithFormat:@"Crushed: %d",workUnitsCompleted]];
        [self.circularTimer removeFromSuperview];
        NSLog(@"playReady");
    }
    else if ([modeName isEqualToString:@"workPaused"])
    {
        self.running = FALSE;
        currentMode = @"workPaused";
        [buttonLabel setText:@"?!"];
        NSLog(@"workPaused");
    }
    else if ([modeName isEqualToString:@"playPaused"])
    {
        self.running = FALSE;
        currentMode = @"playPaused";
        [buttonLabel setText:@"?!"];
        NSLog(@"playPaused");
    }
    else if ([modeName isEqualToString:@"workRunning"])
    {
        self.running = TRUE;
        currentMode = @"workRunning";
        [buttonLabel setText:@"ll"];
        NSLog(@"work timer set %f",self.timeLeft);
        [self startCircularTimerWithTime:self.timeLeft];
        NSLog(@"workRunning");
    }
    else if ([modeName isEqualToString:@"playRunning"])
    {
        self.running = TRUE;
        currentMode = @"playRunning";
        [buttonLabel setText:@"ll"];
        NSLog(@"play timer set %f",self.timeLeft);
        [self startCircularTimerWithTime:self.timeLeft];
        NSLog(@"playRunning");
    }
}

- (void)startCircularTimerWithTime:(int)time
{
    // Initiate circular timer
//    int radius = 100;
//    int internalRadius = 70;
//    UIColor *circleStrokeColor = [UIColor whiteColor];
//    UIColor *activeCircleStrokeColor = ([currentMode isEqualToString:@"playRunning"]) ? [UIColor whiteColor]:[UIColor orangeColor];
//    NSDate *initialDate = [NSDate date];
//    NSDate *finalDate = [NSDate dateWithTimeInterval:time sinceDate:initialDate];
//    
//    self.circularTimer = [[CircularTimer alloc] initWithPosition:CGPointMake(0.0f, 0.0f)
//                                                          radius:radius
//                                                  internalRadius:internalRadius
//                                               circleStrokeColor:circleStrokeColor
//                                         activeCircleStrokeColor:activeCircleStrokeColor
//                                                     initialDate:initialDate
//                                                       finalDate:finalDate
//                                                   startCallback:^{
//                                                       //do something
//                                                   }
//                                                     endCallback:^{
//                                                         //do something
//                                                     }];
//    [self insertSubview:self.circularTimer belowSubview:countdown];
//    self.circularTimer.center = countdown.center;
}

// updates the time shown
- (void)updateLabels
{
    NSLog(@"updateLabels");
    self.timeLeft = timerInterval - self.elapsedTime;
    NSLog(@"elapsedTime %f", self.elapsedTime);
    NSInteger ti = (NSInteger)self.timeLeft;
    NSInteger seconds = ti % 60;
    NSInteger minutes = (ti / 60) % 60;
    //    NSInteger hours = (ti / 3600);
    countdown.text = [NSString stringWithFormat:@"%02i:%02i", minutes, seconds];
    
    for (int i = 0; i<=taskLabels.count-1; i++)
    {
        CrushWorkTaskListItem *task = taskLabels[i];
        CrushTaskObject *item = task.task;
        for(int i=0;i<=(item.works);i++)
        {
            task.works.text = [@"" stringByPaddingToLength:item.works withString:@"|" startingAtIndex:0];
        }
        task.text.text = item.text;
        [task strike:(item.completed)];
    }
}

- (void)clearTasks
{
    for(UIView *subview in [self subviews]) {
        if([subview isKindOfClass:[CrushWorkTaskListItem class]])
        {
            [subview removeFromSuperview];
        }
    }
    tasksOnScreen = 0;
    taskLabels = [[NSMutableArray alloc] init];
}

// adds a new task and moves other tasks down
- (void)nextTaskWithAnimationDuration:(float)duration
{
    if(tasksOnScreen == database.taskInfos.count)
    {
        [self clearTasks];
    }
    
    for (int i=0;i<taskLabels.count;i++)
    {
        int jump = 0;
        CrushWorkTaskListItem *taskListMember = taskLabels[i];
        int labelBottom = (taskListMember.frame.origin.y+taskListMember.frame.size.height);
        int countdownTop = (countdown.frame.origin.y - taskListMember.frame.size.height);
        int countdownBottom = (countdown.frame.origin.y+countdown.frame.size.height);
        
        if ((labelBottom >= countdownTop) && (labelBottom <= countdownBottom))
        {
            jump = 1;
        }
        [UIView transitionWithView:taskListMember
                          duration:duration
                           options:UIViewAnimationOptionCurveEaseOut
                        animations:^(void)
         {
             taskListMember.center = CGPointMake(taskListMember.center.x,taskListMember.center.y+(jump*countdown.frame.size.height)+15+7);
             taskListMember.alpha = (1.0-(.08*(taskLabels.count-i)));
             [taskListMember bold:NO];
             taskListMember.transform = CGAffineTransformMakeScale(1.0, 1.0);
         }
                        completion:^(BOOL finished){}
         ];
    }
    
    CrushTaskObject *item = database.taskInfos[tasksOnScreen];
    CrushWorkTaskListItem *taskLabel = [[CrushWorkTaskListItem alloc] initWithFrame:(CGRectMake(indent,ypad,widthLabel,17.0)) withTask:item];
    taskLabel.alpha = 0.0;
    taskLabel.center = CGPointMake(taskLabel.center.x+100,taskLabel.center.y);
    
    [UIView transitionWithView:taskLabel
                      duration:duration*2
                       options:UIViewAnimationOptionCurveEaseInOut
                    animations:^(void)
     {
         taskLabel.center = CGPointMake(taskLabel.center.x-100,taskLabel.center.y);
         taskLabel.alpha = 1.0;
         taskLabel.transform = CGAffineTransformMakeScale(1.2, 1.2);
         taskLabel.layer.shadowColor = [UIColor blackColor].CGColor;
         taskLabel.layer.shadowOffset = CGSizeMake(3.0, 3.0);
         taskLabel.layer.shadowRadius = 4.0;
         taskLabel.layer.shadowOpacity = 0.4;
         taskLabel.layer.masksToBounds = NO;
         
         [self addSubview:taskLabel];
     }
                    completion:^(BOOL finished)
     {
         if(item.completed)
         {
             [self nextTaskWithAnimationDuration:0.1];
         }
     }
     ];
    
    [taskLabels addObject:taskLabel];
    tasksOnScreen++;
    taskCount.text = [NSString stringWithFormat:@"Tasks: %d",tasksCompleted];
    [self updateLabels];
}

// marks a task complete and calls for next task
- (void)completeTask
{
    CrushWorkTaskListItem *currentTaskLabel = taskLabels[tasksOnScreen-1];
    CrushTaskObject *item = currentTaskLabel.task;
    item.completed = !item.completed;
    [item editInDatabase];
    currentTaskLabel.text.text = item.text;
    [currentTaskLabel strike:(item.completed)];
    tasksCompleted++;
    [self nextTaskWithAnimationDuration:0.5];
}

- (void)addWork
{
    CrushWorkTaskListItem *currentTaskLabel = taskLabels[tasksOnScreen-1];
    CrushTaskObject *item = currentTaskLabel.task;
    item.works++;
    [item editInDatabase];
    [self updateLabels];
    workUnitsCompleted++;
}

@end
