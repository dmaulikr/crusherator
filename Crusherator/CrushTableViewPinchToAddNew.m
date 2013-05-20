//
//  CrushTableViewPinchToAddNew.m
//  Crusherator
//
//  Created by Raj on 4/29/13.
//  Copyright (c) 2013 Raj. All rights reserved.
//

#import "CrushTableViewPinchToAddNew.h"
#import "CrushListTableViewCell.h"

// represents the upper and lower points of a pinch
struct CrushTouchPoints {
    CGPoint upper;
    CGPoint lower;
};

typedef struct CrushTouchPoints CrushTouchPoints;

// the indices of the upper and lower cells that are being pinched
int _pointOneCellindex;
int _pointTwoCellindex;

// the location of the touch points when the pinch began
CrushTouchPoints _initialTouchPoints;

// indicates that the pinch is in progress
BOOL _pinchInProgress;

// indicates that the pinch was big enough to cause a new item to be added
BOOL _pinchExceededRequiredDistance;

@implementation CrushTableViewPinchToAddNew {
    CrushTableView * _tableView;
    CrushListTableViewCell *_placeholderCell;
}

-(id)initWithTableView:(CrushTableView*)tableView {
    self = [super init];
    if (self) {
        _placeholderCell = [[CrushListTableViewCell alloc] init];
        _placeholderCell.backgroundColor = [UIColor redColor];
        _tableView = tableView;
        // add a pinch recognizer
        UIGestureRecognizer* recognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinch:)];
        [_tableView addGestureRecognizer:recognizer];
    }
    return self;
}

-(void)handlePinch:(UIPinchGestureRecognizer *)recognizer {
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        [self pinchStarted:recognizer];
    }
    
    if (recognizer.state == UIGestureRecognizerStateChanged
        && _pinchInProgress
        && recognizer.numberOfTouches == 2) {
        [self pinchChanged:recognizer];
    }
    if (recognizer.state == UIGestureRecognizerStateEnded) {
        [self pinchEnded:recognizer];
    }
}

-(void)pinchChanged:(UIPinchGestureRecognizer *)recognizer {
    // find the touch points
    CrushTouchPoints currentTouchPoints = [self getNormalisedTouchPoints:recognizer];
    
    // determine by how much each touch point has changed, and take the minimum delta
    float upperDelta = currentTouchPoints.upper.y - _initialTouchPoints.upper.y;
    float lowerDelta = _initialTouchPoints.lower.y - currentTouchPoints.lower.y;
    float delta = -MIN(0, MIN(upperDelta, lowerDelta));
    
    // offset the cells, negative for the cells above, positive for those below
    NSArray* visibleCells = _tableView.visibleCells;
    for (int i=0; i < visibleCells.count; i++) {
        UIView* cell = (UIView*)visibleCells[i];
        if (i <= _pointOneCellindex) {
            cell.transform = CGAffineTransformMakeTranslation(0,  -delta);
        }
        if (i >= _pointTwoCellindex) {
            cell.transform = CGAffineTransformMakeTranslation(0, delta);
        }
    }
    // scale the placeholder cell
    float gapSize = delta * 2;
    float cappedGapSize = MIN(gapSize, SHC_ROW_HEIGHT);
    _placeholderCell.transform = CGAffineTransformMakeScale(1.0f, cappedGapSize / SHC_ROW_HEIGHT );
    
    _placeholderCell.label.text = gapSize > SHC_ROW_HEIGHT ?
    @"Release to Add Item" : @"Pull to Add Item";
    
    _placeholderCell.alpha = MIN(1.0f, gapSize / SHC_ROW_HEIGHT);
    
    // determine whether they have pinched far enough
    _pinchExceededRequiredDistance = gapSize > SHC_ROW_HEIGHT;
}

-(void) pinchStarted:(UIPinchGestureRecognizer *)recognizer {
    // find the touch-points
    _initialTouchPoints = [self getNormalisedTouchPoints:recognizer];
    
    // locate the cells that these points touch
    _pointOneCellindex = -100;
    _pointTwoCellindex = -100;
    NSArray* visibleCells = _tableView.visibleCells;
    for (int i=0; i < visibleCells.count; i++) {
        UIView* cell = (UIView*)visibleCells[i];
        if ([self viewContainsPoint:cell withPoint:_initialTouchPoints.upper]) {
            _pointOneCellindex = i;
            NSLog(@"first cell is %i",i);
        }
        if ([self viewContainsPoint:cell withPoint:_initialTouchPoints.lower]) {
            _pointTwoCellindex = i;
            NSLog(@"second cell is %i",i);
        }
    }
    
    // check whether they are neighbors
    if (abs(_pointOneCellindex - _pointTwoCellindex) == 1) {
        // if so - initiate the pinch
        _pinchInProgress = YES;
        _pinchExceededRequiredDistance = NO;
        
        // show your place-holder cell
        CrushListTableViewCell* precedingCell = (CrushListTableViewCell*)(_tableView.visibleCells)[_pointOneCellindex];
        _placeholderCell.frame = CGRectOffset(precedingCell.frame, 0.0f, SHC_ROW_HEIGHT / 2.0f);
        [_tableView.scrollView insertSubview:_placeholderCell atIndex:0];
        
    }
}

-(void)pinchEnded:(UIPinchGestureRecognizer *)recognizer {
    _pinchInProgress = false;
    
    // remove the placeholder cell
    _placeholderCell.transform = CGAffineTransformIdentity;
    [_placeholderCell removeFromSuperview];
    
    if (_pinchExceededRequiredDistance) {
        // add a new item
        int indexOffset = floor(_tableView.scrollView.contentOffset.y / SHC_ROW_HEIGHT);
        [_tableView.dataSource itemAddedAtIndex:_pointTwoCellindex + indexOffset];
        NSLog(@"item added at %i",_pointTwoCellindex + indexOffset);
    } else {
        // Otherwise animate back to position
        [UIView animateWithDuration:0.2f
                              delay:0.0f
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^{
                             NSArray* visibleCells = _tableView.visibleCells;
                             for(CrushListTableViewCell* cell in visibleCells)
                             {
                                 cell.transform = CGAffineTransformIdentity;
                             }
                         }
                         completion:nil];
    }
    
}

// returns the two touch points, ordering them to ensure that upper and lower
// are correctly identified.
-(CrushTouchPoints) getNormalisedTouchPoints:(UIGestureRecognizer*) recognizer {
    CGPoint pointOne = [recognizer locationOfTouch:0 inView:_tableView];
    CGPoint pointTwo = [recognizer locationOfTouch:1 inView:_tableView];
    // offset based on scroll
    pointOne.y += _tableView.scrollView.contentOffset.y;
    pointTwo.y += _tableView.scrollView.contentOffset.y;
    // ensure pointOne is the top-most
    if (pointOne.y > pointTwo.y) {
        CGPoint temp = pointOne;
        pointOne = pointTwo;
        pointTwo = temp;
    }
    CrushTouchPoints points = {pointOne, pointTwo};
    return points;
}

-(BOOL) viewContainsPoint:(UIView*)view withPoint:(CGPoint)point {
    CGRect frame = view.frame;
    return (frame.origin.y < point.y) && (frame.origin.y + frame.size.height) > point.y;
}

@end
