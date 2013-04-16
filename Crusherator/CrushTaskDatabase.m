//
//  CrushTaskDatabase.m
//  Crusherator
//
//  Created by Raj on 4/14/13.
//  Copyright (c) 2013 Raj. All rights reserved.
//

#import "CrushTaskDatabase.h"
#import "CrushTaskInfo.h"

@implementation CrushTaskDatabase

NSMutableArray *retval;

- (id)init {
    if ((self = [super init])) {
        // First, test for existence.
        BOOL success;
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSError *error;
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        NSString *writableDBPath = [documentsDirectory stringByAppendingPathComponent:@"tasks.sqlite3"];
        success = [fileManager fileExistsAtPath:writableDBPath];
        if (success) return self;
        // The writable database does not exist, so copy the default to the appropriate location.
        NSString *defaultDBPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"tasks.sqlite3"];
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
    return [documentsDirectory stringByAppendingPathComponent:@"tasks.sqlite3"];
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
    else NSLog (@"Couldn't access database");
}

- (NSMutableArray *)taskInfos {
    NSString *path = self.databasePath;
    NSMutableArray *retval = [[NSMutableArray alloc] init];
    if (sqlite3_open([path UTF8String], &_database) == SQLITE_OK) {
        // Open the database. The database was prepared outside the application.
        if (sqlite3_open([path UTF8String], &_database) == SQLITE_OK) {
            // Get the primary key for all books.
            const char *sql = "SELECT * FROM tasks";
            sqlite3_stmt *statement;
            // Preparing a statement compiles the SQL query into a byte-code program in the SQLite library.
            // The third parameter is either the length of the SQL string or -1 to read up to the first null terminator.
            if (sqlite3_prepare_v2(_database, sql, -1, &statement, NULL) == SQLITE_OK) {
                // We "step" through the results - once for each row.
                while (sqlite3_step(statement) == SQLITE_ROW) {
                    int uniqueId = sqlite3_column_int (statement, 0);
                    
                    char *textChars = (char *) sqlite3_column_text(statement, 1);
                    NSString *text = [NSString stringWithFormat:(@"%s"),textChars];
                    
                    double works = sqlite3_column_int (statement, 2);
                    
                    int completedZeroOne = sqlite3_column_int (statement, 3);
                    bool completed = (completedZeroOne == 1)? true : false;
                    
                    int deletedZeroOne = sqlite3_column_int (statement, 4);
                    bool deleted = (deletedZeroOne == 1)? true : false;
                    
                    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
                    [dateFormat setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
                    
                    char *dateCreatedChars = (char *) sqlite3_column_text(statement, 7);
                    NSString *createdText = [NSString stringWithFormat:(@"%s"),dateCreatedChars];
                    NSDate *dateCreated =[dateFormat dateFromString:createdText];
                    
                    char *dateCompletedChars = (char *) sqlite3_column_text(statement, 7);
                    NSString *completedText = [NSString stringWithFormat:(@"%s"),dateCompletedChars];
                    NSDate *dateCompleted =[dateFormat dateFromString:completedText];
                    
                    char *dateDeletedChars = (char *) sqlite3_column_text(statement, 7);
                    NSString *deletedText = [NSString stringWithFormat:(@"%s"),dateDeletedChars];
                    NSDate *dateDeleted =[dateFormat dateFromString:deletedText];
                    
                    char *categoryChars = (char *) sqlite3_column_text(statement, 7);
                    NSString *category = [NSString stringWithFormat:(@"%s"),categoryChars];
                    
                    char *projectChars = (char *) sqlite3_column_text(statement, 8);
                    NSString *project = [NSString stringWithFormat:(@"%s"),projectChars];
                    
                    CrushTaskInfo *info = [[CrushTaskInfo alloc]
                                           initWithUniqueId:uniqueId
                                           text:text];
                    
                    [retval addObject:info];
                    info.works = works;
                    info.completed = completed;
                    info.deleted = deleted;
                    info.dateCreated = dateCreated;
                    info.dateCompleted = dateCompleted;
                    info.dateDeleted = dateDeleted;
                    info.category = category;
                    info.project = project;
                }
            }
            // "Finalize" the statement - releases the resources associated with the statement.
            sqlite3_finalize(statement);
        } else {
            // Even though the open failed, call close to properly clean up resources.
            sqlite3_close(_database);
            NSAssert1(0, @"Failed to open database with message '%s'.", sqlite3_errmsg(_database));
            // Additional error handling, as appropriate...
        }
    }
    NSArray* reversedArray = [[retval reverseObjectEnumerator] allObjects];
    return (NSMutableArray *)reversedArray;
}

-(void)removeTask:(CrushTaskInfo *)task {
	NSUInteger index = [retval indexOfObject:task];
    
    if (index == NSNotFound) return;
    
    [task deleteFromDatabase];
    [retval removeObject:task];
}

-(CrushTaskInfo *) addTask:(NSString *)text {
//    Need to make delegate to create uniqueId automatically
	int uniqueId = (retval.count+1);
    CrushTaskInfo *newTask = [[CrushTaskInfo alloc]initWithUniqueId:uniqueId text:text];
    [newTask insertIntoDatabase:_database];
    
	[retval insertObject:newTask atIndex:0];
    return newTask;
}


@end
