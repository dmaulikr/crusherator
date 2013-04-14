//
//  CrushStrikeLabel.m
//  Crusherator
//
//  Created by Raj on 4/14/13.
//  Copyright (c) 2013 Raj. All rights reserved.
//

#import "CrushStrikeLabel.h"
#import <QuartzCore/QuartzCore.h>

@implementation CrushStrikeLabel
{
    bool _strikethrough;
    CALayer* _strikethroughLayer;
}

-(id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _strikethroughLayer = [CALayer layer];
        _strikethroughLayer.backgroundColor = [[UIColor whiteColor] CGColor];
        _strikethroughLayer.opacity = self.alpha;
        _strikethroughLayer.hidden = YES;
        [self.layer addSublayer:_strikethroughLayer];
    }
    return self;
}

-(void)layoutSubviews {
    [super layoutSubviews];
    [self resizeStrikeThrough];
}

-(void)setText:(NSString *)text {
    [super setText:text];
    [self resizeStrikeThrough];
}

// resizes the strikethrough layer to match the current label text
-(void)resizeStrikeThrough {
    CGSize textSize = [self.text sizeWithFont:self.font];
    _strikethroughLayer.frame = CGRectMake(0, self.bounds.size.height/2+_offset,
                                           textSize.width, _strikethroughThickness);
}

#pragma mark - property setter
-(void)setStrikethrough:(bool)strikethrough {
    _strikethrough = strikethrough;
    _strikethroughLayer.hidden = !strikethrough;
}

-(void)setColor:(UIColor*)color {
    _strikethroughLayer.backgroundColor = [color CGColor];
}

-(void)setStrikeAlpha:(CGFloat)alpha {
    _strikethroughLayer.opacity = alpha;
}

@end
