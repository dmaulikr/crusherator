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

@interface CrushListTableViewController : UITableViewController
<
UITableViewDataSource,
UITableViewDelegate,
CrushTableViewCellDelegate
>

@property (weak, nonatomic) IBOutlet CrushTableView *tableView;

@end
