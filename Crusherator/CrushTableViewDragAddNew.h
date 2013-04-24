//
//  CrushTableViewDragAddNew.h
//  Crusherator
//
//  Created by Raj on 4/14/13.
//  Copyright (c) 2013 Raj. All rights reserved.
//

#import "CrushTableView.h"

@interface CrushTableViewDragAddNew : CrushTableView

@property(nonatomic) BOOL alwaysBounceVertical; // default NO. if YES and bounces is YES, even if content is smaller than bounds, allow drag vertically
@property(nonatomic) BOOL alwaysBounceHorizontal; // default NO. if YES and bounces is YES, even if content is smaller than bounds, allow drag horizontally

@end
