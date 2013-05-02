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
    BOOL _nextListActive;
    CrushListTableViewCell *_cellBeingEdited;
    CrushListTableViewController *_nextList;
    
    CrushTableViewDragAddNew *_dragAddNew;
    CrushTableViewPinchToAddNew *_pinchAddNew;
    
    UIPanGestureRecognizer *_swipe;
    CGPoint _originalCenter;
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
    
    _swipe = [[UIPanGestureRecognizer alloc]
                                   initWithTarget:self
                                   action:@selector(handlePan:)];
    [self.view addGestureRecognizer:_swipe];
    
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
    NSArray *visibleCells = (NSArray *)[self.tableView visibleCells];
    for(CrushListTableViewCell* cell in visibleCells) {
        if (startAnimatingDown && ([visibleCells indexOfObject:cell] - [visibleCells indexOfObject:cellBeingMoved] == 1)) {
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
    
    for(CrushListTableViewCell* cell in visibleCells) {
        if (startAnimatingUp && ([visibleCells indexOfObject:cell] - [visibleCells indexOfObject:cellBeingMoved] == -1)) {
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
    [self itemAddedAtIndex:0];
}

-(void)itemAddedAtIndex:(NSInteger)index {
    // create the new item
    CrushTaskObject* toDoItem = [database addTask:@"task name" atIndex:index];
    
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

-(BOOL)gestureRecognizerShouldBegin:(id)gestureRecognizer
{
    if(gestureRecognizer == _swipe)
    {
        UIPanGestureRecognizer *recognizer = (UIPanGestureRecognizer *)gestureRecognizer;
        CGPoint translation = [recognizer translationInView:[self view]];
        // Check for horizontal gesture
        if (fabsf(translation.x) > fabsf(translation.y)) {
            return YES;
        }
        else return NO;
    }
    else return NO;
}

-(void)handlePan:(id)gestureRecognizer
{
    if(gestureRecognizer == _swipe)
    {
        UIPanGestureRecognizer *recognizer = (UIPanGestureRecognizer *)gestureRecognizer;
        
        // 1
        if (recognizer.state == UIGestureRecognizerStateBegan) {
            // if the gesture has just started, record the current centre location
            _originalCenter = self.view.center;
            _nextList = [[CrushListTableViewController alloc]initWithNibName:@"CrushListTableViewController_iPhone" bundle:nil];
            _nextList.view.backgroundColor = [UIColor purpleColor];
            _nextList.view.center = CGPointMake((self.view.center.x - self.view.frame.size.width),self.view.center.y);
            [self.view addSubview:_nextList.view];
        }
        
        // 2
        if (recognizer.state == UIGestureRecognizerStateChanged) {
            // translate the center
            CGPoint translation = [recognizer translationInView:[self view]];
            if (translation.x >= self.view.frame.size.width/2)
            {
                _nextListActive = TRUE;
            }
            else _nextListActive = FALSE;

            self.view.center = CGPointMake(_originalCenter.x + translation.x, _originalCenter.y);
        }
        
        // 3
        if (recognizer.state == UIGestureRecognizerStateEnded) {
            // the frame this cell would have had before being dragged
            
            if(!_nextListActive){
                [UIView animateWithDuration:0.2
                                animations:^{
                                    self.view.center = _originalCenter;
                                    _nextList.view.center = CGPointMake((self.view.center.x - self.view.frame.size.width),self.view.center.y);
                                }
                ];
            }
            else {
                [UIView animateWithDuration:0.2
                                 animations:^{
                                     self.view.center = CGPointMake(_originalCenter.x + self.view.frame.size.width,_originalCenter.y);
//                                     _nextList.view.center = CGPointMake((self.view.center.x - self.view.frame.size.width),self.view.center.y);
                                 }
                 ];

            }
        }
    }
}


@end