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
    
    // the table that this gesture is associated with
    CrushTableView* _tableView;
}

@synthesize alwaysBounceHorizontal;
@synthesize alwaysBounceVertical;

-(id)initWithTableView:(CrushTableView *)tableView {
//    self = [super init];
    if (self) {
        _placeholderCell = [[CrushListTableViewCell alloc] init];
        _tableView = tableView;
        _placeholderCell.backgroundColor = tableView.color;
        _tableView.delegate = self;
    }
    return self;
}

#pragma mark - UIScrollViewDelegate
-(void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    _pullDownInProgress = true;
    if (_pullDownInProgress) {
        // add your placeholder
        [_tableView insertSubview:_placeholderCell atIndex:0];
    }
}

-(void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (_pullDownInProgress && _tableView.scrollView.contentOffset.y <= 0.0f) {
        // maintain the location of the placeholder
        _placeholderCell.frame = CGRectMake(0, - _tableView.scrollView.contentOffset.y - SHC_ROW_HEIGHT,
                                            _tableView.frame.size.width, SHC_ROW_HEIGHT);
        _placeholderCell.label.text = -_tableView.scrollView.contentOffset.y > SHC_ROW_HEIGHT ?
        @"Release to Add Item" : @"Pull to Add Item";
        _placeholderCell.alpha = MIN(1.0f, - _tableView.scrollView.contentOffset.y / SHC_ROW_HEIGHT);
    }
}

-(void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    // check whether the user pulled down far enough
    if (_pullDownInProgress && - _tableView.scrollView.contentOffset.y > SHC_ROW_HEIGHT) {
        [_tableView.dataSource itemAdded];
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
