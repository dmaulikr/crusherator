//
//  CrushListViewController.h
//  Crusherator
//
//  Created by Raj on 4/13/13.
//  Copyright (c) 2013 Raj. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CrushTableViewCellDelegate.h"
#import "CrushListTableViewCell.h"
#import "CrushTableView.h"
#import "CrushTableViewDragAddNew.h"
#import "CrushTaskDatabase.h"
#import "CrushTableViewDataSource.h"
#import "CrushTableViewPinchToAddNew.h"

@interface CrushListTableViewController : UIViewController
<
UITableViewDelegate, // Allows managing selections, configuring section headings and footers, help to delete and reorder cells, and perform other actions.
CrushTableViewCellDelegate, // Handles deleting, and editing, CrushListTableViewCells.
CrushTableViewDataSource // Implements numberOfRows, rowForIndex, and adding CrushListTableViewCells.
>

@property (weak, nonatomic) IBOutlet CrushTableView *tableView;

@property (nonatomic, retain) NSMutableArray *tasks;
@property (nonatomic, assign) BOOL selfIsPrimaryList;

@end