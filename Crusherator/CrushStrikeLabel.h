//
//  CrushStrikeLabel.h
//  Crusherator
//
//  Created by Raj on 4/14/13.
//  Copyright (c) 2013 Raj. All rights reserved.
//

#import <UIKit/UIKit.h>

// A UILabel subclass that can optionally have a strikethrough.
@interface CrushStrikeLabel : UITextField

// A Boolean value that determines whether the label should have a strikethrough.
@property (nonatomic) bool strikethrough;
@property (nonatomic) UIColor *color;
@property (nonatomic) float strikeAlpha;
@property (nonatomic) float strikethroughThickness;
@property (nonatomic) float offset;

@end