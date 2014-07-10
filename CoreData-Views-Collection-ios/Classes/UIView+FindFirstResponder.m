//
//  UIView+FindFirstResponder.m
//  GeniePlanner
//
//  Created by Michal Olszewski on 10.10.2013.
//  Copyright (c) 2013 GenieBelt. All rights reserved.
//

#import "UIView+FindFirstResponder.h"

@implementation UIView (FindFirstResponder)

- (UIView *)findFirstResponder {
    if (self.isFirstResponder) {
        return self;
    }

    for (UIView *subView in self.subviews) {
        UIView *firstResponder = [subView findFirstResponder];
        if (firstResponder != nil) {
            return firstResponder;
        }
    }
    return nil;
}

@end
