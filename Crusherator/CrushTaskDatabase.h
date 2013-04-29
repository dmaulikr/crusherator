//
//  CrushTaskDatabase.h
//  Crusherator
//
//  Created by Raj on 4/14/13.
//  Copyright (c) 2013 Raj. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <sqlite3.h>
@class CrushTaskObject;

@interface CrushTaskDatabase : NSObject <UIApplicationDelegate>

{
    sqlite3 *_database;
}

+ (CrushTaskDatabase *)sharedInstance;
- (NSMutableArray *)taskInfos;
- (CrushTaskObject *)addTask:text atIndex:(int)index;
- (void)removeTask:task;
- (sqlite3 *)databaseAccess;

@property (nonatomic, retain) NSMutableArray *retval;

@end
