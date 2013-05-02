//
//  CrushFirstViewController.m
//  Crusherator
//
//  Created by Raj on 4/11/13.
//  Copyright (c) 2013 Raj. All rights reserved.
//

#import "CrushWorkViewController.h"
#import "CrushStrikeLabel.h"
#import "CrushTaskDatabase.h"
#import <AudioToolbox/AudioToolbox.h>
#import <QuartzCore/QuartzCore.h>
#import <MediaPlayer/MediaPlayer.h>
#import "UIImage+CrushImage.h"

#define UIColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]

@interface CrushWorkViewController ()
{
    // an array of to-do items
    CrushTaskDatabase *database;
    
    // Gesture variables
    UIPanGestureRecognizer *panRecognizer;
    CGPoint _originalCenter;
    BOOL _completeOnDragRelease;
    BOOL _nextOnDragRelease;
    BOOL _pauseOnDragRelease;
    BOOL _stopOnDragRelease;
    UIImageView *_tickLabel;
	UIImageView *_crossLabel;
    
    // Variables that make the timer work
    bool running;
    NSTimeInterval startTime;
    NSTimeInterval elapsedTime;
    NSTimeInterval timeLeft;
    NSTimeInterval timerInterval;
    int defaultTasksOnScreen;
    int tasksOnScreen;

    // Variables that make the task list work
    NSMutableArray *taskList;
    CrushWorkTaskListItem *currentTask;
    
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

@end

@implementation CrushWorkViewController

// Timer interface
@synthesize countdown;
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

const float WORK_CUES_MARGIN = 10.0f;
const float WORK_CUES_WIDTH = 50.0f;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialize data source

        database = [CrushTaskDatabase sharedInstance];
        taskList = database.taskInfos;
        
        self.title = NSLocalizedString(@"Work", @"Work");
        self.tabBarItem.image = [UIImage imageNamed:@"first"];
        
        panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
        [self.view addGestureRecognizer:panRecognizer];
        
        // add a tick and cross
        UIImage *check = [[UIImage imageNamed:@"check.png"] imageWithOverlayColor:[UIColor grayColor]];
        _tickLabel = [[UIImageView alloc] initWithImage:check];
        [self.view addSubview:_tickLabel];
        
        UIImage *next = [[UIImage imageNamed:@"next.png"] imageWithOverlayColor:[UIColor grayColor]];
        _crossLabel = [[UIImageView alloc] initWithImage:next];
        [self.view addSubview:_crossLabel];
        
        // ensure the gradient layers occupies the full bounds
        _tickLabel.frame = CGRectMake(0,0,50.0,50.0);
        _tickLabel.center = CGPointMake(self.view.center.x + self.view.frame.size.width/2 + 50.0, self.view.center.y);
        _crossLabel.frame = CGRectMake(0,0,50.0,50.0);
        _crossLabel.center = CGPointMake(self.view.center.x + self.view.frame.size.width/2 + 50.0, self.view.center.y);
        
    }
    return self;
}

- (void)viewDidAppear:(BOOL)animated
{
    [self.view setNeedsDisplay];
    [self updateLabels];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
// modes and defaults
    lengthOfWorkBlocks = 25;
    lengthOfRelaxBlocks = 5;
    defaultTasksOnScreen = 1;
    buzzEndWork = FALSE;
    buzzEndPlay = FALSE;
    
// set page properties
    screenWidth = self.view.frame.size.width;
    screenHeight = self.view.frame.size.height;
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
    [self.view setBackgroundColor:[UIColor blackColor]];
    
    
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
    [self.view addSubview:countdown];

    
// building the buttons
    buttonGoStop = [UIButton buttonWithType:UIButtonTypeCustom];
    [buttonGoStop setFrame:CGRectMake(widthButton,heightOutput-100,widthButton,heightButton)];
    
    [buttonGoStop.titleLabel setFont:fontButton];
    [buttonGoStop addTarget:self action:@selector(buttonPress:) forControlEvents:(UIControlEventTouchUpInside)];
    [buttonGoStop setBackgroundColor:[UIColor clearColor]];
    [buttonGoStop setTitleColor:UIColorFromRGB(0xFFFFFF) forState:UIControlStateNormal];
    
    [self.view addSubview:buttonGoStop];
    
// add a layer that overlays the cell adding a subtle gradient effect
    gradientHot = [CAGradientLayer layer];
    gradientHot.frame = CGRectMake(0,0,screenWidth,heightOutput);
    gradientHot.colors = @[(id)[[UIColor colorWithRed:(254.0 / 256.0) green:(0.0 / 256.0) blue:(4.0 / 256.0) alpha:1.0f] CGColor],
                           (id)[[UIColor colorWithRed:(253.0 / 256.0) green:(116.0 / 256.0) blue:(16.0 / 256.0) alpha:1.0f] CGColor]];
    gradientHot.locations = @[@0.00f,@1.00f];
    gradientHot.hidden = NO;
    [self.view.layer insertSublayer:gradientHot atIndex:0];

// add a layer that overlays the cell adding a subtle gradient effect
    gradientCold = [CAGradientLayer layer];
    gradientCold.frame = CGRectMake(0,0,screenWidth,heightOutput);
    gradientCold.colors = @[(id)[[UIColor colorWithRed:(29.0 / 256.0) green:(247.0 / 256.0) blue:(255.0 / 256.0) alpha:1.0f] CGColor],
                            (id)[[UIColor colorWithRed:(0.0 / 256.0) green:(168.0 / 256.0) blue:(253.0 / 256.0) alpha:1.0f] CGColor]];
    gradientCold.locations = @[@0.00f, @1.00f];
    gradientCold.hidden = YES;
    [self.view.layer insertSublayer:gradientCold atIndex:0];
    
// task list
    taskLabels = [[NSMutableArray alloc]init];
    for (int i = 0; i<defaultTasksOnScreen; i++)
    {
        [self nextTask];
    }
    
// initiate the timer
    [self changeModes:@"workReady"];
    running = FALSE;
    UIBackgroundTaskIdentifier bgTask =0;
    UIApplication  *app = [UIApplication sharedApplication];
    bgTask = [app beginBackgroundTaskWithExpirationHandler:^{
        [app endBackgroundTask:bgTask];
    }];
    [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(incrementTimer) userInfo:nil repeats:YES];
    
}

- (void)viewWillAppear:(BOOL)animated
{    

}

// pressing button changes modes
- (void)buttonPress:(id)sender
{
    if ([currentMode isEqual:@"workReady"])
    {
        [self changeModes:@"workRunning"];
        [self startMusic];
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
            
//            [TSMessage showNotificationInViewController:self
//                                              withTitle:@"Feel relaxed?"
//                                            withMessage:@"Good. Time to crush some more work."
//                                               withType:TSMessageNotificationTypeMessage
//                                           withDuration:5.0
//                                           withCallback:^{
//                                               // user dismissed callback
//                                           }];
            
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
            [self addWork];
            [workCount setText:[NSString stringWithFormat:@"Crushed: %d",workUnitsCompleted]];
            
//            [TSMessage showNotificationInViewController:self
//                                              withTitle:@"Good work!"
//                                            withMessage:@"You crushed it. Now do something relaxing."
//                                               withType:TSMessageNotificationTypeMessage
//                                           withDuration:5.0
//                                           withCallback:^{
//                                               // user dismissed callback
//                                           }];
            [self stopMusic];
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

- (void)startMusic
{
    MPMusicPlayerController *player = [MPMusicPlayerController iPodMusicPlayer];
    MPMediaQuery *query = [[MPMediaQuery alloc] init];
    [query setGroupingType:MPMediaGroupingPlaylist];
    NSArray *collection = [query collections];
    [player setQueueWithItemCollection:collection[3]];
    [player setShuffleMode:(MPMusicShuffleModeSongs)];
    [player play];
    NSLog(@"%@",collection);
    NSLog(@"music should be playing");
}

- (void)stopMusic
{
    [[MPMusicPlayerController iPodMusicPlayer] pause];
    NSLog(@"music should be paused");
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
    for(UIView *subview in [self.view subviews]) {
        if([subview isKindOfClass:[CrushWorkTaskListItem class]])
        {
            [subview removeFromSuperview];
        }
    }
    tasksOnScreen = 0;
    taskLabels = [[NSMutableArray alloc] init];
}

// adds a new task and moves other tasks down
- (void)nextTask
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
                          duration:0.5
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
                      duration:1.0
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
         
         [self.view addSubview:taskLabel];
     }
                    completion:^(BOOL finished)
                    {
                        if(item.completed)
                        {
                            [self nextTask];
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
    [self nextTask];    
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

//  The function:
- (void)vibrate {
    AudioServicesPlaySystemSound (kSystemSoundID_Vibrate);
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

// utility method for creating the contextual cues
-(UILabel*) createCueLabel {
    UILabel* label = [[UILabel alloc] initWithFrame:CGRectNull];
    label.textColor = [UIColor whiteColor];
    label.font = [UIFont boldSystemFontOfSize:32.0];
    label.backgroundColor = [UIColor clearColor];
    return label;
}


-(BOOL)gestureRecognizerShouldBegin:(id)gestureRecognizer
{
    if(gestureRecognizer == panRecognizer)
    {
        UIPanGestureRecognizer *recognizer = (UIPanGestureRecognizer *)gestureRecognizer;
        CGPoint translation = [recognizer translationInView:[self view]];
        // Check for horizontal gesture
        
        if (fabsf(translation.x) > fabsf(translation.y)) {
            return YES;
        }
        else return NO;
    }
    else return NO;
}

-(void)handlePan:(id)gestureRecognizer
{
    if(gestureRecognizer == panRecognizer)
    {
        UIPanGestureRecognizer *recognizer = (UIPanGestureRecognizer *)gestureRecognizer;
        
        // 1
        if (recognizer.state == UIGestureRecognizerStateBegan) {
            // if the gesture has just started, record the current centre location
            _originalCenter = self.view.center;
        }
        
        // 2
        if (recognizer.state == UIGestureRecognizerStateChanged) {
            // translate the center
            CGPoint translation = [recognizer translationInView:self.view];
            self.view.center = CGPointMake(_originalCenter.x + translation.x, _originalCenter.y);
            // determine whether the item has been dragged far enough to initiate a delete / complete
            _nextOnDragRelease = self.view.frame.origin.x < -self.view.frame.size.width / 2;
            _completeOnDragRelease = self.view.frame.origin.x < -self.view.frame.size.width / 4 && !_nextOnDragRelease;
            
            // fade the contextual cues
            float cueAlpha = fabsf(self.view.frame.origin.x) / (self.view.frame.size.width / 2);
            
            // indicate when the item have been pulled far enough to invoke the given action
            if(_completeOnDragRelease)
            {
                _tickLabel.image = [[UIImage imageNamed:@"check.png"] imageWithOverlayColor:[UIColor greenColor]];
                _tickLabel.alpha = 1.0;
            }
            else
            {
                _tickLabel.image = [[UIImage imageNamed:@"check.png"] imageWithOverlayColor:[UIColor whiteColor]];
                _tickLabel.alpha = cueAlpha;
            }
            if(_nextOnDragRelease)
            {
                _crossLabel.image = [[UIImage imageNamed:@"next.png"] imageWithOverlayColor:[UIColor whiteColor]];
                _crossLabel.alpha = cueAlpha;
                _tickLabel.alpha = 0.0;
            }
            else
            {
                _crossLabel.image = [[UIImage imageNamed:@"next.png"] imageWithOverlayColor:[UIColor whiteColor]];
                _crossLabel.alpha = 0.0;
            }
        }
        
        // 3
        if (recognizer.state == UIGestureRecognizerStateEnded) {
            // the frame this cell would have had before being dragged
            CGRect originalFrame = CGRectMake(0, self.view.frame.origin.y,
                                              self.view.bounds.size.width, self.view.bounds.size.height);
            if (!_nextOnDragRelease) {

            }
            if (_nextOnDragRelease) {
                // notify the delegate that this item should be deleted
                [self nextTask];
            }
            
            if (_completeOnDragRelease) {
                // mark the item as complete and update the UI state
                [self completeTask];
            }
            
            [UIView animateWithDuration:0.2
                             animations:^{
                                 self.view.frame = originalFrame;
                             }
             ];
        }
    }
}


@end
