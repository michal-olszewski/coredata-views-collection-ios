//
//  UIViewUtils.m
//  QuickInspect
//
//  Created by Michal Olszewski on 08.07.2014.
//  Copyright (c) 2014 Kacper Kawecki. All rights reserved.
//

#import "UIViewUtils.h"

@implementation UIViewUtils

+ (UITableViewCell *)tableViewCellForEmbeddedButton:(UIButton *)button {
    id view = nil;
    if(![button isKindOfClass:UIWindow.class]) {
        view = button;
        while (![[view class] isSubclassOfClass:UITableViewCell.class]) {
            view = [view superview];
            if ([view isKindOfClass:UIWindow.class]) {
                return nil;
            }
        }
    }
    return view;
}

@end
