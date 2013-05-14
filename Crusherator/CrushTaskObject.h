//
//  CrushTaskData.h
//  Crusherator
//
//  Created by Raj on 4/14/13.
//  Copyright (c) 2013 Raj. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <sqlite3.h>
#import "CrushTaskDatabase.h"

@interface CrushTaskObject : NSObject
{
    sqlite3 *_database;
    int _uniqueId;
    NSString *_text;
    int _works;
    int _estimatedWorks;
    bool _completed;
    NSInteger _ordering;
//    NSDate *_dateCreated;
//    NSDate *_dateCompleted;
//    NSDate *_dateDeleted;
//    NSString *_category;
//    NSString *_project;
}

@property (nonatomic, assign) int uniqueId;
@property (nonatomic, copy) NSString *text;
@property (nonatomic, assign) int works;
@property (nonatomic, assign) int estimatedWorks;
@property (nonatomic, assign) bool completed;
@property (nonatomic, assign) bool deleted;
@property (nonatomic, assign) NSInteger ordering;
@property (nonatomic, copy) NSDate *dateCreated;
@property (nonatomic, copy) NSDate *dateCompleted;
@property (nonatomic, copy) NSDate *dateDeleted;
@property (nonatomic, copy) NSString *category;
@property (nonatomic, copy) NSString *project;

- (id)initWithUniqueId:(int)uniqueId
                  text:(NSString *)text;

- (void) deleteFromDatabase;
+ (NSInteger) insertIntoDatabase:(sqlite3 *)database;
- (void) editInDatabase;

@end
