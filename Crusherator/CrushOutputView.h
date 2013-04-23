//
//  CrushViewController.h
//  Crusherator
//
//  Created by Raj on 4/18/13.
//  Copyright (c) 2013 Raj. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CrushTableViewCellDelegate.h"
#import "listItem.h"
#import "CrushListTableViewCell.h"
#import "CrushTableView.h"
#import "CrushOutputList.h"
#import "CrushTaskDatabase.h"

@interface CrushOutputView : UIViewController
<
UITableViewDataSource,
UITableViewDelegate,
CrushTableViewCellDelegate
>

@property (weak, nonatomic) IBOutlet CrushOutputList *tableView;

-(void)reload;

@end
