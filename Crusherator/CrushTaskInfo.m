//
//  CrushTaskData.m
//  Crusherator
//
//  Created by Raj on 4/14/13.
//  Copyright (c) 2013 Raj. All rights reserved.
//

#import "CrushTaskInfo.h"

@implementation CrushTaskInfo

static sqlite3_stmt *init_statement = nil;
static sqlite3_stmt *dehydrate_statment = nil;
static sqlite3_stmt *delete_statement = nil;
static sqlite3_stmt *insert_statement = nil;
@synthesize uniqueId = _uniqueId;
@synthesize text = _text;
@synthesize works = _works;
@synthesize completed = _completed;
@synthesize deleted = _deleted;
@synthesize dateCreated = _dateCreated;
@synthesize dateCompleted = _dateCompleted;
@synthesize dateDeleted = _dateDeleted;
@synthesize category = _category;
@synthesize project = _project;

- (void)insertIntoDatabase:(sqlite3 *)database {
    // When delegate is applied this will return an NSInteger
    if (insert_statement == nil) {
        NSLog(_text);
        static char *sql = "INSERT INTO tasks VALUES('_uniqueId','','0','0','0','','','','','')";
        if (sqlite3_prepare_v2(__database, sql, -1, &insert_statement, NULL) != SQLITE_OK) {
            NSAssert1(0, @"Error: failed to prepare statement with message '%s'.", sqlite3_errmsg(database));
        }
    }
    int success = sqlite3_step(insert_statement);
    
    sqlite3_reset(insert_statement);
    if (success != SQLITE_ERROR) {
        return;
    }
    NSAssert1(0, @"Error: failed to insert into the database with message '%s'.", sqlite3_errmsg(database));
}

- (id)initWithUniqueId:(int)uniqueId
                  text:(NSString *)text
{
    if ((self = [super init])) {
        self.uniqueId = uniqueId;
        self.text = text;
        self.works = FALSE;
        self.completed = FALSE;
        self.deleted = FALSE;
        self.dateCreated = [NSDate date];
        self.dateCompleted = NULL;
        self.dateDeleted = NULL;
        self.category = NULL;
        self.project = NULL;
        
        CrushTaskDatabase *taskDatabase = [[CrushTaskDatabase alloc] init];
        __database = taskDatabase.databaseAccess;
    }
    return self;
}

- (void) reset {
    self.text = nil;
    self.works = 0;
    self.deleted = nil;
    self.dateCreated = nil;
    self.dateCompleted = nil;
    self.dateDeleted = nil;
    self.category = nil;
    self.project = nil;
}

-(void) deleteFromDatabase {
	if (delete_statement == nil) {
		const char *sql = "DELETE FROM tasks WHERE uniqueId=?";
		if (sqlite3_prepare_v2(__database, sql, -1, &delete_statement, NULL) != SQLITE_OK) {
			NSAssert1(0, @"Error: failed to prepare statement with message '%s'.", sqlite3_errmsg(__database));
		}
	}
	
	sqlite3_bind_int(delete_statement, 1, self.uniqueId);
	int success = sqlite3_step(delete_statement);
	
	if (success != SQLITE_DONE) {
		NSAssert1(0, @"Error: failed to save priority with message '%s'.", sqlite3_errmsg(__database));
	}
	
	sqlite3_reset(delete_statement);
}


@end
