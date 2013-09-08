//
//  CrushTaskDatabase.m
//  Crusherator
//
//  Created by Raj on 4/14/13.
//  Copyright (c) 2013 Raj. All rights reserved.
//

#import "CrushTaskDatabase.h"
#import "CrushTaskObject.h"

@implementation CrushTaskDatabase

static NSMutableArray *allTasks = NULL;
static CrushTaskDatabase *instance = NULL;

+ (CrushTaskDatabase *)sharedInstance
{
    @synchronized(self)
    {
        if (instance == NULL)
            instance = [[self alloc] init];
    }
    
    return(instance);
}

- (id)init {
    if ((self = [super init])) {
        
        // First, test for existence.
        BOOL success;
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSError *error;
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        NSString *writableDBPath = [documentsDirectory stringByAppendingPathComponent:@"taskList.sqlite3"];
        success = [fileManager fileExistsAtPath:writableDBPath];
        if (success) return self;
        
        // The writable database does not exist, so copy the default to the appropriate location.
        NSString *defaultDBPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"taskList.sqlite3"];
        success = [fileManager copyItemAtPath:defaultDBPath toPath:writableDBPath error:&error];
        
        if (!success) {
            NSAssert1(0, @"Failed to create writable database file with message '%@'.", defaultDBPath);
        }
    }
    return self;
}

- (NSString *)databasePath {
    // The database is stored in the application bundle.
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    return [documentsDirectory stringByAppendingPathComponent:@"taskList.sqlite3"];
}

- (sqlite3 *)databaseAccess {
    NSString *path = self.databasePath;
    if (sqlite3_open([path UTF8String], &_database) == SQLITE_OK) {
        // Open the database. The database was prepared outside the application.
        if (sqlite3_open([path UTF8String], &_database) == SQLITE_OK)
        {
            return _database;
        }
    }
    return NULL;
}

- (NSMutableArray *)arrayWithAllTasks {
    if(allTasks.count == 0)
    {
        allTasks = [[NSMutableArray alloc] init];
        NSString *path = self.databasePath;
        if (sqlite3_open([path UTF8String], &_database) == SQLITE_OK) {
            
            // Open the database. The database was prepared outside the application.
            if (sqlite3_open([path UTF8String], &_database) == SQLITE_OK) {
                
                // Get the primary key for all tasks.
                const char *sql = "SELECT * FROM tasks ORDER BY ordering DESC";
                sqlite3_stmt *statement;
                
                // Preparing a statement compiles the SQL query into a byte-code program in the SQLite library.
                
                // The third parameter is either the length of the SQL string or -1 to read up to the first null terminator.
                if (sqlite3_prepare_v2(_database, sql, -1, &statement, NULL) == SQLITE_OK) {
                    
                    // We "step" through the results - once for each row.
                    while (sqlite3_step(statement) == SQLITE_ROW) {
                        int uniqueId = sqlite3_column_int (statement, 0);
                        
                        char *textChars = (char *) sqlite3_column_text(statement, 1);
                        NSString *text = [NSString stringWithFormat:(@"%s"),textChars];
                        
                        int completedZeroOne = sqlite3_column_int (statement, 2);
                        bool accessedCompleted = (completedZeroOne == 1)? true : false;

                        int accessedWorks = sqlite3_column_int (statement, 3);
                        int accessedOrdering = sqlite3_column_int (statement, 4);
                        int accessedEstimatedWorks = sqlite3_column_int (statement, 5);
                        int accessedCategory = sqlite3_column_int (statement, 6);
//
//                      NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
//                      [dateFormat setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
//
//                      char *dateCreatedChars = (char *) sqlite3_column_text(statement, 7);
//                      NSString *createdText = [NSString stringWithFormat:(@"%s"),dateCreatedChars];
//                      NSDate *dateCreated =[dateFormat dateFromString:createdText];
//                    
//                      char *dateCompletedChars = (char *) sqlite3_column_text(statement, 7);
//                      NSString *completedText = [NSString stringWithFormat:(@"%s"),dateCompletedChars];
//                      NSDate *dateCompleted =[dateFormat dateFromString:completedText];
//                    
//                      char *dateDeletedChars = (char *) sqlite3_column_text(statement, 7);
//                      NSString *deletedText = [NSString stringWithFormat:(@"%s"),dateDeletedChars];
//                      NSDate *dateDeleted =[dateFormat dateFromString:deletedText];
//                    
//                      char *categoryChars = (char *) sqlite3_column_text(statement, 7);
//                      NSString *category = [NSString stringWithFormat:(@"%s"),categoryChars];
//                    
//                      char *projectChars = (char *) sqlite3_column_text(statement, 8);
//                      NSString *project = [NSString stringWithFormat:(@"%s"),projectChars];
//                    
                        CrushTaskObject *accessedTask = [[CrushTaskObject alloc]
                                               initWithUniqueId:uniqueId
                                               text:text];
                        
                        accessedTask.works = accessedWorks;
                        accessedTask.completed = accessedCompleted;
                        accessedTask.ordering = accessedOrdering;
                        accessedTask.estimatedWorks = accessedEstimatedWorks;
    //                    info.dateCreated = dateCreated;
    //                    info.dateCompleted = dateCompleted;
    //                    info.dateDeleted = dateDeleted;
                        accessedTask.category = accessedCategory;
    //                    info.project = project;
                        [allTasks addObject:accessedTask];
                        
                        NSLog(@"Accessed task: %@, order %i, index %i",accessedTask.text,accessedTask.ordering,accessedTask.category);
                    }
                }
                
                // "Finalize" the statement - releases the resources associated with the statement.
                sqlite3_finalize(statement);
            } else {
                
                // Even though the open failed, call close to properly clean up resources.
                sqlite3_close(_database);
                NSAssert1(0, @"Failed to open database with message '%s'.", sqlite3_errmsg(_database));
            }
        }
    }
    return allTasks;
}

- (NSMutableArray *)taskInfosForPageIndex:(int)index
{
    // Returns an array of task objects (ordered) in the category (index) specified
    NSMutableArray *filteredList = [[NSMutableArray alloc] init];
    for(CrushTaskObject *object in [self arrayWithAllTasks])
    {
        if(object.category == index+1) [filteredList addObject:object];
    }
    
    NSSortDescriptor *sortDescriptor;
    sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"ordering"
                                                 ascending:NO];
    NSArray *sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
    NSArray *sortedArray;
    sortedArray = [filteredList sortedArrayUsingDescriptors:sortDescriptors];
    return (NSMutableArray*)sortedArray;
}

-(void)removeTask:(CrushTaskObject *)task {
	
    // Find task index in allTasks
    NSUInteger index = [allTasks indexOfObject:task];
    if (index == NSNotFound) return;
    
    // Delete task from database & allTasks
    [task deleteFromDatabase];
    [allTasks removeObject:task];
    
    // Shift order of all tasks above deleted task
    for(CrushTaskObject *object in [self taskInfosForPageIndex:task.category-1])
    {
        if(object.ordering > task.ordering)
        {
            object.ordering --;
            [object editInDatabase];
        }
    }
}

-(void)moveToEnd:(CrushTaskObject *)task {
    // Shift order of all tasks below moved task
    for(CrushTaskObject *object in [self taskInfosForPageIndex:task.category])
    {
        if(object.ordering < task.ordering)
        {
            object.ordering ++;
            [object editInDatabase];
        }
    }

    task.ordering = 1;
}

-(CrushTaskObject *) addTask:(NSString *)text atIndex:(int)index withPageIndex:(int)pageIndex {
	
    // Shift order of all tasks above inserted task
    for (CrushTaskObject *object in [self taskInfosForPageIndex:pageIndex-1])
    {
        if (object.ordering >= index)
        {
            object.ordering ++;
            [object editInDatabase];
        }
    }
    
    // Add task to database and allTasks
    NSInteger uniqueId = [CrushTaskObject insertIntoDatabase:_database];
    CrushTaskObject *newTask = [[CrushTaskObject alloc]initWithUniqueId:uniqueId text:text];
    [allTasks addObject:newTask];
    
    newTask.ordering = index;
    newTask.category = pageIndex;
    
    [newTask editInDatabase];

    return newTask;
}


@end
