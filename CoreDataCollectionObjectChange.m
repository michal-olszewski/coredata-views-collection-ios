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
            [collectionView moveItemAtIndexPath:self.indexPath toIndexPath:self.secondIndexPath];
            break;
    }

}
@end