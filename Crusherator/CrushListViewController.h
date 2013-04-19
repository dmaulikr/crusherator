//
//  CrushListViewController.h
//  Crusherator
//
//  Created by Raj on 4/13/13.
//  Copyright (c) 2013 Raj. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CrushTableViewCellDelegate.h"
#import "listItem.h"
#import "CrushListTableViewCell.h"
#import "CrushTableView.h"
#import "CrushTableViewDragAddNew.h"
#import "CrushTaskDatabase.h"

@interface CrushListViewController : UIViewController
<
UITableViewDataSource,
UITableViewDelegate,
CrushTableViewCellDelegate
>

@property (weak, nonatomic) IBOutlet CrushTableViewDragAddNew *tableView;

@property (nonatomic, retain) NSMutableArray *tasks;

@end