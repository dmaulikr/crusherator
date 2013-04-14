//
//  CrushTableView.m
//  Crusherator
//
//  Created by Raj on 4/14/13.
//  Copyright (c) 2013 Raj. All rights reserved.
//

#import "CrushTableView.h"

@implementation CrushTableView
{
// the scroll view that hosts the cells
UIScrollView* _scrollView;
}

-(id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        _scrollView = [[UIScrollView alloc] initWithFrame:CGRectNull];
        [self addSubview:_scrollView];
        _scrollView.backgroundColor = [UIColor clearColor];
        self.backgroundColor = [UIColor clearColor];
        
    }
    return self;
}

-(void)layoutSubviews {
    _scrollView.frame = self.frame;
    [self refreshView];
}

const float SHC_ROW_HEIGHT = 50.0f;

-(void)refreshView {
    // set the scrollview height
    _scrollView.contentSize = CGSizeMake(_scrollView.bounds.size.width,
                                         [_dataSource numberOfRows] * SHC_ROW_HEIGHT);
    
    // add the cells
    for (int row=0; row < [_dataSource numberOfRows]; row++) {
        // obtain a cell
        UIView* cell = [_dataSource cellForRow:row];
        // set its location
        float topEdgeForRow = row * SHC_ROW_HEIGHT;
        CGRect frame = CGRectMake(0, topEdgeForRow,
                                  _scrollView.frame.size.width, SHC_ROW_HEIGHT);
        cell.frame = frame;
        // add to the view
        [_scrollView addSubview:cell];
    }
}

#pragma mark - property setters
-(void)setDataSource:(id<CrushTableViewDataSource>)dataSource {
    _dataSource = dataSource;
    [self refreshView];
}

@end
