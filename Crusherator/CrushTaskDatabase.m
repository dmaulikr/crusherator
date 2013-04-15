//
//  CrushTaskDatabase.m
//  Crusherator
//
//  Created by Raj on 4/14/13.
//  Copyright (c) 2013 Raj. All rights reserved.
//

#import "CrushTaskDatabase.h"

@implementation CrushTaskDatabase

- (id)init {
    if ((self = [super init])) {
        NSString *sqLiteDb = [[NSBundle mainBundle] pathForResource:@"tasklist" ofType:@"sqlite3"];
        
        if (sqlite3_open([sqLiteDb UTF8String], &_database) != SQLITE_OK) {
            NSLog (@"Failed to open database!");
        }
    }
    return self;
}

- (NSArray *)taskInfos {
    NSMutableArray *retval = [[NSMutableArray alloc] init];
    NSString *query = @"SELECT id, text, works, completed, deleted, dateCreated, dateCompleted, dateDeleted, category, project FROM tasks ORDER BY uniqueId";
    sqlite3_stmt *statement;
    if (sqlite3_prepare_v2(_database, [query UTF8String],-1,&statement,nil) == SQLITE_OK) {
        while (sqlite3_step(statement) == SQLITE_ROW) {
            int uniqueId = sqlite3_column_int (statement, 0);
            
            char *textChars = (char *) sqlite3_column_text(statement, 1);
            NSString *text = [[NSString alloc] initWithUTF8String:textChars];
            
            double works = sqlite3_column_int (statement, 2);
            
            int completedZeroOne = sqlite3_column_int (statement, 3);
            bool completed = (completedZeroOne == 1)? true : false;
            
            int deletedZeroOne = sqlite3_column_int (statement, 4);
            bool deleted = (deletedZeroOne == 1)? true : false;
            
            NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
            [dateFormat setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
            
            NSDate *dateCreated =[dateFormat dateFromString:[NSString stringWithUTF8String:(char *)sqlite3_column_text(statement, 4)]];
            
            NSDate *dateCompleted =[dateFormat dateFromString:[NSString stringWithUTF8String:(char *)sqlite3_column_text(statement, 5)]];
            
            NSDate *dateDeleted =[dateFormat dateFromString:[NSString stringWithUTF8String:(char *)sqlite3_column_text(statement, 6)]];
            
            char *categoryChars = (char *) sqlite3_column_text(statement, 7);
            NSString *category = [[NSString alloc] initWithUTF8String:categoryChars];
            
            char *projectChars = (char *) sqlite3_column_text(statement, 8);
            NSString *project = [[NSString alloc] initWithUTF8String:projectChars];
            
            CrushTaskInfo *info = [[CrushTaskInfo alloc]
                                    initWithUniqueId:uniqueId
                                   text:text
                                   works:works
                                   completed:completed
                                   deleted:deleted
                                   datecreated:dateCreated
                                   dateCompleted:dateCompleted
                                   dateDeleted:dateDeleted
                                   category:category
                                   project:project];
            [retval addObject:info];
        }
        sqlite3_finalize(statement);
    }
    return retval;
}

@end
