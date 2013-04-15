//
//  CrushTableView.h
//  Crusherator
//
//  Created by Raj on 4/14/13.
//  Copyright (c) 2013 Raj. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CrushTableViewDataSource.h"
#import "CrushListTableViewCell.h"

@interface CrushTableView : UIView <UIScrollViewDelegate>

// the object that acts as the data source for this table
@property (nonatomic, assign) id<CrushTableViewDataSource> dataSource;

// dequeues a cell that can be reused
-(UIView*)dequeueReusableCell;

// registers a class for use as new cells
-(void)registerClassForCells:(Class)cellClass;

// an array of cells that are currently visible, sorted from top to bottom.
-(NSArray*)visibleCells;

// forces the table to dispose of all the cells and re-build the table.
-(void)reloadData;

@property (nonatomic, assign, readonly) UIScrollView* scrollView;

@end
