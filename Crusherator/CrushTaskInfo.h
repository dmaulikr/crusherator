//
//  CrushTaskData.h
//  Crusherator
//
//  Created by Raj on 4/14/13.
//  Copyright (c) 2013 Raj. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CrushTaskInfo : NSObject
{
    int _uniqueId;
    NSString *_text;
    double _works;
    bool _completed;
    bool _deleted;
    NSDate *_dateCreated;
    NSDate *_dateCompleted;
    NSDate *_dateDeleted;
    NSString *_category;
    NSString *_project;
}

@property (nonatomic, assign) int uniqueId;
@property (nonatomic, copy) NSString *text;
@property (nonatomic, assign) double works;
@property (nonatomic, assign) bool completed;
@property (nonatomic, assign) bool deleted;
@property (nonatomic, copy) NSDate *dateCreated;
@property (nonatomic, copy) NSDate *dateCompleted;
@property (nonatomic, copy) NSDate *dateDeleted;
@property (nonatomic, copy) NSString *category;
@property (nonatomic, copy) NSString *project;

- (id)initWithUniqueId:(int)uniqueId
                  text:(NSString *)text
                 works:(double)works
             completed:(bool) completed
               deleted:(bool) deleted
           datecreated:(NSDate *) dateCreated
         dateCompleted:(NSDate *)dateCompleted
           dateDeleted:(NSDate *)dateDeleted
              category:(NSString *)category
               project:(NSString *)project;

@end
