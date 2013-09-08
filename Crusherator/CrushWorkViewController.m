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
    CrushTimer *_timer;
    NSInteger _listIndex;
    
    // Gesture variables
    UIPanGestureRecognizer *_panRecognizer;
    UITapGestureRecognizer *_tapRecognizer;
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
        
        // adjust settings
        continuousMode = FALSE;
        _listIndex = (int) [[NSUserDefaults standardUserDefaults] floatForKey:@"listIndex"];
        [self addGestureRecognizers];
        [self layoutTimer];
        [self reloadState];
        
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)viewDidAppear:(BOOL)animated
{
    if((int) [[NSUserDefaults standardUserDefaults] floatForKey:@"listIndex"] != _listIndex) [_timer clearTasks];
    _listIndex = (int) [[NSUserDefaults standardUserDefaults] floatForKey:@"listIndex"];
}

- (void)addGestureRecognizers
{
    // add gesture objects
    _panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    [self.view addGestureRecognizer:_panRecognizer];
    _tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(buttonPress)];
    [self.view addGestureRecognizer:_tapRecognizer];
    
    // add gesture icons
    UIImage *check = [[UIImage imageNamed:@"check.png"] imageWithOverlayColor:[UIColor grayColor]];
    _tickLabel = [[UIImageView alloc] initWithImage:check];
    [self.view addSubview:_tickLabel];
    UIImage *next = [[UIImage imageNamed:@"next.png"] imageWithOverlayColor:[UIColor grayColor]];
    _crossLabel = [[UIImageView alloc] initWithImage:next];
    [self.view addSubview:_crossLabel];
    
    // layout gesture icons
    _tickLabel.frame = CGRectMake(0,0,50.0,50.0);
    _tickLabel.center = CGPointMake(self.view.center.x + self.view.frame.size.width/2 + 50.0, self.view.center.y);
    _crossLabel.frame = CGRectMake(0,0,50.0,50.0);
    _crossLabel.center = CGPointMake(self.view.center.x + self.view.frame.size.width/2 + 50.0, self.view.center.y);
}

- (void)scheduleAlarmForDate:(NSDate*)date withMessage:(NSString*)message
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
        alarm.fireDate = date;
        alarm.timeZone = [NSTimeZone defaultTimeZone];
        alarm.repeatInterval = 0;
        alarm.soundName = @"boxing-bell.wav";
        alarm.alertBody = message;
        [app scheduleLocalNotification:alarm];
    }
}

- (void)layoutTimer
{
    // instantiate timer object
    UIBackgroundTaskIdentifier bgTask =0;
    UIApplication  *app = [UIApplication sharedApplication];
    bgTask = [app beginBackgroundTaskWithExpirationHandler:^{
        [app endBackgroundTask:bgTask];
    }];
    [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(incrementTimer) userInfo:nil repeats:YES];
    
    // instantiate timer
    _timer = [[CrushTimer alloc] initWithFrame:CGRectMake(0,0,self.view.frame.size.width,self.view.frame.size.height)];
    [_timer clearTasks];
    [self.view addSubview:_timer];
    [_timer changeModes:@"workReady"];
}

- (void)saveState
{
        if (_timer.running && [_timer.currentMode isEqualToString:@"workRunning"])[self scheduleAlarmForDate:[NSDate dateWithTimeInterval:_timer.timeLeft sinceDate:[NSDate date]] withMessage:@"Work is over. Time to rest!"];
        if (_timer.running && [_timer.currentMode isEqualToString:@"playRunning"])[self scheduleAlarmForDate:[NSDate dateWithTimeInterval:_timer.timeLeft sinceDate:[NSDate date]] withMessage:@"Alright buddy. Back to work!"];
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        [userDefaults setObject:[NSDate date]
                        forKey:@"timeBackgrounded"];
        [userDefaults synchronize];
        
        [userDefaults setObject:_timer.currentMode
                         forKey:@"modeBackgrounded"];
        NSLog(@"modeBackgrounded is %@",_timer.currentMode);
        [userDefaults synchronize];
        
        [userDefaults setInteger:_timer.elapsedTime
                         forKey:@"timeElapsedWhenBackgrounded"];
        [userDefaults synchronize];
        
        [userDefaults setInteger:_timer.timeLeft
                         forKey:@"timeLeftWhenBackgrounded"];
        [userDefaults synchronize];
        
        _timer.running = FALSE;
}

- (void)reloadState
{
    NSDate *timeBackgrounded = [[NSUserDefaults standardUserDefaults] objectForKey:@"timeBackgrounded"];
    NSString *modeBackgrounded = [[NSUserDefaults standardUserDefaults] objectForKey:@"modeBackgrounded"];
    NSLog(@"modeBackgrounded is %@",_timer.currentMode);
    NSTimeInterval timeElapsedWhenBackgrounded = [[NSUserDefaults standardUserDefaults] integerForKey:@"timeElapsedWhenBackgrounded"];
    NSTimeInterval timeLeftWhenBackgrounded = [[NSUserDefaults standardUserDefaults] integerForKey:@"timeLeftWhenBackgrounded"];
    double timePassed = [[NSDate date] timeIntervalSinceDate:timeBackgrounded];
    
    [_timer changeModes:modeBackgrounded];
    
    if([modeBackgrounded isEqual:@"workRunning"] || [modeBackgrounded isEqual:@"playRunning"])
    {
        _timer.elapsedTime = timeElapsedWhenBackgrounded;
        _timer.timeLeft = timeLeftWhenBackgrounded;
        if(continuousMode)
        {
            // continuous mode handling
        }
        else
        {
            if (timePassed<timeLeftWhenBackgrounded) _timer.elapsedTime += timePassed;
            else _timer.elapsedTime += timeLeftWhenBackgrounded;
        }
        _timer.running = TRUE;
    }
    else return;
}

// pressing button changes modes
- (void)buttonPress
{
    NSLog(@"tapped");
    if ([_timer.currentMode isEqual:@"workReady"])
    {
        [_timer changeModes:@"workRunning"];
        [self startMusic];
    }
    else if ([_timer.currentMode isEqual:@"workRunning"])
    {
        [_timer changeModes:@"workPaused"];
        [self stopMusic];
    }
    else if ([_timer.currentMode isEqual:@"workPaused"])
    {
        [_timer changeModes:@"workRunning"];
        [self scheduleAlarmForDate:[NSDate dateWithTimeInterval:_timer.timeLeft sinceDate:[NSDate date]] withMessage:@"Session over. Do something relaxing!"];
        [self startMusic];
    }
    else if ([_timer.currentMode isEqual:@"playReady"])
    {
        [_timer changeModes:@"playRunning"];
        [self scheduleAlarmForDate:[NSDate dateWithTimeInterval:_timer.timeLeft sinceDate:[NSDate date]] withMessage:@"Relaxed? Great. It's time to work!"];
        [self stopMusic];
    }
    else if ([_timer.currentMode isEqual:@"playRunning"])
    {
        [_timer changeModes:@"playPaused"];
        [self stopMusic];
    }
    else if ([_timer.currentMode isEqual:@"playPaused"])
    {
        [_timer changeModes:@"playRunning"];
        [self stopMusic];
    }
}

// timer increments (only when running) and changes modes if it hits zero
- (void)incrementTimer
{
    if (_timer.running)
    {
        _timer.elapsedTime++;
        [_timer updateLabels];
        if((_timer.timeLeft<=0) && ([_timer.currentMode isEqualToString:@"workRunning"]))
        {
            [_timer changeModes:@"playReady"];
            if(continuousMode) [_timer changeModes:@"playRunning"];
            if(buzzEndPlay)[self vibrate];
            [self stopMusic];
            workUnitsCompleted++;
        }
        else if((_timer.timeLeft<=0) && ([_timer.currentMode isEqualToString:@"playRunning"]))
        {
            [_timer changeModes:@"workReady"];
            if(continuousMode) [_timer changeModes:@"workRunning"];
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
    
    for (MPMediaPlaylist *playlist in collection)
    {
        NSLog([playlist valueForProperty:MPMediaPlaylistPropertyName]);
    }
    
    if(collection[3]) [player setQueueWithItemCollection:collection[3]];
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
    if(gestureRecognizer == _panRecognizer)
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
    if(gestureRecognizer == _panRecognizer)
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
            self.view.center = CGPointMake(_originalCenter.x + translation.x*1/2, _originalCenter.y);
            // determine whether the item has been dragged far enough to initiate a delete / complete
            _nextOnDragRelease = translation.x < -self.view.frame.size.width / 2;
            _completeOnDragRelease = translation.x < -self.view.frame.size.width / 4 && !_nextOnDragRelease;
            
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
                [_timer nextTaskWithAnimationDuration:0.5];
            }
            
            if (_completeOnDragRelease) {
                // mark the item as complete and update the UI state
                [_timer completeTask];
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

- (BOOL)shouldAutorotate

{
    return NO;
}

UIDeviceOrientation currentOrientation;

- (void)deviceOrientationDidChange:(NSNotification *)notification {
    //Obtaining the current device orientation
    UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
    
    //Ignoring specific orientations
    if (orientation == UIDeviceOrientationFaceUp || orientation == UIDeviceOrientationFaceDown || orientation == UIDeviceOrientationUnknown || currentOrientation == orientation) {
        return;
    }
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(relayoutLayers) object:nil];
    //Responding only to changes in landscape or portrait
    currentOrientation = orientation;
    //
//    [self performSelector:@selector(orientationChangedMethod) withObject:nil afterDelay:0];
}

@end
