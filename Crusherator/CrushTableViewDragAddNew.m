//
//  CrushTableViewDragAddNew.m
//  Crusherator
//
//  Created by Raj on 4/14/13.
//  Copyright (c) 2013 Raj. All rights reserved.
//

#import "CrushTableViewDragAddNew.h"
#import "CrushListTableViewCell.h"

@implementation CrushTableViewDragAddNew
{
    // a cell that is rendered as a placeholder to indicate where a new item is added
    CrushListTableViewCell* _placeholderCell;
    
    // indicates the state of this behavior
    BOOL _pullDownInProgress;
}

-(id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        _placeholderCell = [[CrushListTableViewCell alloc] init];
        _placeholderCell.backgroundColor = [UIColor redColor];
    }
    return self;
}

#pragma mark - UIScrollViewDelegate
-(void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    // this behaviour starts when a user pulls down while at the top of the table
    _pullDownInProgress = scrollView.contentOffset.y <= 0.0f;
    if (_pullDownInProgress) {
        // add your placeholder
        [self insertSubview:_placeholderCell atIndex:0];
    }
}

-(void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [super scrollViewDidScroll:scrollView];
    
    if (_pullDownInProgress && self.scrollView.contentOffset.y <= 0.0f) {
        // maintain the location of the placeholder
        _placeholderCell.frame = CGRectMake(0, - self.scrollView.contentOffset.y - SHC_ROW_HEIGHT,
                                            self.frame.size.width, SHC_ROW_HEIGHT);
        _placeholderCell.label.text = -self.scrollView.contentOffset.y > SHC_ROW_HEIGHT ?
        @"Release to Add Item" : @"Pull to Add Item";
        _placeholderCell.alpha = MIN(1.0f, - self.scrollView.contentOffset.y / SHC_ROW_HEIGHT);
    }
}

-(void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    // check whether the user pulled down far enough
    if (_pullDownInProgress && - self.scrollView.contentOffset.y > SHC_ROW_HEIGHT) {
        [self.dataSource itemAdded];
    }
    _pullDownInProgress = false;
    [_placeholderCell removeFromSuperview];
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
