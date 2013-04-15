//
//  CrushTaskData.m
//  Crusherator
//
//  Created by Raj on 4/14/13.
//  Copyright (c) 2013 Raj. All rights reserved.
//

#import "CrushTaskInfo.h"

@implementation CrushTaskInfo

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

- (id)initWithUniqueId:(int)uniqueId
                  text:(NSString *)text
                 works:(double)works
             completed:(bool) completed
               deleted:(bool) deleted
           datecreated:(NSDate *) dateCreated
         dateCompleted:(NSDate *)dateCompleted
           dateDeleted:(NSDate *)dateDeleted
              category:(NSString *)category
               project:(NSString *)project
{
    if ((self = [super init])) {
        self.uniqueId = uniqueId;
        self.text = text;
        self.works = works;
        self.completed = completed;
        self.deleted = deleted;
        self.dateCreated = dateCreated;
        self.dateCompleted = dateCompleted;
        self.dateDeleted = dateDeleted;
        self.category = category;
        self.project = project;
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

@end
