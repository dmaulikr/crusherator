//
//  CrushTaskDatabase.h
//  Crusherator
//
//  Created by Raj on 4/14/13.
//  Copyright (c) 2013 Raj. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <sqlite3.h>
#import "CrushTaskInfo.h"

@interface CrushTaskDatabase : NSObject
{
    sqlite3 *_database;
}

+ (CrushTaskInfo*)database;
- (NSArray *)taskInfos;

@end
