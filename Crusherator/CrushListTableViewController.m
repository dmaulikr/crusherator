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
    
    // the offset applied to cells when entering “edit mode”
    float _editingOffset;
    CrushListTableViewCell *cellBeingEdited;
}

@end

@implementation CrushListTableViewController


-(id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
        // access database
        CrushTaskDatabase *database = [[CrushTaskDatabase alloc] init];
        self.tasks = database.taskInfos;        

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
//    [self.tableView registerClass:[CrushListTableViewCell class] forCellReuseIdentifier:@"cell"];
//    
//    self.tableView.delegate = self;
//    
//    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.backgroundColor = [UIColor blackColor];
    [self.tableView registerClassForCells:[CrushListTableViewCell class]];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]
                                   initWithTarget:self
                                   action:@selector(dismissKeyboard)];
    
    [self.view addGestureRecognizer:tap];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(UIColor*)colorForIndex:(NSInteger) index {
    NSUInteger itemCount = _tasks.count - 1;
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

#pragma mark - CrushTableViewDataSource methods
-(NSInteger)numberOfRows {
    return _tasks.count;
}

-(UITableViewCell *)cellForRow:(NSInteger)row {
    CrushListTableViewCell* cell = (CrushListTableViewCell*)[self.tableView dequeueReusableCell];
    CrushTaskInfo *item = _tasks[row];
    cell.toDoItem = item;
    cell.delegate = self;
    cell.backgroundColor = [self colorForIndex:row];
    return cell;
}

-(void)toDoItemDeleted:(CrushTaskInfo *)todoItem {
    float delay = 0.0;
    
    // find the visible cells
    NSArray* visibleCells = [self.tableView visibleCells];
    
    UIView* lastView = [visibleCells lastObject];
    bool startAnimating = false;
    
    // iterate over all of the cells
    for(CrushListTableViewCell* cell in visibleCells) {
        if (startAnimating) {
            [UIView animateWithDuration:0.3 delay:delay options:UIViewAnimationOptionCurveEaseInOut animations:^{
                cell.frame = CGRectOffset(cell.frame, 0.0f, -cell.frame.size.height);
            } completion:^(BOOL finished){
                if (cell == lastView) {
                    [self.tableView reloadData];
                }
            }];
            delay+=0.03;
        }
        // if we have reached the item that was deleted, start animating
        if (cell.toDoItem == todoItem) {
            startAnimating = true;
            cell.hidden = YES;
        }
    }
    
    [todoItem deleteFromDatabase];
}

-(void)cellDidBeginEditing:(CrushListTableViewCell *)editingCell {
//    NSLog(@"1 %@",cellBeingEdited.toDoItem.text);
//    if (cellBeingEdited!=NULL && cellBeingEdited!=editingCell){
//        [self dismissKeyboard];
//        NSLog(@"if statement");
//        [editingCell textFieldShouldReturn:editingCell.label];
//        cellBeingEdited = NULL;
//        return;
//    }
//    else {
        cellBeingEdited = editingCell;
//    }
//    NSLog(@"2 %@",cellBeingEdited.toDoItem.text);
//    NSLog(@"3 %@",cellBeingEdited.toDoItem.text);
    _editingOffset = _tableView.scrollView.contentOffset.y - editingCell.frame.origin.y;
    for(CrushListTableViewCell* cell in [_tableView visibleCells]) {
        [UIView animateWithDuration:0.3
                         animations:^{
                             cell.frame = CGRectOffset(cell.frame, 0, _editingOffset);
                             if (cell != editingCell) {
                                 cell.alpha = 0.3;
                             }
                         }];
    }
}

-(void)cellDidEndEditing:(CrushListTableViewCell *)editingCell {
//    NSLog(@"done editing %@",cellBeingEdited);
//    cellBeingEdited = NULL;
    for(CrushListTableViewCell* cell in [_tableView visibleCells]) {
        [UIView animateWithDuration:0.3
                         animations:^{
                             cell.frame = CGRectOffset(cell.frame, 0, -_editingOffset);
                             if (cell != editingCell)
                             {
                                 cell.alpha = 1.0;
                             }
                         }];
    }
}

-(void)itemAdded {
    // create the new item
    CrushTaskDatabase *database = [[CrushTaskDatabase alloc] init];
    CrushTaskInfo* toDoItem = [database addTask:@"task name"];
    
    [_tasks insertObject:toDoItem atIndex:0];
    // refresh the table
    [_tableView reloadData];
    // enter edit mode
    CrushListTableViewCell* editCell;
    for (CrushListTableViewCell* cell in _tableView.visibleCells) {
        if (cell.toDoItem == toDoItem) {
            editCell = cell;
            break;
        }
    }
    [editCell.label becomeFirstResponder];
}

-(void)dismissKeyboard {
    [cellBeingEdited textFieldShouldReturn:cellBeingEdited.label];
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
