//
// Created by Kacper Kawecki on 19/07/14.
// Copyright (c) 2014 GenieBelt. All rights reserved.
//

#import "CoreDataCollectionObjectChange.h"
#import <UIKit/UIKit.h>


@implementation CoreDataCollectionObjectChange


- (void)performChangeOnView:(UICollectionView *)collectionView {
    switch (self.changeType) {
        case NSFetchedResultsChangeInsert:
            [collectionView insertItemsAtIndexPaths:@[self.secondIndexPath]];
            break;
        case NSFetchedResultsChangeDelete:
            [collectionView deleteItemsAtIndexPaths:@[self.indexPath]];
            break;
        case NSFetchedResultsChangeUpdate:
            [collectionView reloadItemsAtIndexPaths:@[self.indexPath]];
            break;
        case NSFetchedResultsChangeMove:
            if ([self.indexPath isEqual:self.secondIndexPath]) {
                [collectionView reloadItemsAtIndexPaths:@[self.indexPath]];
            } else {
                [collectionView moveItemAtIndexPath:self.indexPath toIndexPath:self.secondIndexPath];
            }
            break;
    }

}

- (BOOL)isEqual:(id)object {
    if (object == self)
        return YES;
    if (!object || ![object isKindOfClass:[self class]])
        return NO;
    return [self isEqualToChange:object];
}

- (BOOL)isEqualToChange:(id)object {
    CoreDataCollectionObjectChange *other = object;
    if (self.indexPath && self.secondIndexPath) {
        return ([self.indexPath isEqual:other.indexPath]) && [self.secondIndexPath isEqual:other.secondIndexPath] && self.changeType == other.changeType;
    }
    if (self.indexPath && !self.secondIndexPath) {
        return ([self.indexPath isEqual:other.indexPath]) && !other.secondIndexPath && self.changeType == other.changeType;
    }
    if (!self.indexPath && self.secondIndexPath) {
        return (!other.indexPath) && [self.secondIndexPath isEqual:other.secondIndexPath] && self.changeType == other.changeType;
    }
    return !other.secondIndexPath && !other.indexPath && self.changeType == other.changeType;
}
@end