//
//  CrushTask.m
//  Crusherator
//
//  Created by Raj on 4/20/13.
//  Copyright (c) 2013 Raj. All rights reserved.
//

#import "CrushWorkTaskListItem.h"

@implementation CrushWorkTaskListItem
{
    UIFont *fontDialog;
    UIFont *fontDialogStrong;
}

@synthesize text;
@synthesize works;
@synthesize estimatedWorks;
@synthesize task;

- (id)initWithFrame:(CGRect)frame withTask:(CrushTaskObject *)item
{
    self = [super initWithFrame:frame];
    if (self) {
//        [self setBackgroundColor:[UIColor blackColor]];
        fontDialog = [UIFont fontWithName:@"Gotham Light" size:15.0];
        fontDialogStrong = [UIFont fontWithName:@"Gotham Medium" size:15.0];
        
        text = [[CrushStrikeLabel alloc] initWithFrame:(CGRectMake(0,0,self.frame.size.width,self.frame.size.height))];
        task = item;
        text.backgroundColor = [UIColor clearColor];
        text.strikethrough = item.completed;
        text.color = [UIColor whiteColor];
        text.font = fontDialogStrong;
        text.textColor = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:(1.0)];
        text.alpha = 1.0;
        text.text = item.text;
        text.strikethroughThickness = 2.0;
        text.offset = -3.0;
        text.enabled = NO;
        [self addSubview:text];
        
        estimatedWorks = [[CrushStrikeLabel alloc] initWithFrame:(CGRectMake(0,0,self.frame.size.width,self.frame.size.height))];
        estimatedWorks.backgroundColor = [UIColor clearColor];
        estimatedWorks.font = fontDialogStrong;
        estimatedWorks.textColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:(0.3)];
        estimatedWorks.alpha = 1.0;
        estimatedWorks.textAlignment = NSTextAlignmentRight;
        estimatedWorks.enabled = NO;
        for(int i=0;i<=(task.estimatedWorks);i++)
        {
            estimatedWorks.text = [@"" stringByPaddingToLength:task.estimatedWorks withString:@"|" startingAtIndex:0];
        }
        
        [self addSubview:estimatedWorks];
        
        works = [[CrushStrikeLabel alloc] initWithFrame:(CGRectMake(0,0,self.frame.size.width,self.frame.size.height))];
        works.backgroundColor = [UIColor clearColor];
        works.font = fontDialogStrong;
        works.textColor = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:(1.0)];
        works.alpha = 1.0;
        works.textAlignment = NSTextAlignmentRight;
        works.enabled = NO;
        for(int i=0;i<=(task.works);i++)
        {
            works.text = [@"" stringByPaddingToLength:task.works withString:@"|" startingAtIndex:0];
        }

        [self addSubview:works];

    }
    return self;
}

- (void)strike:(BOOL)strike
{
    text.strikethrough = strike;
}

- (void)bold:(BOOL)bold
{
    UIFont *currentFont;
    if (bold)
    {
        currentFont = fontDialogStrong;
        text.strikethroughThickness = 2.0;
    }
    if (!bold) currentFont = fontDialog;
    {
        text.font = currentFont;
        text.strikethroughThickness = 1.0;
    }
}


/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
