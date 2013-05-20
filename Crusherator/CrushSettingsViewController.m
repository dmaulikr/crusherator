//
//  CrushSettingsViewController.m
//  Crusherator
//
//  Created by Raj on 4/26/13.
//  Copyright (c) 2013 Raj. All rights reserved.
//

#import "CrushSettingsViewController.h"

@interface CrushSettingsViewController ()
{
    // an array of to-do items
    NSArray *_settings;
    UIFont *_fontDialogStrong;
    
}

@end

@implementation CrushSettingsViewController

#define CELL_SNAPSHOT_TAG 100000

-(id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
        self.title = NSLocalizedString(@"Settings", @"Settings");
        self.tabBarItem.image = [UIImage imageNamed:@"settings"];
        
        _settings = @[
                      @"Play music",
                      @"Buzz at end of work",
                      @"Buzz at end of play",
                      @"Shuffle music",
                      @"Play ticking sound",
                      @"Alarm when done",
                      @"Autostart",
                      @"Enable pausing",
                      @"Enable cancelling"
                      ];
        
        _fontDialogStrong = [UIFont fontWithName:@"Gotham Medium" size:15.0];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.tableView.dataSource = self;
    self.tableView.backgroundColor = [UIColor blackColor];
    [self.tableView registerClassForCells:[CrushListTableViewCell class]];
}

//     Reloads data when switching back from list view
- (void)viewWillAppear:(BOOL)animated
{
    [self.tableView reloadData];
    animated = NO;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

-(UIColor*)colorForIndex:(NSInteger)index
{
//    NSUInteger itemCount = database.taskInfos.count - 1;
//    float val = ((float)index / (float)itemCount) * 0.6;
    return [UIColor grayColor];
//    return [UIColor colorWithRed: 1.0 green:val blue: 0.0 alpha:1.0];
}

#pragma mark - UITableViewDataDelegate protocol methods
-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 50.0f;
}

-(void)tableView:(UITableView *)tableView willDisplayCell:(CrushListTableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    cell.backgroundColor = [self colorForIndex:indexPath.row];
}

#pragma mark - CrushTableViewDataSource methods
-(NSInteger)numberOfRows
{
    return _settings.count;
}

-(CrushListTableViewCell *)cellForRow:(NSInteger)row
{
    CrushListTableViewCell* cell = (CrushListTableViewCell*)[self.tableView dequeueReusableCell];
    cell.textLabel.text = _settings[row];
    cell.textLabel.backgroundColor = [UIColor clearColor];
    cell.textLabel.textColor = [UIColor whiteColor];
    cell.textLabel.font = _fontDialogStrong;
    cell.delegate = self;
    cell.backgroundColor = [self colorForIndex:row];
    return cell;
}

@end
