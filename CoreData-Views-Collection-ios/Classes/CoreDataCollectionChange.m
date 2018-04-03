//
// Created by Kacper Kawecki on 19/07/14.
// Copyright (c) 2014 GenieBelt. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CoreDataCollectionChange.h"


@implementation CoreDataCollectionChange {

}
- (void)performChangeOnView:(UICollectionView *)collectionView {
    [NSException raise:NSInternalInconsistencyException format:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)];
}


@end