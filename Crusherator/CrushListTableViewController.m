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
    CrushTaskDatabase *database;
    
    // the offset applied to cells when entering “edit mode”
    float _editingOffset;
    BOOL _cellIsBeingEdited;
    CrushListTableViewCell *_cellBeingEdited;
    
    CrushTableViewDragAddNew *_dragAddNew;
}

@end

@implementation CrushListTableViewController

#define CELL_SNAPSHOT_TAG 100000

-(id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
        // access database
        database = [CrushTaskDatabase sharedInstance];
        self.tasks = database.taskInfos;

        //
        self.title = NSLocalizedString(@"List", @"List");
        self.tabBarItem.image = [UIImage imageNamed:@"second"];
        
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.tableView.dataSource = self;
    self.tableView.backgroundColor = [UIColor blackColor];
    [self.tableView registerClassForCells:[CrushListTableViewCell class]];
    
//    Gesture recognizer to dismiss keyboard when in editing mode
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]
                                   initWithTarget:self
                                   action:@selector(dismissKeyboard)];
    [self.view addGestureRecognizer:tap];
    
    _dragAddNew = [[CrushTableViewDragAddNew alloc] initWithTableView:self.tableView];
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
    NSUInteger itemCount = database.taskInfos.count - 1;
    float val = ((float)index / (float)itemCount) * 0.6;
    return [UIColor colorWithRed: 1.0 green:val blue: 0.0 alpha:1.0];
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
    return database.taskInfos.count;
}

-(CrushListTableViewCell *)cellForRow:(NSInteger)row
{
    CrushListTableViewCell* cell = (CrushListTableViewCell*)[self.tableView dequeueReusableCell];
    CrushTaskObject *item = database.taskInfos[row];
    cell.toDoItem = item;
    cell.row = row;
    cell.delegate = self;
    cell.backgroundColor = [self colorForIndex:row];
    return cell;
}

// 
-(void)toDoItemDeleted:(CrushTaskObject *)todoItem
{
    float delay = 0.5;
    [database removeTask:todoItem];
    
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
            delay+=0.01;
        }
        // if we have reached the item that was deleted, start animating
        if (cell.toDoItem == todoItem) {
            startAnimating = true;
            cell.hidden = YES;
        }
    }
}

-(void)cellIsBeingMoved:(CrushListTableViewCell *)cellBeingMoved
{
    // find the visible cells
    NSArray* visibleCells = [self.tableView visibleCells];
    
    // iterate over all of the cells
    for(CrushListTableViewCell* referenceCell in visibleCells) {
        if (cellBeingMoved == referenceCell) {
            referenceCell.alpha = 0.0;
        }
    }
}

-(void)cellIsDoneBeingMoved:(CrushListTableViewCell *)cellBeingMoved
{
    // find the visible cells
    NSArray* visibleCells = [self.tableView visibleCells];
    
    // iterate over all of the cells
    for(CrushListTableViewCell* referenceCell in visibleCells) {
        if (cellBeingMoved == referenceCell) {
            referenceCell.alpha = 1.0;
        }
        
        referenceCell.toDoItem.ordering = [visibleCells indexOfObject:referenceCell];
    }
}

-(void)cellIsBeingDragged:(CrushListTableViewCell *)cellBeingMoved to:(CGPoint)number;
{
    UIImageView *snapShotView = (UIImageView *)[self.view viewWithTag:CELL_SNAPSHOT_TAG];
    CGPoint center = snapShotView.center;
    BOOL startAnimatingDown = FALSE;
    BOOL startAnimatingUp = FALSE;
    if(center.y > cellBeingMoved.frame.origin.y+cellBeingMoved.frame.size.height)
    {
        startAnimatingDown = TRUE;
    }
    if(center.y < cellBeingMoved.frame.origin.y)
    {
        startAnimatingUp = TRUE;
    }
    NSArray *visibleCells = (NSArray *)[self.tableView visibleCells];
    UIView* lastView = [visibleCells lastObject];
    for(CrushListTableViewCell* cell in visibleCells) {
        if (startAnimatingDown && ([visibleCells indexOfObject:cell] - [visibleCells indexOfObject:cellBeingMoved] == 1)) {
            [UIView animateWithDuration:0.3 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
                cell.frame = CGRectOffset(cell.frame, 0.0f, -cell.frame.size.height);
                cellBeingMoved.frame = CGRectOffset(cellBeingMoved.frame, 0.0f, cellBeingMoved.frame.size.height);
            } completion:^(BOOL finished){
            }];
        }
    }
    
    for(CrushListTableViewCell* cell in visibleCells) {
        if (startAnimatingUp && ([visibleCells indexOfObject:cell] - [visibleCells indexOfObject:cellBeingMoved] == -1)) {
            [UIView animateWithDuration:0.3 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
                cell.frame = CGRectOffset(cell.frame, 0.0f, cell.frame.size.height);
                cellBeingMoved.frame = CGRectOffset(cellBeingMoved.frame, 0.0f, -cellBeingMoved.frame.size.height);
            } completion:^(BOOL finished){
            }];
        }
    }
}

-(void)cellDidBeginEditing:(CrushListTableViewCell *)editingCell
{
    _cellBeingEdited = editingCell;
    _cellIsBeingEdited = YES;
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

-(void)cellDidEndEditing:(CrushListTableViewCell *)editingCell
{
    _cellIsBeingEdited = NO;
    _cellBeingEdited = NULL;
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

-(BOOL)cellShouldBeginEditing:(CrushListTableViewCell *)cell
{
    if(_cellBeingEdited && !cell.isBeingEdited)
    {
        [self dismissKeyboard];
        return NO;
    }
    else return YES;
}

-(void)itemAdded
{
    // create the new item
    CrushTaskObject* todoItem = [database addTask:@"task name"];
    
    // refresh the table
    [_tableView reloadData];
    
    // enter edit mode
    CrushListTableViewCell* editCell;
    for (CrushListTableViewCell* cell in _tableView.visibleCells) {
        if (cell.toDoItem == todoItem) {
            editCell = cell;
            break;
        }
    }
    [editCell.label becomeFir