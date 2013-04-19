//
//  CrushTaskDatabase.h
//  Crusherator
//
//  Created by Raj on 4/14/13.
//  Copyright (c) 2013 Raj. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <sqlite3.h>
@class CrushTaskInfo;

@interface CrushTaskDatabase : NSObject <UIApplicationDelegate>

{
    sqlite3 *_databaseFile;
//    NSMutableArray *array;
}

- (CrushTaskInfo *)addTask:text;
- (void)removeTask:task;
- (sqlite3 *)databaseAccess;
- (NSMutableArray *)globalTaskList;

//@property (nonatomic, retain) NSMutableArray *array;

@end
