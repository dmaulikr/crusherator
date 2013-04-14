//
//  CrushTableView.h
//  Crusherator
//
//  Created by Raj on 4/14/13.
//  Copyright (c) 2013 Raj. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CrushTableViewDataSource.h"

@interface CrushTableView : UIView

// the object that acts as the data source for this table
@property (nonatomic, assign) id<CrushTableViewDataSource> dataSource;

@end
