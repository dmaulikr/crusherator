//
//  CrushListViewController.m
//  Crusherator
//
//  Created by Raj on 4/13/13.
//  Copyright (c) 2013 Raj. All rights reserved.
//

#import "CrushListTableViewController.h"

@interface CrushListTableViewController ()

{
    // an array of to-do items
    NSMutableArray* _toDoItems;
}

@end

@implementation CrushListTableViewController


-(id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
        // create a dummy to-do list
        _toDoItems = [[NSMutableArray alloc] init];
        [_toDoItems addObject:[listItem toDoItemWithText:@"Feed the cat"]];
        [_toDoItems addObject:[listItem toDoItemWithText:@"Buy eggs"]];
        [_toDoItems addObject:[listItem toDoItemWithText:@"Pack bags for WWDC"]];
        [_toDoItems addObject:[listItem toDoItemWithText:@"Rule the web"]];
        [_toDoItems addObject:[listItem toDoItemWithText:@"Buy a new iPhone"]];
        [_toDoItems addObject:[listItem toDoItemWithText:@"Find missing socks"]];
        [_toDoItems addObject:[listItem toDoItemWithText:@"Write a new tutorial"]];
        [_toDoItems addObject:[listItem toDoItemWithText:@"Master Objective-C"]];
        [_toDoItems addObject:[listItem toDoItemWithText:@"Remember your wedding anniversary!"]];
        [_toDoItems addObject:[listItem toDoItemWithText:@"Drink less beer"]];
        [_toDoItems addObject:[listItem toDoItemWithText:@"Learn to draw"]];
        [_toDoItems addObject:[listItem toDoItemWithText:@"Take the car to the garage"]];
        [_toDoItems addObject:[listItem toDoItemWithText:@"Sell things on eBay"]];
        [_toDoItems addObject:[listItem toDoItemWithText:@"Learn to juggle"]];
        [_toDoItems addObject:[listItem toDoItemWithText:@"Give up"]];
        self.title = NSLocalizedString(@"List", @"List");
        self.tabBarItem.image = [UIImage imageNamed:@"second"];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    self.tableView.dataSource = self;
    [self.tableView registerClass:[CrushListTableViewCell class] forCellReuseIdentifier:@"cell"];
    
    self.tableView.delegate = self;
    
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.backgroundColor = [UIColor blackColor];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(UIColor*)colorForIndex:(NSInteger) index {
    NSUInteger itemCount = _toDoItems.count - 1;
    float val = ((float)index / (float)itemCount) * 0.6;
    return [UIColor colorWithRed: 1.0 green:val blue: 0.0 alpha:1.0];
}

#pragma mark - UITableViewDataDelegate protocol methods
-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 50.0f;
}

-(void)tableView:(UITableView *)tableView willDisplayCell:(CrushListTableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    cell.backgroundColor = [self colorForIndex:indexPath.row];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return _toDoItems.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *ident = @"cell";
    // re-use or create a cell
    CrushListTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:ident forIndexPath:indexPath];
    // find the to-do item for this index
    int index = [indexPath row];
    listItem *item = _toDoItems[index];
    // set the text
//    cell.textLabel.text = item.text;
    cell.textLabel.backgroundColor = [UIColor clearColor];
    
    cell.delegate = self;
    cell.toDoItem = item;
    return cell;
}

-(void)toDoItemDeleted:(id)todoItem {
    // use the UITableView to animate the removal of this row
    NSUInteger index = [_toDoItems indexOfObject:todoItem];
    [self.tableView beginUpdates];
    [_toDoItems removeObject:todoItem];
    [self.tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:index inSection:0]]
                          withRowAnimation:UITableViewRowAnimationFade];
    [self.tableView endUpdates];
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Navigation logic may go here. Create and push another view controller.
    /*
     <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
     [self.navigationController pushViewController:detailViewController animated:YES];
     */
}

@end
