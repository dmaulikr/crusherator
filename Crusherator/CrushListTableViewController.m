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
    CrushTableViewPinchToAddNew *_pinchAddNew;
    
//    UIPanGestureRecognizer *_swipe;
    CGPoint _originalCenter;
    NSInteger _pageIndex;
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
        
    }
    return self;
}

+ (CrushListTableViewController *)viewControllerForPageIndex:(NSInteger)pageIndex {
    if (pageIndex >= 0 && pageIndex < 10) {
        return [[self alloc] initWithPageIndex:pageIndex];
    }
    return nil;
}

- (id)initWithPageIndex:(NSInteger)pageIndex
{
    self = [self initWithNibName:@"CrushListTableViewController_iPhone" bundle:nil];
    if (self) {
        _pageIndex = pageIndex;
    }
    return self;
}

- (NSInteger)pageIndex
{
    return _pageIndex;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.tableView.dataSource = self;
    self.tableView.color = [self colorForIndex:[database taskInfosForPageIndex:_pageIndex].count];
    self.tableView.backgroundColor = [UIColor blackColor];
    [self.tableView registerClassForCells:[CrushListTableViewCell class]];
    
    _dragAddNew = [[CrushTableViewDragAddNew alloc] initWithTableView:self.tableView];
    _pinchAddNew = [[CrushTableViewPinchToAddNew alloc] initWithTableView:self.tableView];
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
    int numberOfLists = 5;
    float hue = (1.0/numberOfLists)*(_pageIndex%numberOfLists);
    float adjustment = (0.15/self.filteredTaskInfos.count)*index;
    
    NSArray *colors = @[
                        [UIColor colorWithRed:255.0 / 255.0 green:66.0 / 255.0 blue: 0.0 / 255.0 alpha:1.0],
                        [UIColor colorWithRed:255.0 / 255.0 green:180.0 / 255.0 blue: 0.0 / 255.0 alpha:1.0],
                        [UIColor colorWithRed:0.0 / 255.0 green:180.0 / 255.0 blue: 60.0 / 255.0 alpha:1.0],
                        [UIColor colorWithRed:0.0 / 255.0 green:234.0 / 255.0 blue: 255.0 / 255.0 alpha:1.0],
                        [UIColor colorWithRed:0.0 / 255.0 green:0.0 / 255.0 blue: 255.0 / 255.0 alpha:1.0],
                        [UIColor colorWithRed:198.0 / 255.0 green:0.0 / 255.0 blue: 255.0 / 255.0 alpha:1.0],
                        [UIColor colorWithRed:255.0 / 255.0 green:0.0 / 255.0 blue: 144.0 / 255.0 alpha:1.0]
                        ];
    
//    UIColor *color = colors[(_pageIndex%colors.count)];
    
    UIColor *color = [UIColor colorWithHue:hue+adjustment saturation:1.0 brightness:0.8 alpha:1.0];
    
    return color;
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
    return self.filteredTaskInfos.count;
}

-(NSMutableArray *)filteredTaskInfos
{
    return [database taskInfosForPageIndex:_pageIndex];
}

-(CrushListTableViewCell *)cellForRow:(NSInteger)row
{
    CrushListTableViewCell* cell = (CrushListTableViewCell*)[self.tableView dequeueReusableCell];
    
    CrushTaskObject *item = self.filteredTaskInfos[row];
    cell.toDoItem = item;
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
        UIImageView *snapShotView = (UIImageView *)[self.view viewWithTag:CELL_SNAPSHOT_TAG];
        [UIView animateWithDuration:0.3 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            snapShotView.transform = CGAffineTransformMakeScale(1.0, 1.0);
            snapShotView.frame = cellBeingMoved.frame;
        } completion:^(BOOL finished){
            if (cellBeingMoved == referenceCell) {
                referenceCell.alpha = 1.0;
            }
            [[self.view viewWithTag:CELL_SNAPSHOT_TAG] removeFromSuperview];
            [self.tableView reloadData];
        }];
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
    if(startAnimatingDown) [self moveCellDown:cellBeingMoved];
    if(startAnimatingUp) [self moveCellUp:cellBeingMoved];
    
}

-(void)moveCellDown:(CrushListTableViewCell *)cellBeingMoved
{
    NSArray *visibleCells = (NSArray *)[self.tableView visibleCells];
    for(CrushListTableViewCell* cell in visibleCells) {
        if ([visibleCells indexOfObject:cell] - [visibleCells indexOfObject:cellBeingMoved] == 1) {
            cell.toDoItem.ordering ++;
            cellBeingMoved.toDoItem.ordering --;
            [cell.toDoItem editInDatabase];
            [cellBeingMoved.toDoItem editInDatabase];
            [UIView animateWithDuration:0.3 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
                cell.frame = CGRectOffset(cell.frame, 0.0f, -cell.frame.size.height);
                cellBeingMoved.frame = CGRectOffset(cellBeingMoved.frame, 0.0f, cellBeingMoved.frame.size.height);
            } completion:^(BOOL finished){
            }];
        }
    }
}

-(void)moveCellUp:(CrushListTableViewCell *)cellBeingMoved
{
    NSArray *visibleCells = (NSArray *)[self.tableView visibleCells];
    for(CrushListTableViewCell* cell in visibleCells) {
        if ([visibleCells indexOfObject:cell] - [visibleCells indexOfObject:cellBeingMoved] == -1) {
            cell.toDoItem.ordering --;
            cellBeingMoved.toDoItem.ordering ++;
            [cell.toDoItem editInDatabase];
            [cellBeingMoved.toDoItem editInDatabase];
            [UIView animateWithDuration:0.3 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
                cell.frame = CGRectOffset(cell.frame, 0.0f, cell.frame.size.height);
                cellBeingMoved.frame = CGRectOffset(cellBeingMoved.frame, 0.0f, -cellBeingMoved.frame.size.height);
            } completion:^(BOOL finished){
            }];
        }
    }
}

-(void)cellBeingCompleted:(CrushListTableViewCell *)cellBeingCompleted
{
    for(int i = 0; i < cellBeingCompleted.toDoItem.ordering+1; i++)
    {
//        [self moveCellDown:cellBeingCompleted];
//        [database moveToEnd:cellBeingCompleted.toDoItem];
//        [self.tableView reloadData];
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
    
//    if([editingCell.toDoItem.text isEqualToString:@""])
//    {
//        [self toDoItemDeleted:editingCell.toDoItem];
//    }
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
    [self itemAddedAtIndex:[self filteredTaskInfos].count+1];
}

-(void)itemAddedAtIndex:(NSInteger)index {
    // create the new item
    CrushTaskObject* toDoItem = [database addTask:@"task name" atIndex:index withPageIndex:_pageIndex+1];
//    NSLog(@"%@ added: order %i, index %i",toDoItem.text,toDoItem.ordering,toDoItem.category);
    
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

-(void)dismissKeyboard
{
    [_cellBeingEdited dismissKeyboard];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return NO;
}

@end