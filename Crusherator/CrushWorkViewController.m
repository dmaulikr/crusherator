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
#import <AudioToolbox/AudioToolbox.h>

#define UIColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]

@interface CrushWorkViewController ()
{
    bool running;
    NSTimeInterval startTime;
    NSTimeInterval timerInterval;
    NSTimeInterval elapsedTime;
    NSTimeInterval timeLeft;
    NSMutableArray *taskList;
    NSMutableArray * _toDoItems;
    
    int workUnitsCompleted;
    int relaxUnitsCompleted;
    
    int lengthOfWorkBlocks;
    int lengthOfRelaxBlocks;
    
    int defaultTasksOnScreen;
    int tasksOnScreen;
    
    int heightButton;
    double xpad;
    double ypad;
    double widthPage;
    double widthLabel;
    double heightOutput;
    double widthButton;
    double indent;
    UIFont *fontCountdown;
    UIFont *fontButton;
    UIFont *fontDialog;
    UIFont *fontDialogStrong;
}

@end

@implementation CrushWorkViewController

@synthesize countdown;
@synthesize workCount;
@synthesize relaxedCount;
@synthesize taskCount;
@synthesize currentMode;
@synthesize buttonGoStop;
@synthesize buttonNextTask;
@synthesize buttonCompleteTask;
@synthesize taskLabels;
@synthesize workLabels;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = NSLocalizedString(@"Crush", @"Crush");
        self.tabBarItem.image = [UIImage imageNamed:@"first"];
        
        // create a dummy to-do list
        _toDoItems = [[NSMutableArray alloc] init];
        [_toDoItems addObject:[listItem toDoItemWithText:@"Feed the cat"]];
        [_toDoItems addObject:[listItem toDoItemWithText:@"Buy eggs"]];
        [_toDoItems addObject:[listItem toDoItemWithText:@"Pack bags for WWDC"]];
        [_toDoItems addObject:[listItem toDoItemWithText:@"Rule the web"]];
        [_toDoItems addObject:[listItem toDoItemWithText:@"Buy a new iPhone"]];
        [_toDoItems addObject:[listItem toDoItemWithText:@"Find missing socks"]];
        [_toDoItems addObject:[listItem toDoItemWithText:@"Write a new tutorial"]];
        [_toDoItems addObject:[listItem toDoItemWithText:@"Master Objective-C"]];
        [_toDoItems addObject:[listItem toDoItemWithText:@"Remember your wedding anniversary!"]];
        [_toDoItems addObject:[listItem toDoItemWithText:@"Drink less beer"]];
        [_toDoItems addObject:[listItem toDoItemWithText:@"Learn to draw"]];
        [_toDoItems addObject:[listItem toDoItemWithText:@"Take the car to the garage"]];
        [_toDoItems addObject:[listItem toDoItemWithText:@"Sell things on eBay"]];
        [_toDoItems addObject:[listItem toDoItemWithText:@"Learn to juggle"]];
        [_toDoItems addObject:[listItem toDoItemWithText:@"Give up"]];
        
        //  Vibrate when sessions are done:
        AudioServicesPlaySystemSound (kSystemSoundID_Vibrate);
    }
    return self;
}
							
- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
// modes and defaults
    lengthOfWorkBlocks = 5;
    lengthOfRelaxBlocks = 5;
    defaultTasksOnScreen = 8;
    
// fonts and colors
    fontCountdown = [UIFont fontWithName:@"Gotham Medium" size:80.0];
    fontButton = [UIFont fontWithName:@"Gotham Medium" size:20.0];
    fontDialog = [UIFont fontWithName:@"Gotham Light" size:15.0];
    fontDialogStrong = [UIFont fontWithName:@"Gotham Medium" size:15.0];
    [self.view setBackgroundColor:[UIColor blackColor]];
    
// set page properties
    heightButton = 70;
    xpad = 5;
    widthPage = self.view.frame.size.width-2*xpad;
    ypad = 5;
    heightOutput = 300;
    indent = 35;
    widthLabel = self.view.frame.size.width-(6*xpad+2*indent);
    widthButton = widthPage/3.0-(xpad/2.0);
    
// text field for results
    countdown = [[UILabel alloc] initWithFrame:(CGRectMake(xpad,ypad,widthPage,heightOutput))];
    countdown.backgroundColor = [UIColor lightGrayColor];
    countdown.font = fontCountdown;
    countdown.text = @"0:25";
    countdown.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:countdown];
    
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
    
    [self.view addSubview:buttonGoStop];
    
    buttonNextTask = [UIButton buttonWithType:UIButtonTypeCustom];
    [buttonNextTask setFrame:CGRectMake(xpad,2*ypad+heightOutput,widthButton,heightButton)];
    
    [buttonNextTask.titleLabel setFont:fontButton];
    [buttonNextTask setTitle:@"»" forState:UIControlStateNormal];
    [buttonNextTask setBackgroundColor:UIColorFromRGB(0xbf5757)];
    [buttonNextTask setTitleColor:UIColorFromRGB(0x7f2d2d) forState:UIControlStateNormal];
    [buttonNextTask addTarget:self action:@selector(nextTask) forControlEvents:(UIControlEventTouchUpInside)];
    buttonNextTask.contentEdgeInsets = UIEdgeInsetsMake(5.0, 0.0, 0.0, 0.0);
    
    [self.view addSubview:buttonNextTask];
    
    buttonCompleteTask = [UIButton buttonWithType:UIButtonTypeCustom];
    [buttonCompleteTask setFrame:CGRectMake((xpad*3+widthButton*2),2*ypad+heightOutput,widthButton-2,heightButton)];
    
    [buttonCompleteTask.titleLabel setFont:fontButton];
    [buttonCompleteTask setTitle:@"✓" forState:UIControlStateNormal];
    [buttonCompleteTask setBackgroundColor:UIColorFromRGB(0xb3ddab)];
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
            [self vibrate];
            running = FALSE;
            currentMode = @"workReady";
            timerInterval = lengthOfWorkBlocks;
            elapsedTime = 0;
            [self updateLabels];
            [buttonGoStop setTitle:@"CRUSH!" forState:(UIControlStateNormal)];
            countdown.backgroundColor = UIColorFromRGB(0x5797bf);
            [buttonGoStop setBackgroundColor:UIColorFromRGB(0xa6c9e0)];
            [buttonGoStop setTitleColor:UIColorFromRGB(0x215c81) forState:UIControlStateNormal];
        }
        else if ([modeName isEqualToString:@"playReady"])
        {
            [self vibrate];
            running = FALSE;
            currentMode = @"playReady";
            timerInterval = lengthOfRelaxBlocks;
            elapsedTime = 0;
            [buttonGoStop setTitle:@"RELAX!" forState:(UIControlStateNormal)];
            countdown.backgroundColor = UIColorFromRGB(0x60c04d);
            [buttonGoStop setBackgroundColor:UIColorFromRGB(0xb3ddab)];
            [buttonGoStop setTitleColor:UIColorFromRGB(0x378328) forState:UIControlStateNormal];
            workUnitsCompleted++;
            [workCount setText:[NSString stringWithFormat:@"Crushed: %d",workUnitsCompleted]];
            listItem *item = _toDoItems[((taskLabels.count)%_toDoItems.count)];
            item.works++;
            [self updateLabels];
        }
        else if ([modeName isEqualToString:@"workPaused"])
        {
            running = FALSE;
            currentMode = @"workPaused";
            [buttonGoStop setTitle:@"?!" forState:(UIControlStateNormal)];
            [buttonGoStop setBackgroundColor:UIColorFromRGB(0xcfcfcf)];
            [buttonGoStop setTitleColor:UIColorFromRGB(0x000000) forState:UIControlStateNormal];
        }
        else if ([modeName isEqualToString:@"playPaused"])
        {
            running = FALSE;
            currentMode = @"playPaused";
            [buttonGoStop setTitle:@"?!" forState:(UIControlStateNormal)];
            [buttonGoStop setBackgroundColor:UIColorFromRGB(0xcfcfcf)];
            [buttonGoStop setTitleColor:UIColorFromRGB(0x000000) forState:UIControlStateNormal];
        }
        else if ([modeName isEqualToString:@"workRunning"])
        {
            running = TRUE;
            currentMode = @"workRunning";
            [buttonGoStop setTitle:@"ll" forState:(UIControlStateNormal)];
            [buttonGoStop setBackgroundColor:UIColorFromRGB(0xcfcfcf)];
            [buttonGoStop setTitleColor:UIColorFromRGB(0x000000) forState:UIControlStateNormal];
        }
        else if ([modeName isEqualToString:@"playRunning"])
        {
            running = TRUE;
            currentMode = @"playRunning";
            [buttonGoStop setTitle:@"ll" forState:(UIControlStateNormal)];
            [buttonGoStop setBackgroundColor:UIColorFromRGB(0xcfcfcf)];
            [buttonGoStop setTitleColor:UIColorFromRGB(0x000000) forState:UIControlStateNormal];
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
    
    listItem *item = _toDoItems[((taskLabels.count)%_toDoItems.count)];
    
    for(int i=0;i<=(item.works+1);i++)
    {
        item.textWorks = [@"" stringByPaddingToLength:item.works withString:@"|" startingAtIndex:0];
    }
    UILabel *currentWorkLabel = workLabels[taskLabels.count-1];
    currentWorkLabel.text = item.textWorks;
    
    CrushStrikeLabel *currentTaskLabel = taskLabels[taskLabels.count-1];
    currentTaskLabel.strikethrough = item.completed;
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
    listItem *item = _toDoItems[((taskLabels.count)%_toDoItems.count)];
    taskLabel.backgroundColor = [UIColor clearColor];
    taskLabel.strikethrough = item.completed;
    taskLabel.color = [UIColor blackColor];
    taskLabel.font = fontDialogStrong;
    taskLabel.textColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:(1.0)];
    taskLabel.alpha = 0.0;
    taskLabel.text = item.text;
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
    listItem *item = _toDoItems[((taskLabels.count-1)%(_toDoItems.count-1))];
    CrushStrikeLabel *currentTaskLabel = taskLabels[taskLabels.count-1];
    item.completed = !item.completed;
    currentTaskLabel.text = item.text;
    currentTaskLabel.strikethrough = item.completed;
    [self nextTask];
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
