//
//  CrushCell.m
//  Crusherator
//
//  Created by Raj on 4/13/13.
//  Copyright (c) 2013 Raj. All rights reserved.
//

#import "CrushListTableViewCell.h"
#import "CrushStrikeLabel.h"
#import "CrushTaskObject.h"
#import <QuartzCore/QuartzCore.h>
#import "UIImage+CrushImage.h"

@implementation CrushListTableViewCell
{
    CAGradientLayer* _gradientLayer;
    CGPoint _originalCenter;
	BOOL _deleteOnDragRelease;
	BOOL _completeOnDragRelease;
    BOOL _estimateWorksOnDragRelease;
    int _estimatedWorks;
	CALayer *_itemCompleteLayer;
    UIImageView *_tickLabel;
	UIImageView *_crossLabel;
    UILabel *_worksLabel;
    UIFont *fontDialogStrong;
    UIFont *fontDialogHuge;
    BOOL _isBeingEdited;
    BOOL _gestureInProgress;
    CGFloat _scrollingRate;
    CGFloat _indexChanged;
    UIPanGestureRecognizer *panRecognizer;
    UILongPressGestureRecognizer *longRecognizer;
    CGPoint _beginningLocation;
    NSTimer *movingTimer;
}

#define CELL_SNAPSHOT_TAG 100000

const float UI_CUES_MARGIN = 10.0f;
const float UI_CUES_WIDTH = 50.0f;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        fontDialogStrong = [UIFont fontWithName:@"Gotham Medium" size:15.0];
        fontDialogHuge = [UIFont fontWithName:@"Gotham Medium" size:25.0];
        
        // add a tick and cross
        UIImage *check = [[UIImage imageNamed:@"check.png"] imageWithOverlayColor:[UIColor grayColor]];
        _tickLabel = [[UIImageView alloc] initWithImage:check];
        [self addSubview:_tickLabel];
        
        UIImage *next = [[UIImage imageNamed:@"next.png"] imageWithOverlayColor:[UIColor grayColor]];
        _crossLabel = [[UIImageView alloc] initWithImage:next];
        [self addSubview:_crossLabel];
        
        _worksLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _worksLabel.font = fontDialogHuge;
        [self addSubview:_worksLabel];
        
        // add a layer that overlays the cell adding a subtle gradient effect
        _gradientLayer = [CAGradientLayer layer];
        _gradientLayer.frame = self.bounds;
        _gradientLayer.colors = @[(id)[[UIColor colorWithWhite:1.0f alpha:0.2f] CGColor],
                                  (id)[[UIColor colorWithWhite:1.0f alpha:0.1f] CGColor],
                                  (id)[[UIColor clearColor] CGColor],
                                  (id)[[UIColor colorWithWhite:0.0f alpha:0.1f] CGColor]];
        _gradientLayer.locations = @[@0.00f, @0.01f, @0.95f, @1.00f];
        [self.layer insertSublayer:_gradientLayer atIndex:0];
        
        // add a layer that renders a green background when an item is complete
        _itemCompleteLayer = [CALayer layer];
        _itemCompleteLayer.backgroundColor = [[[UIColor alloc] initWithRed:0.0 green:0.6 blue:0.0 alpha:1.0] CGColor];
        _itemCompleteLayer.hidden = YES;
        [self.layer insertSublayer:_itemCompleteLayer atIndex:0];
        
        panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
        panRecognizer.delegate = self;
        [self addGestureRecognizer:panRecognizer];
        
        longRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
        longRecognizer.delegate = self;
        [longRecognizer setMinimumPressDuration:0.3];
        [self addGestureRecognizer:longRecognizer];
        
        // create a label that renders the to-do item text
        _label = [[CrushStrikeLabel alloc] initWithFrame:CGRectNull];
        _label.offset = -2.0;
        _label.textColor = [UIColor whiteColor];
        _label.font = fontDialogStrong;
        _label.backgroundColor = [UIColor clearColor];
        _label.layer.shadowColor = [UIColor blackColor].CGColor;
        _label.layer.shadowOffset = CGSizeMake(0.5,0.5);
        _label.layer.shadowOpacity = 0.7;
        _label.layer.shadowRadius = 0.5;
        _label.clipsToBounds = NO;
        [self addSubview:_label];

        // create a label that renders the to-do item text
        _estimatedWorksLabel = [[CrushStrikeLabel alloc] initWithFrame:CGRectNull];
        _estimatedWorksLabel.textColor = [UIColor blackColor];
        _estimatedWorksLabel.font = fontDialogStrong;
        _estimatedWorksLabel.text = @"";
        _estimatedWorksLabel.backgroundColor = [UIColor clearColor];
        _estimatedWorksLabel.textAlignment = NSTextAlignmentRight;
        _estimatedWorksLabel.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
        _estimatedWorksLabel.enabled = NO;
        _estimatedWorksLabel.alpha = 0.3;
        [self addSubview:_estimatedWorksLabel];
        
        // create a label that renders the to-do item work count
        _workLabel = [[CrushStrikeLabel alloc] initWithFrame:CGRectNull];
        _workLabel.textColor = [UIColor whiteColor];
        _workLabel.font = fontDialogStrong;
        _workLabel.text = @"";
        _workLabel.backgroundColor = [UIColor clearColor];
        _workLabel.textAlignment = NSTextAlignmentRight;
        _workLabel.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
        _workLabel.enabled = NO;
        _workLabel.layer.shadowColor = [UIColor blackColor].CGColor;
        _workLabel.layer.shadowOffset = CGSizeMake(0.5,0.5);
        _workLabel.layer.shadowOpacity = 0.7;
        _workLabel.layer.shadowRadius = 0.5;
        _workLabel.clipsToBounds = NO;
        [self addSubview:_workLabel];
        
        _label.delegate = self;
        _label.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
        self.isBeingEdited = NO;
        
        // remove the default blue highlight for selected cells
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
    }
    return self;
}

const float LABEL_LEFT_MARGIN = 10.0f;
const float LABEL_RIGHT_MARGIN = 10.0f;

-(void)layoutSubviews
{
    [super layoutSubviews];
    // ensure the gradient layers occupies the full bounds
    _gradientLayer.frame = self.bounds;
    _itemCompleteLayer.frame = self.bounds;
    _label.frame = CGRectMake(LABEL_LEFT_MARGIN, 0,
                              self.bounds.size.width - LABEL_LEFT_MARGIN,self.bounds.size.height);
    
    _workLabel.frame = CGRectMake(LABEL_LEFT_MARGIN, 0,
                              self.bounds.size.width - LABEL_LEFT_MARGIN*2,self.bounds.size.height);
    _estimatedWorksLabel.frame = CGRectMake(LABEL_LEFT_MARGIN, 0,
                                  self.bounds.size.width - LABEL_LEFT_MARGIN*2,self.bounds.size.height);
    
    // ensure the gradient layers occupies the full bounds
    _tickLabel.frame = CGRectMake(0,0,30.0,30.0);
    _tickLabel.center = CGPointMake(self.center.x + self.frame.size.width/2 + 30.0, self.frame.size.height/2);
    _crossLabel.frame = CGRectMake(0,0,30.0,30.0);
    _crossLabel.center = CGPointMake(self.center.x + self.frame.size.width/2 + 30.0, self.frame.size.height/2);
    _worksLabel.frame = CGRectMake(0,0,100.0,30.0);
    _worksLabel.center = CGPointMake(self.center.x - self.frame.size.width/2 - 60.0, self.frame.size.height/2);
    _worksLabel.textColor = [UIColor whiteColor];
    _worksLabel.backgroundColor = [UIColor clearColor];
    _worksLabel.textAlignment = NSTextAlignmentRight;
}

-(void)setToDoItem:(CrushTaskObject *)todoItem
{
    _toDoItem = todoItem;
    // we must update all the visual state associated with the model item
    _label.text = todoItem.text;
    for(int i=0;i<=(todoItem.works);i++)
    {
        _workLabel.text = [@"" stringByPaddingToLength:todoItem.works withString:@"|" startingAtIndex:0];
    }
    for(int i=0;i<=(todoItem.estimatedWorks);i++)
    {
        _estimatedWorksLabel.text = [@"" stringByPaddingToLength:todoItem.estimatedWorks withString:@"|" startingAtIndex:0];
    }
    _label.strikethrough = todoItem.completed;
    _label.strikethroughThickness = 2.0;
    _itemCompleteLayer.hidden = !todoItem.completed;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

#pragma mark - horizontal pan gesture methods
-(BOOL)gestureRecognizerShouldBegin:(id)gestureRecognizer
{
    if(gestureRecognizer == panRecognizer)
    {
        UIPanGestureRecognizer *recognizer = (UIPanGestureRecognizer *)gestureRecognizer;
        CGPoint translation = [recognizer translationInView:[self superview]];
        CGPoint location = [recognizer locationInView:[self superview]];
        // Check for horizontal gesture
        
        if (fabsf(translation.x) > fabsf(translation.y)) {
            if(fabsf(location.x)<=40 || fabsf(location.x)>=(self.frame.size.width-40))
            {
                [self handlePan:gestureRecognizer];
                return NO;
            }
            return YES;
        }
    else return NO;
    }
    
    if(gestureRecognizer == longRecognizer)
    {
        _gestureInProgress = YES;
        return YES;
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
            _originalCenter = self.center;
        }
        
        // 2
        if (recognizer.state == UIGestureRecognizerStateChanged) {
            // translate the center
            CGPoint translation = [recognizer translationInView:self];
            self.center = CGPointMake(_originalCenter.x + translation.x, _originalCenter.y);
            
            // determine whether the item has been dragged far enough to initiate a delete / complete
            _deleteOnDragRelease = self.frame.origin.x < -self.frame.size.width / 2;
            _completeOnDragRelease = self.frame.origin.x < -self.frame.size.width / 4 && !_deleteOnDragRelease;
            _estimateWorksOnDragRelease = self.frame.origin.x > self.frame.size.width / 10;
            _estimatedWorks = (int) self.frame.origin.x / (self.frame.size.width / 10);
            
            // fade the contextual cues
            float cueAlpha = fabsf(self.frame.origin.x) / (self.frame.size.width / 2);
            
            // indicate when the item have been pulled far enough to invoke the given action
            if(_completeOnDragRelease)
            {
                UIColor *color;
                if(self.toDoItem.completed) color = [UIColor redColor];
                if(!self.toDoItem.completed) color = [UIColor greenColor];
                _tickLabel.image = [[UIImage imageNamed:@"check.png"] imageWithOverlayColor:color];
                _tickLabel.alpha = 1.0;
            }
            else
            {
                _tickLabel.image = [[UIImage imageNamed:@"check.png"] imageWithOverlayColor:[UIColor whiteColor]];
                _tickLabel.alpha = cueAlpha;
            }
            if(_deleteOnDragRelease)
            {
                _crossLabel.image = [[UIImage imageNamed:@"cross.png"] imageWithOverlayColor:[UIColor redColor]];
                _crossLabel.alpha = cueAlpha;
                _tickLabel.alpha = 0.0;
            }
            else
            {
                _crossLabel.image = [[UIImage imageNamed:@"cross.png"] imageWithOverlayColor:[UIColor whiteColor]];
                _crossLabel.alpha = 0.0;
            }
            if(_estimateWorksOnDragRelease)
            {
                for(int i=0;i<=(_estimatedWorks);i++)
                {
                    _worksLabel.text = [@"" stringByPaddingToLength:_estimatedWorks withString:@"|" startingAtIndex:0];
                }
                _worksLabel.alpha = cueAlpha;
            }
        }
        
        // 3
        if (recognizer.state == UIGestureRecognizerStateEnded) {
            // the frame this cell would have had before being dragged
            CGRect originalFrame = CGRectMake(0, self.frame.origin.y,
                                              self.bounds.size.width, self.bounds.size.height);
            if (!_deleteOnDragRelease) {
                // if the item is not being deleted, snap back to the original location
                [UIView animateWithDuration:0.2
                                 animations:^{
                                     self.frame = originalFrame;
                                 }
                 ];
            }
            if (_deleteOnDragRelease) {
                // notify the delegate that this item should be deleted
                [self.delegate toDoItemDeleted:self.toDoItem];
            }
            
            if (_completeOnDragRelease) {
                // mark the item as complete and update the UI state
                self.toDoItem.completed = !(self.toDoItem.completed);
                [self.toDoItem editInDatabase];
                _itemCompleteLayer.hidden = !_itemCompleteLayer.hidden;
                _label.strikethrough = !_label.strikethrough;
            }
            
            if (_estimateWorksOnDragRelease) {
                // mark the item as complete and update the UI state
                self.toDoItem.estimatedWorks = _estimatedWorks;
                for(int i=0;i<=(_toDoItem.estimatedWorks);i++)
                {
                    _estimatedWorksLabel.text = [@"" stringByPaddingToLength:_toDoItem.estimatedWorks withString:@"|" startingAtIndex:0];
                }
                [self.toDoItem editInDatabase];
                // change estimated works
            }
        }
    }
    
    if (gestureRecognizer == longRecognizer)
    {
        UILongPressGestureRecognizer *recognizer = (UILongPressGestureRecognizer *)gestureRecognizer;
        if (recognizer.state == UIGestureRecognizerStateBegan)
        {
            CrushListTableViewCell *cell = self;
            _beginningLocation = [recognizer locationInView:self.superview];
            UIGraphicsBeginImageContextWithOptions(cell.bounds.size, NO, 0);
            [cell.layer renderInContext:UIGraphicsGetCurrentContext()];
            UIImage *cellImage = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
            
            // We create an imageView for caching the cell snapshot here
            UIImageView *snapShotView = (UIImageView *)[cell viewWithTag:CELL_SNAPSHOT_TAG];
            if ( ! snapShotView) {
                snapShotView = [[UIImageView alloc] initWithImage:cellImage];
                snapShotView.tag = CELL_SNAPSHOT_TAG;
                [self.superview addSubview:snapShotView];
                CGRect rect = cell.frame;
                snapShotView.frame = CGRectOffset(snapShotView.bounds, rect.origin.x, rect.origin.y);
                snapShotView.layer.shadowColor = [UIColor blackColor].CGColor;
                snapShotView.layer.shadowOffset = CGSizeMake(0,0);
                snapShotView.layer.shadowOpacity = 0.7;
                snapShotView.layer.shadowRadius = 5.0;
                snapShotView.clipsToBounds = NO;
            }
            
            // Make a zoom in effect for the cell
            [UIView beginAnimations:@"zoomCell" context:nil];
            snapShotView.transform = CGAffineTransformMakeScale(1.1, 1.1);
            snapShotView.center = CGPointMake(self.superview.center.x, _beginningLocation.y);
            [UIView commitAnimations];
            [self.delegate cellIsBeingMoved:self];
        }
        
        if (recognizer.state == UIGestureRecognizerStateChanged)
        {
            // While our finger moves, we also moves the snapshot imageView
            UIImageView *snapShotView = (UIImageView *)[self.superview viewWithTag:CELL_SNAPSHOT_TAG];
            CGPoint currentLocation = [recognizer locationInView:self.superview];
            snapShotView.center = CGPointMake(self.superview.center.x, currentLocation.y);
                [self.delegate cellIsBeingDragged:self to:snapShotView.center];
        }
        if (recognizer.state == UIGestureRecognizerStateEnded)
        {   
            [self.delegate cellIsDoneBeingMoved:self];
        }
    }
    
    _gestureInProgress = NO;
}

-(void)dismissKeyboard
{
    [self.label resignFirstResponder];
}

#pragma mark - UITextFieldDelegate
-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
    // close the keyboard on enter
    [textField resignFirstResponder];
    return NO;
}

-(void)textFieldDidEndEditing:(UITextField *)textField
{
    [self.delegate cellDidEndEditing:self];
    self.toDoItem.text = textField.text;
    [self.toDoItem editInDatabase];
}

-(void)textFieldDidBeginEditing:(UITextField *)textField
{
    [self.delegate cellDidBeginEditing:self];
    [self.toDoItem editInDatabase];
}

-(BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    return [self.delegate cellShouldBeginEditing:self];
}

@end
