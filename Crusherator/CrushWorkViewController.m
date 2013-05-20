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
#import "CrushTimer.h"

@interface CrushWorkViewController ()
{
    // the timer
    CrushTimer *timer;
    NSInteger listIndex;
    
    // Gesture variables
    UIPanGestureRecognizer *panRecognizer;
    UITapGestureRecognizer *tapRecognizer;
    CGPoint _originalCenter;
    BOOL _completeOnDragRelease;
    BOOL _nextOnDragRelease;
    BOOL _pauseOnDragRelease;
    BOOL _stopOnDragRelease;
    UIImageView *_tickLabel;
	UIImageView *_crossLabel;
    
    // Options that will be changeable by the user in the future
    BOOL continuousMode;
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
}

@end

@implementation CrushWorkViewController

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
        
        self.title = NSLocalizedString(@"Work", @"Work");
        self.tabBarItem.image = [UIImage imageNamed:@"first"];
        
        continuousMode = FALSE;
        
        panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
        [self.view addGestureRecognizer:panRecognizer];
        
        tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(buttonPress)];
        [timer addGestureRecognizer:tapRecognizer];
        
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

- (void)scheduleAlarmForDate:(NSDate*)theDate withMessage:(NSString*)message
{
    UIApplication* app = [UIApplication sharedApplication];
    NSArray* oldNotifications = [app scheduledLocalNotifications];

    // Clear out the old notification before scheduling a new one.
    if ([oldNotifications count] > 0)
        [app cancelAllLocalNotifications];

    // Create a new notification.
    UILocalNotification* alarm = [[UILocalNotification alloc] init];
    if (alarm)
    {
        alarm.fireDate = theDate;
        alarm.timeZone = [NSTimeZone defaultTimeZone];
        alarm.repeatInterval = 0;
        alarm.soundName = @"boxing-bell.wav";
        alarm.alertBody = message;
        [app scheduleLocalNotification:alarm];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [self.view setNeedsDisplay];
    listIndex = (int) [[NSUserDefaults standardUserDefaults] floatForKey:@"listIndex"];
    NSLog(@"work view loaded with index %i",listIndex);
    
    [timer clearTasks];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    timer = [[CrushTimer alloc] initWithFrame:self.view.frame];
    [self.view addSubview:timer];
        
// initiate the timer
    [timer changeModes:@"workReady"];
    UIBackgroundTaskIdentifier bgTask =0;
    UIApplication  *app = [UIApplication sharedApplication];
    bgTask = [app beginBackgroundTaskWithExpirationHandler:^{
        [app endBackgroundTask:bgTask];
    }];
    
    [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(incrementTimer) userInfo:nil repeats:YES];
    
}

- (void)moveToBackground
{
        [self scheduleAlarmForDate:[NSDate dateWithTimeInterval:timer.timeLeft sinceDate:[NSDate date]] withMessage:@"Session over."];
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        [userDefaults setObject:[NSDate date]
                        forKey:@"timeBackgrounded"];
        [userDefaults synchronize];
        
        [userDefaults setObject:timer.currentMode
                         forKey:@"modeBackgrounded"];
        NSLog(@"modeBackgrounded is %@",timer.currentMode);
        [userDefaults synchronize];
        
        [userDefaults setInteger:timer.elapsedTime
                         forKey:@"timeElapsedWhenBackgrounded"];
        [userDefaults synchronize];
        
        [userDefaults setInteger:timer.timeLeft
                         forKey:@"timeLeftWhenBackgrounded"];
        [userDefaults synchronize];
        
        timer.running = FALSE;
}

- (void)moveToForeground
{
    NSDate *timeBackgrounded = [[NSUserDefaults standardUserDefaults] objectForKey:@"timeBackgrounded"];
    NSString *modeBackgrounded = [[NSUserDefaults standardUserDefaults] objectForKey:@"modeBackgrounded"];
    NSLog(@"modeBackgrounded is %@",timer.currentMode);
    NSTimeInterval timeElapsedWhenBackgrounded = [[NSUserDefaults standardUserDefaults] integerForKey:@"timeElapsedWhenBackgrounded"];
    NSTimeInterval timeLeftWhenBackgrounded = [[NSUserDefaults standardUserDefaults] integerForKey:@"timeLeftWhenBackgrounded"];
    double timePassed = [[NSDate date] timeIntervalSinceDate:timeBackgrounded];
    
    [timer changeModes:modeBackgrounded];
    
    if([modeBackgrounded isEqual:@"workRunning"] || [modeBackgrounded isEqual:@"playRunning"])
    {
        timer.elapsedTime = timeElapsedWhenBackgrounded;
        if(continuousMode)
        {
            // continuous mode handling
        }
        else
        {
            if (timePassed<timeLeftWhenBackgrounded) timer.elapsedTime += timePassed;
            else timer.elapsedTime += timeLeftWhenBackgrounded;
        }
        timer.running = TRUE;
    }
    else return;
}

// pressing button changes modes
- (void)buttonPress
{
    if ([timer.currentMode isEqual:@"workReady"])
    {
        [timer changeModes:@"workRunning"];
        [self startMusic];
    }
    else if ([timer.currentMode isEqual:@"workRunning"])
    {
        [timer changeModes:@"workPaused"];
        [self stopMusic];
    }
    else if ([timer.currentMode isEqual:@"workPaused"])
    {
        [timer changeModes:@"workRunning"];
        [self scheduleAlarmForDate:[NSDate dateWithTimeInterval:timer.timeLeft sinceDate:[NSDate date]] withMessage:@"Session over. Do something relaxing!"];
        [self startMusic];
    }
    else if ([timer.currentMode isEqual:@"playReady"])
    {
        [timer changeModes:@"playRunning"];
        [self scheduleAlarmForDate:[NSDate dateWithTimeInterval:timer.timeLeft sinceDate:[NSDate date]] withMessage:@"Relaxed? Great. It's time to work!"];
        [self stopMusic];
    }
    else if ([timer.currentMode isEqual:@"playRunning"])
    {
        [timer changeModes:@"playPaused"];
        [self stopMusic];
    }
    else if ([timer.currentMode isEqual:@"playPaused"])
    {
        [timer changeModes:@"playRunning"];
        [self stopMusic];
    }
}

// timer increments (only when running) and changes modes if it hits zero
- (void)incrementTimer
{
    if (timer.running)
    {
        timer.elapsedTime++;
        [timer updateLabels];
        if((timer.timeLeft<=0) && ([timer.currentMode isEqualToString:@"workRunning"]))
        {
            [timer changeModes:@"playReady"];
            if(continuousMode) [timer changeModes:@"playRunning"];
            if(buzzEndPlay)[self vibrate];
            [self stopMusic];
            workUnitsCompleted++;
        }
        else if((timer.timeLeft<=0) && ([timer.currentMode isEqualToString:@"playRunning"]))
        {
            [timer changeModes:@"workReady"];
            if(continuousMode) [timer changeModes:@"workRunning"];
            if(buzzEndWork)[self vibrate];
            relaxUnitsCompleted++;
        }
    }
}

- (void)startMusic
{
    MPMusicPlayerController *player = [MPMusicPlayerController iPodMusicPlayer];
    MPMediaQuery *query = [[MPMediaQuery alloc] init];
    [query setGroupingType:MPMediaGroupingPlaylist];
    NSArray *collection = [query collections];
//    if(collection[3]) [player setQueueWithItemCollection:collection[3]];
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

- (void)vibrate
{
    AudioServicesPlaySystemSound (kSystemSoundID_Vibrate);
    NSString *path = [NSString stringWithFormat:@"%@%@", [[NSBundle mainBundle] resourcePath], @"/boxing-bell.wav"];
    SystemSoundID soundID;
    NSURL *filePath = [NSURL fileURLWithPath:path isDirectory:NO];
    
    //Use audio sevices to create the sound
    AudioServicesCreateSystemSoundID((__bridge CFURLRef)filePath, &soundID);
    
    //Use audio services to play the sound
    
    AudioServicesPlaySystemSound(soundID);
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

// utility method for creating the contextual cues
-(UILabel*) createCueLabel
{
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
                [timer nextTaskWithAnimationDuration:0.5];
            }
            
            if (_completeOnDragRelease) {
                // mark the item as complete and update the UI state
                [timer completeTask];
                tasksCompleted++;
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
