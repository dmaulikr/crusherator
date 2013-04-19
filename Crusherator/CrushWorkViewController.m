//
//  CrushFirstViewController.m
//  Crusherator
//
//  Created by Raj on 4/11/13.
//  Copyright (c) 2013 Raj. All rights reserved.
//

#import "CrushWorkViewController.h"
#import "listItem.h"
#import "CrushStrikeLabel.h"
#import "CrushTaskDatabase.h"
#import <AudioToolbox/AudioToolbox.h>
#import <QuartzCore/QuartzCore.h>

#define UIColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]

@interface CrushWorkViewController ()

{
    // an array of to-do items
    CrushTaskDatabase *database;
    
    // Variables that make the timer work
    bool running;
    NSTimeInterval startTime;
    NSTimeInterval elapsedTime;
    NSTimeInterval timeLeft;
    NSTimeInterval timerInterval;
    int defaultTasksOnScreen;
    int tasksOnScreen;
    
    // Options that will be changeable by the user in the future
    int lengthOfWorkBlocks;
    int lengthOfRelaxBlocks;
//    BOOL continuousMode;
//    BOOL ringEndWork;
//    BOOL ringEndPlay;
    BOOL buzzEndWork;
    BOOL buzzEndPlay;
//    BOOL soundDuringWork;
//    BOOL soundDuringPlay;
    
    // Statistics on work completed so far
    int workUnitsCompleted;
    int relaxUnitsCompleted;
//    NSTimeInterval workTimeCompleted;
//    NSTimeInterval playTimeCompleted;
    
    // Dimensions and spacing
    int heightButton;
    double xpad;
    double ypad;
    double widthPage;
    double widthLabel;
    double heightOutput;
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

@end

@implementation CrushWorkViewController

// Timer interface
@synthesize countdown;
@synthesize list;
@synthesize buttonGoStop;
@synthesize buttonNextTask;
@synthesize buttonCompleteTask;

// List elements
@synthesize taskLabels;
@synthesize workLabels;

// Statistics
@synthesize workCount;
@synthesize relaxedCount;
@synthesize taskCount;

// For shifting between work and play
@synthesize currentMode;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialize data source
//        CrushDummyTaskDatabase *database = [[CrushDummyTaskDatabase alloc] init];
//        taskList = database.taskList;
        
        database = [[CrushTaskDatabase alloc] init];
        
        self.title = NSLocalizedString(@"Crush", @"Crush");
        self.tabBarItem.image = [UIImage imageNamed:@"first"];
        
    }
    return self;
}
							
- (void)viewDidLoad
{
    [super viewDidLoad];
    
// modes and defaults
    lengthOfWorkBlocks = 5;
    lengthOfRelaxBlocks = 5;
    defaultTasksOnScreen = 8;
    buzzEndWork = FALSE;
    buzzEndPlay = FALSE;
    
// fonts and colors
    fontCountdown = [UIFont fontWithName:@"Gotham Medium" size:80.0];
    fontButton = [UIFont fontWithName:@"Gotham Medium" size:20.0];
    fontDialog = [UIFont fontWithName:@"Gotham Light" size:15.0];
    fontDialogStrong = [UIFont fontWithName:@"Gotham Medium" size:15.0];
    [self.view setBackgroundColor:[UIColor blackColor]];
    
// set page properties
    heightButton = 35;
    xpad = 5;
    widthPage = self.view.frame.size.width-2*xpad;
    ypad = 5;
    heightOutput = 300;
    indent = 35;
    widthLabel = self.view.frame.size.width-(6*xpad+2*indent);
    widthButton = widthPage/3.0-(xpad/2.0);
    
// text field for results
    countdown = [[UILabel alloc] initWithFrame:(CGRectMake(xpad,ypad,widthPage,heightOutput))];
    countdown.backgroundColor = [UIColor clearColor];
    countdown.font = fontCountdown;
    countdown.text = @"0:25";
    countdown.textAlignment = NSTextAlignmentCenter;
    countdown.layer.shadowColor = [UIColor blackColor].CGColor;
    countdown.layer.shadowOffset = CGSizeMake(0.0, 0.0);
    countdown.layer.shadowRadius = 5.0;
    countdown.layer.shadowOpacity = 0.4;
    countdown.layer.masksToBounds = NO;
    [self.view addSubview:countdown];
    
// add a layer that overlays the cell adding a subtle gradient effect
    gradientHot = [CAGradientLayer layer];
    gradientHot.frame = CGRectMake(xpad,ypad,widthPage,heightOutput);
    gradientHot.colors = @[(id)[[UIColor colorWithRed:(254.0 / 256.0) green:(0.0 / 256.0) blue:(4.0 / 256.0) alpha:1.0f] CGColor],
                           (id)[[UIColor colorWithRed:(253.0 / 256.0) green:(116.0 / 256.0) blue:(16.0 / 256.0) alpha:1.0f] CGColor]];
    gradientHot.locations = @[@0.00f,@1.00f];
    gradientHot.hidden = NO;
    [self.view.layer insertSublayer:gradientHot atIndex:0];

// add a layer that overlays the cell adding a subtle gradient effect
    gradientCold = [CAGradientLayer layer];
    gradientCold.frame = CGRectMake(xpad,ypad,widthPage,heightOutput);
    gradientCold.colors = @[(id)[[UIColor colorWithRed:(29.0 / 256.0) green:(247.0 / 256.0) blue:(255.0 / 256.0) alpha:1.0f] CGColor],
                            (id)[[UIColor colorWithRed:(0.0 / 256.0) green:(168.0 / 256.0) blue:(253.0 / 256.0) alpha:1.0f] CGColor]];
    gradientCold.locations = @[@0.00f, @1.00f];
    gradientCold.hidden = YES;
    [self.view.layer insertSublayer:gradientCold atIndex:0];
    
// work counts for this session
    workCount = [[UILabel alloc] initWithFrame:(CGRectMake(xpad+indent,4*ypad+heightOutput+heightButton,widthLabel,15.0+7.0))];
    workCount.backgroundColor = [UIColor clearColor];
    workCount.font = fontDialog;
    workCount.textColor = [UIColor whiteColor];
    workCount.text = [NSString stringWithFormat:@"Crushed: %d",workUnitsCompleted];
    [self.view addSubview:workCount];

// play counts for this session
    relaxedCount = [[UILabel alloc] initWithFrame:(CGRectMake(xpad+indent,4*ypad+heightOutput+heightButton+15.0+7.0,widthLabel,15.0+7.0))];
    relaxedCount.backgroundColor = [UIColor clearColor];
    relaxedCount.font = fontDialog;
    relaxedCount.textColor = [UIColor whiteColor];
    relaxedCount.text = [NSString stringWithFormat:@"Relaxed: %d",relaxUnitsCompleted];
    [self.view addSubview:relaxedCount];

// task counts for this session
    taskCount = [[UILabel alloc] initWithFrame:(CGRectMake(xpad+indent,4*ypad+heightOutput+heightButton+2*(15.0+7.0),widthLabel,15.0+7.0))];
    taskCount.backgroundColor = [UIColor clearColor];
    taskCount.font = fontDialog;
    taskCount.textColor = [UIColor whiteColor];
    taskCount.text = [NSString stringWithFormat:@"Tasks: %d",tasksOnScreen];
    [self.view addSubview:taskCount];
    
// creating custom button properties
    UIColor *buttonColorDefault = [UIColor blackColor];
    UIColor *buttonColorHighlight = [UIColor blackColor];

// building the buttons
    buttonGoStop = [UIButton buttonWithType:UIButtonTypeCustom];
    [buttonGoStop setFrame:CGRectMake((xpad*2+widthButton),2*ypad+heightOutput,widthButton,heightButton)];
    
    [buttonGoStop.titleLabel setFont:fontButton];
    [buttonGoStop setTitleColor:buttonColorDefault forState:UIControlStateNormal];
    [buttonGoStop setTitleColor:buttonColorHighlight forState:UIControlStateHighlighted];
    [buttonGoStop addTarget:self action:@selector(buttonPress:) forControlEvents:(UIControlEventTouchUpInside)];
    [buttonGoStop setBackgroundColor:UIColorFromRGB(0xcfcfcf)];
    [buttonGoStop setTitleColor:UIColorFromRGB(0x000000) forState:UIControlStateNormal];
    
    [self.view addSubview:buttonGoStop];
    
    buttonNextTask = [UIButton buttonWithType:UIButtonTypeCustom];
    [buttonNextTask setFrame:CGRectMake(xpad,2*ypad+heightOutput,widthButton,heightButton)];
    
    [buttonNextTask.titleLabel setFont:fontButton];
    [buttonNextTask setTitle:@"»" forState:UIControlStateNormal];
    [buttonNextTask setBackgroundColor:UIColorFromRGB(0xcfcfcf)];
    [buttonNextTask setTitleColor:UIColorFromRGB(0x7f2d2d) forState:UIControlStateNormal];
    [buttonNextTask addTarget:self action:@selector(nextTask) forControlEvents:(UIControlEventTouchUpInside)];
    buttonNextTask.contentEdgeInsets = UIEdgeInsetsMake(5.0, 0.0, 0.0, 0.0);
    
    [self.view addSubview:buttonNextTask];
    
    buttonCompleteTask = [UIButton buttonWithType:UIButtonTypeCustom];
    [buttonCompleteTask setFrame:CGRectMake((xpad*3+widthButton*2),2*ypad+heightOutput,widthButton-2,heightButton)];
    
    [buttonCompleteTask.titleLabel setFont:fontButton];
    [buttonCompleteTask setTitle:@"✓" forState:UIControlStateNormal];
    [buttonCompleteTask setBackgroundColor:UIColorFromRGB(0xcfcfcf)];
    [buttonCompleteTask setTitleColor:UIColorFromRGB(0x378328) forState:UIControlStateNormal];
    [buttonCompleteTask addTarget:self action:@selector(completeTask) forControlEvents:(UIControlEventTouchUpInside)];
    buttonCompleteTask.contentEdgeInsets = UIEdgeInsetsMake(5.0, 0.0, 0.0, 0.0);
    
    [self.view addSubview:buttonCompleteTask];
    
// task list
    taskLabels = [[NSMutableArray alloc]init];
    workLabels = [[NSMutableArray alloc]init];
    for (int i = 0; i<defaultTasksOnScreen; i++)
    {
        [self nextTask];
    }
    
// initiate the timer
    [self changeModes:@"workReady"];
    running = FALSE;    
    [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(incrementTimer) userInfo:nil repeats:YES];

//  add subview list
    list = [[CrushOutputView alloc] initWithNibName:@"CrushListViewController_iPhone" bundle:nil];
    [list.view setFrame:CGRectMake(xpad,ypad,widthPage,heightOutput)];
    [self addChildViewController:list];
    [self.view addSubview:list.view];
    
}

- (void)viewWillAppear:(BOOL)animated
{
    [self.list reload];
    
    NSLog(@"reloaded with %i tasks!",database.globalTaskList.count);
}

// pressing button changes modes
- (void)buttonPress:(id)sender
{
    if ([currentMode isEqual:@"workReady"])
    {
        [self changeModes:@"workRunning"];
    }
    else if ([currentMode isEqual:@"workRunning"])
    {
        [self changeModes:@"workPaused"];
    }
    else if ([currentMode isEqual:@"workPaused"])
    {
        [self changeModes:@"workRunning"];
    }
    else if ([currentMode isEqual:@"playReady"])
    {
        [self changeModes:@"playRunning"];
    }
    else if ([currentMode isEqual:@"playRunning"])
    {
        [self changeModes:@"playPaused"];
    }
    else if ([currentMode isEqual:@"playPaused"])
    {
        [self changeModes:@"playRunning"];
    }
}

// changing modes dictates colors, button names, etc.
- (void)changeModes:(NSString *)modeName
{
        if ([modeName isEqualToString:@"workReady"])
        {
            if(buzzEndPlay) [self vibrate];
            running = FALSE;
            currentMode = @"workReady";
            timerInterval = lengthOfWorkBlocks;
            elapsedTime = 0;
            [self updateLabels];
            [buttonGoStop setTitle:@"CRUSH!" forState:(UIControlStateNormal)];
            gradientCold.hidden = YES;
            gradientHot.hidden = NO;
        }
        else if ([modeName isEqualToString:@"playReady"])
        {
            if(buzzEndWork) [self vibrate];
            running = FALSE;
            currentMode = @"playReady";
            timerInterval = lengthOfRelaxBlocks;
            elapsedTime = 0;
            [buttonGoStop setTitle:@"RELAX!" forState:(UIControlStateNormal)];
            gradientCold.hidden = NO;
            gradientHot.hidden = YES;
            workUnitsCompleted++;
            [workCount setText:[NSString stringWithFormat:@"Crushed: %d",workUnitsCompleted]];
//            listItem *item = database.globalTaskList[(database.globalTaskList.count)-1];
//            item.works++;
            [self updateLabels];
        }
        else if ([modeName isEqualToString:@"workPaused"])
        {
            running = FALSE;
            currentMode = @"workPaused";
            [buttonGoStop setTitle:@"?!" forState:(UIControlStateNormal)];
        }
        else if ([modeName isEqualToString:@"playPaused"])
        {
            running = FALSE;
            currentMode = @"playPaused";
            [buttonGoStop setTitle:@"?!" forState:(UIControlStateNormal)];
        }
        else if ([modeName isEqualToString:@"workRunning"])
        {
            running = TRUE;
            currentMode = @"workRunning";
            [buttonGoStop setTitle:@"ll" forState:(UIControlStateNormal)];
        }
        else if ([modeName isEqualToString:@"playRunning"])
        {
            running = TRUE;
            currentMode = @"playRunning";
            [buttonGoStop setTitle:@"ll" forState:(UIControlStateNormal)];
        }
}

// timer increments (only when running) and changes modes if it hits zero
- (void)incrementTimer
{
    if (running)
    {
        elapsedTime++;
        [self updateLabels];
        if((timeLeft==0) && ([currentMode isEqualToString:@"workRunning"]))
        {
            [self changeModes:@"playReady"];
        }
        else if((timeLeft==0) && ([currentMode isEqualToString:@"playRunning"]))
        {
            [self changeModes:@"workReady"];
            relaxUnitsCompleted++;
            [relaxedCount setText:[NSString stringWithFormat:@"Relaxed: %d",relaxUnitsCompleted]];
        }
    }
}

// updates the time shown
- (void)updateLabels
{
    timeLeft = timerInterval - elapsedTime;
    NSInteger ti = (NSInteger)timeLeft;
    NSInteger seconds = ti % 60;
    NSInteger minutes = (ti / 60) % 60;
//    NSInteger hours = (ti / 3600);
    countdown.text = [NSString stringWithFormat:@"%02i:%02i", minutes, seconds];
    
//    listItem *item = database.globalTaskList[(database.globalTaskList.count)-1];
    
//    for(int i=0;i<=(item.works+1);i++)
//    {
//        item.textWorks = [@"" stringByPaddingToLength:item.works withString:@"|" startingAtIndex:0];
//    }
//    UILabel *currentWorkLabel = workLabels[taskLabels.count-1];
//    currentWorkLabel.text = item.textWorks;
    
    CrushStrikeLabel *currentTaskLabel = taskLabels[taskLabels.count-1];
//    currentTaskLabel.strikethrough = item.completed;
}

// adds a new task and moves other tasks down
- (void)nextTask
{
    
    for (int i=0;i<taskLabels.count;i++)
    {
        int jump = 0;
        CrushStrikeLabel *taskListMember = taskLabels[i];
        UILabel *worksListMember = workLabels[i];
        
        if (i==(taskLabels.count-4))
        {
            jump = 1;
        }
        [UIView transitionWithView:taskListMember
                          duration:0.5
                           options:UIViewAnimationOptionCurveEaseOut
                        animations:^(void)
        {
            taskListMember.font = fontDialog;
            taskListMember.center = CGPointMake(taskListMember.center.x,taskListMember.center.y+(jump*65)+15+7);
            taskListMember.textColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:
                                        (1.0-(.1*(taskLabels.count-i)))];
            taskListMember.strikeAlpha = (1.0-(.1*(taskLabels.count-i)));
            taskListMember.strikethroughThickness = 1.0;
        }
                        completion:^(BOOL finished){}
         ];
        
        [UIView transitionWithView:worksListMember
                          duration:0.5
                           options:UIViewAnimationOptionCurveEaseOut
                        animations:^(void)
         {
             worksListMember.font = fontDialog;
             worksListMember.center = CGPointMake(worksListMember.center.x,worksListMember.center.y+(jump*65)+15+7);
             worksListMember.textColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:(1.0-(.1*(taskLabels.count-i)))];
         }
                        completion:^(BOOL finished){}
         ];
    }
    
    CrushStrikeLabel *taskLabel = [[CrushStrikeLabel alloc] initWithFrame:(CGRectMake(xpad+indent,6*ypad,widthLabel,17.0))];
//    listItem *item = database.globalTaskList[(database.globalTaskList.count)-1];
    taskLabel.backgroundColor = [UIColor clearColor];
//    taskLabel.strikethrough = item.completed;
    taskLabel.color = [UIColor blackColor];
    taskLabel.font = fontDialogStrong;
    taskLabel.textColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:(1.0)];
    taskLabel.alpha = 0.0;
//    taskLabel.text = item.text;
    taskLabel.center = CGPointMake(taskLabel.center.x+100,taskLabel.center.y);
    taskLabel.strikethroughThickness = 2.0;
    taskLabel.offset = -3.0;
    taskLabel.enabled = NO;

    UILabel *worksLabel = [[UILabel alloc] initWithFrame:(CGRectMake(xpad+widthPage-indent-50,6*ypad,50,17.0))];
    worksLabel.backgroundColor = [UIColor clearColor];
    worksLabel.font = fontDialogStrong;
    worksLabel.textColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:(1.0)];
    worksLabel.alpha = 0.0;
    worksLabel.textAlignment = NSTextAlignmentRight;
    worksLabel.center = CGPointMake(worksLabel.center.x+100,worksLabel.center.y);
    
    [UIView transitionWithView:taskLabel
                      duration:1.0
                       options:UIViewAnimationOptionCurveEaseInOut
                    animations:^(void)
     {
         taskLabel.center = CGPointMake(taskLabel.center.x-100,taskLabel.center.y);
         [self.view addSubview:taskLabel];
         taskLabel.alpha = 1.0;
     }
                    completion:^(BOOL finished){}
     ];
    
    [UIView transitionWithView:worksLabel
                      duration:1.0
                       options:UIViewAnimationOptionCurveEaseInOut
                    animations:^(void)
     {
         worksLabel.center = CGPointMake(worksLabel.center.x-100,worksLabel.center.y);
         [self.view addSubview:worksLabel];
         worksLabel.alpha = 1.0;
     }
                    completion:^(BOOL finished){}
     ];
    
    [taskLabels addObject:taskLabel];
    [workLabels addObject:worksLabel];
    tasksOnScreen++;
    taskCount.text = [NSString stringWithFormat:@"Tasks: %d",tasksOnScreen-1];
    [self updateLabels];
}

- (void)completeTask
{
//    listItem *item = taskList[((taskLabels.count-1)%(taskList.count-1))];
//    CrushStrikeLabel *currentTaskLabel = taskLabels[taskLabels.count-1];
//    item.completed = !item.completed;
//    currentTaskLabel.text = item.text;
//    currentTaskLabel.strikethrough = item.completed;
//    [self nextTask];
}

//  The function:
- (void)vibrate {
    AudioServicesPlaySystemSound (kSystemSoundID_Vibrate);
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
