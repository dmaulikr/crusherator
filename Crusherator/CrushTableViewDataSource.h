//
//  CrushTableViewDataSource.h
//  Crusherator
//
//  Created by Raj on 4/14/13.
//  Copyright (c) 2013 Raj. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol CrushTableViewDataSource <NSObject>

// Indicates the number of rows in the table
-(NSInteger)numberOfRows;

// Obtains the cell for the given row
-(UIView *)cellForRow:(NSInteger)row;

// Informs the datasource that a new item has been added at the top of the table
-(void)itemAdded;

@end