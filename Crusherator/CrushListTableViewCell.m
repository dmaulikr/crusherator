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

@implementation CrushListTableViewCell
{
    CAGradientLayer* _gradientLayer;
    CGPoint _originalCenter;
	BOOL _deleteOnDragRelease;
	BOOL _completeOnDragRelease;
	CALayer *_itemCompleteLayer;
    UILabel *_tickLabel;
	UILabel *_crossLabel;
    UIFont *fontDialogStrong;
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
        
        // add a tick and cross
        _tickLabel = [self createCueLabel];
        _tickLabel.text = @"\u2713";
        _tickLabel.textAlignment = NSTextAlignmentRight;
        [self addSubview:_tickLabel];
        _crossLabel = [self createCueLabel];
        _crossLabel.text = @"\u2717";
        _crossLabel.textAlignment = NSTextAlignmentLeft;
        [self addSubview:_crossLabel];
        
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
        [longRecognizer setMinimumPressDuration:0.5];
        [self addGestureRecognizer:longRecognizer];
        
        // create a label that renders the to-do item text
        _label = [[CrushStrikeLabel alloc] initWithFrame:CGRectNull];
        _label.offset = -2.0;
        _label.textColor = [UIColor blackColor];
        _label.font = fontDialogStrong;
        _label.backgroundColor = [UIColor clearColor];
        [_label addGestureRecognizer:longRecognizer];
        [self addSubview:_label];

        // create a label that renders the to-do item text
        _workLabel = [[CrushStrikeLabel alloc] initWithFrame:CGRectNull];
        _workLabel.textColor = [UIColor blackColor];
        _workLabel.font = fontDialogStrong;
        _workLabel.text = @"";
        _workLabel.backgroundColor = [UIColor clearColor];
        _workLabel.textAlignment = NSTextAlignmentRight;
        _workLabel.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
        _workLabel.enabled = NO;
        [self addSubview:_workLabel];

        
        _label.delegate = self;
        _label.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
        self.isBeingEdited = NO;
        
        // remove the default blue highlight for selected cells
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
    }
    return self;
}

// utility method for creating the contextual cues
-(UILabel*) createCueLabel {
    UILabel* label = [[UILabel alloc] initWithFrame:CGRectNull];
    label.textColor = [UIColor whiteColor];
    label.font = [UIFont boldSystemFontOfSize:32.0];
    label.backgroundColor = [UIColor clearColor];
    return label;
}

const float LABEL_LEFT_MARGIN = 15.0f;
const float LABEL_RIGHT_MARGIN = 15.0f;

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
    
    _tickLabel.frame = CGRectMake(-UI_CUES_WIDTH - UI_CUES_MARGIN, 0,
                                  UI_CUES_WIDTH, self.bounds.size.height);
    _crossLabel.frame = CGRectMake(self.bounds.size.width + UI_CUES_MARGIN, 0,
                                   UI_CUES_WIDTH, self.bounds.size.height);
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
        // Check for horizontal gesture
        if (fabsf(translation.x) > fabsf(translation.y)) {
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
            _completeOnDragRelease = self.frame.origin.x > self.frame.size.width / 2;
            
            // fade the contextual cues
            float cueAlpha = fabsf(self.frame.origin.x) / (self.frame.size.width / 2);
            _tickLabel.alpha = cueAlpha;
            _crossLabel.alpha = cueAlpha;
            
            // indicate when the item have been pulled far enough to invoke the given action
            _tickLabel.textColor = _completeOnDragRelease ?
            [UIColor greenColor] : [UIColor whiteColor];
            _crossLabel.textColor = _deleteOnDragRelease ?
            [UIColor redColor] : [UIColor whiteColor];
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
            }
            
            // Make a zoom in effect for the cell
            [UIView beginAnimations:@"zoomCell" context:nil];
            snapShotView.transform = CGAffineTransformMakeScale(1.1, 1.1);
            snapShotView.center = CGPointMake(self.superview.center.x, _beginningLocation.y);
            [UIView commitAnimations];
            [self.delegate cellIsBeingMoved:self];
            
//            [self.superview beginUpdates];
//            [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationNone];
//            [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationNone];
//            [self.delegate gestureRecognizer:self needsCreatePlaceholderForRowAtIndexPath:indexPath];
//            
//            self.addingIndexPath = indexPath;
//            
//            [self.tableView endUpdates];
            
            // Start timer to prepare for auto scrolling
//            movingTimer = [NSTimer timerWithTimeInterval:1/8 target:self selector:@selector(scrollTable) userInfo:nil repeats:YES];
//            [[NSRunLoop mainRunLoop] addTimer:movingTimer forMode:NSDefaultRunLoopMode];
        }
        
        if (recognizer.state == UIGestureRecognizerStateChanged)
        {
            // While our finger moves, we also moves the snapshot imageView
            UIImageView *snapShotView = (UIImageView *)[self.superview viewWithTag:CELL_SNAPSHOT_TAG];
            CGPoint currentLocation = [recognizer locationInView:self.superview];
            snapShotView.center = CGPointMake(self.superview.center.x, currentLocation.y);
                [self.delegate cellIsBeingDragged:self to:snapShotView.center];
//            location.y -= self.superview.contentOffset.y;       // We needed to compensate actual contentOffset.y to get the relative y position of touch.
            
//            [self updateAddingIndexPathForCurrentLocation];
            
//            CGFloat bottomDropZoneHeight = self.superview.bounds.size.height / 6;
//            CGFloat topDropZoneHeight    = bottomDropZoneHeight;
//            CGFloat bottomDiff = location.y - (rect.size.height - bottomDropZoneHeight);
//            if (bottomDiff > 0) {
//                _scrollingRate = bottomDiff / (bottomDropZoneHeight / 1);
//            } else if (location.y <= topDropZoneHeight) {
//                _scrollingRate = -(topDropZoneHeight - MAX(location.y, 0)) / bottomDropZoneHeight;
//            } else {
//                _scrollingRate = 0;
//            }
        }
        if (recognizer.state == UIGestureRecognizerStateEnded)
        {
            // While long press ends, we remove the snapshot imageView
            
            __block __weak UIImageView *snapShotView = (UIImageView *)[self.superview viewWithTag:CELL_SNAPSHOT_TAG];
//            __block __weak UILongPressGestureRecognizer *weakSelf = recognizer; //!!!
            
            // We use self.addingIndexPath directly to make sure we dropped on a valid indexPath
            // which we've already ensure while UIGestureRecognizerStateChanged
//            __block __weak NSIndexPath *indexPath = self.addingIndexPath;
            
            // Stop timer
//            [self.movingTimer invalidate]; self.movingTimer = nil;
//            self.scrollingRate = 0;
            
//            [UIView animateWithDuration:2.0
//                             animations:^{
//                                 CGRect rect = [self.superview rectForRowAtIndexPath:indexPath];
//                                 snapShotView.transform = CGAffineTransformIdentity;    // restore the transformed value
//                                 snapShotView.frame = CGRectOffset(snapShotView.bounds, rect.origin.x, rect.origin.y);
//                             } completion:^(BOOL finished) {
                                 [snapShotView removeFromSuperview];
//
//                                 [weakSelf.tableView beginUpdates];
//                                 [weakSelf.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationNone];
//                                 [weakSelf.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationNone];
//                                 [weakSelf.delegate gestureRecognizer:weakSelf needsReplacePlaceholderForRowAtIndexPath:indexPath];
//                                 [weakSelf.tableView endUpdates];
//                                 
//                                 [weakSelf.tableView reloadVisibleRowsExceptIndexPath:indexPath];
//                                 // Update state and clear instance variables
//                                 weakSelf.cellSnapshot = nil;
//                                 weakSelf.addingIndexPath = nil;
//                                 weakSelf.state = JTTableViewGestureRecognizerStateNone;
//                             }];
            
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
