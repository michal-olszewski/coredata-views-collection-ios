//
// Created by Kacper Kawecki on 19/07/14.
// Copyright (c) 2014 GenieBelt. All rights reserved.
//

#import "CoreDataCollectionSectionChange.h"
#import <UIKit/UIKit.h>


@implementation CoreDataCollectionSectionChange {

}

- (void)performChangeOnView:(UICollectionView *)collectionView {
    switch (self.changeType) {
        case NSFetchedResultsChangeInsert:
            [collectionView insertSections:[NSIndexSet indexSetWithIndex:self.index]];
            break;
        case NSFetchedResultsChangeDelete:
            [collectionView deleteSections:[NSIndexSet indexSetWithIndex:self.index]];
            break;
        case NSFetchedResultsChangeUpdate:
            [collectionView reloadSections:[NSIndexSet indexSetWithIndex:self.index]];
            break;
        case NSFetchedResultsChangeMove:
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
    CoreDataCollectionSectionChange *other = object;
    return self.index == other.index && self.changeType == other.changeType;
}
@end
